#!/usr/bin/env python3

import argparse
import csv
import json
import os
import random
import re
import time
import urllib.error
import urllib.request
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path

from common_normalization import is_na_like, load_na_markers

NA_MARKERS = load_na_markers()

PATTERNS = {
    "ko": re.compile(r"(?:ko:)?(K\d{5})", re.IGNORECASE),
    "cpd": re.compile(r"(?:cpd:)?(C\d{5})", re.IGNORECASE),
    "reaction": re.compile(r"(?:rn:)?(R\d{5})", re.IGNORECASE),
    "ec": re.compile(r"(?:ec:)?((?:\d+\.){3}[0-9A-Za-z\-]+)", re.IGNORECASE),
}


def normalize_token(value, token_type):
    if is_na_like(value, NA_MARKERS):
        return None
    text = str(value).strip()
    match = PATTERNS[token_type].search(text)
    if not match:
        return None
    token = match.group(1)
    if token_type in {"ko", "cpd", "reaction"}:
        return token.upper()
    return token


def read_int_env(name, default, min_value=1):
    raw = os.getenv(name, str(default))
    try:
        value = int(raw)
    except ValueError:
        return default
    return value if value >= min_value else default


def read_float_env(name, default, min_value=0.0):
    raw = os.getenv(name, str(default))
    try:
        value = float(raw)
    except ValueError:
        return default
    return value if value >= min_value else default


RETRY_MAX = read_int_env("BIOREMPP_API_MAX_RETRIES", 6, min_value=1)
REQUEST_TIMEOUT = read_int_env("BIOREMPP_API_TIMEOUT_SECONDS", 90, min_value=1)
BACKOFF_BASE = read_float_env("BIOREMPP_API_BACKOFF_BASE_SECONDS", 1.0, min_value=0.1)
BACKOFF_MAX = read_float_env("BIOREMPP_API_BACKOFF_MAX_SECONDS", 30.0, min_value=0.1)
BACKOFF_JITTER = read_float_env("BIOREMPP_API_BACKOFF_JITTER_RATIO", 0.25, min_value=0.0)


def compute_backoff_seconds(attempt):
    exponential = BACKOFF_BASE * (2 ** (attempt - 1))
    capped = min(BACKOFF_MAX, exponential)
    jitter_multiplier = random.uniform(1 - BACKOFF_JITTER, 1 + BACKOFF_JITTER)
    return max(0.1, capped * jitter_multiplier)


def fetch_text(base_url, endpoint, max_retries=RETRY_MAX, timeout=REQUEST_TIMEOUT):
    url = base_url.rstrip("/") + "/" + endpoint.lstrip("/")
    last_error = None
    for attempt in range(1, max_retries + 1):
        try:
            with urllib.request.urlopen(url, timeout=timeout) as response:
                return response.read().decode("utf-8", errors="replace"), url
        except (urllib.error.URLError, TimeoutError) as err:
            last_error = err
            if attempt < max_retries:
                sleep_seconds = compute_backoff_seconds(attempt)
                print(
                    f"[WARN] Fetch failed for {url} at attempt {attempt}/{max_retries} "
                    f"({err}). Retrying in {sleep_seconds:.2f}s."
                )
                time.sleep(sleep_seconds)
    raise RuntimeError(f"Failed to fetch endpoint after {max_retries} attempts: {url} | {last_error}")


def parse_link_payload(payload, left_type, right_type):
    rows = set()
    stats = {
        "total_lines": 0,
        "parsed_pairs": 0,
        "swapped_orientation_lines": 0,
        "invalid_lines": 0,
    }

    for raw_line in payload.splitlines():
        line = raw_line.strip()
        if not line:
            continue
        stats["total_lines"] += 1
        parts = line.split("\t")
        if len(parts) < 2:
            stats["invalid_lines"] += 1
            continue

        col1 = parts[0].strip()
        col2 = parts[1].strip()

        direct_left = normalize_token(col1, left_type)
        direct_right = normalize_token(col2, right_type)
        swap_left = normalize_token(col2, left_type)
        swap_right = normalize_token(col1, right_type)

        direct_valid = direct_left is not None and direct_right is not None
        swap_valid = swap_left is not None and swap_right is not None

        if direct_valid:
            rows.add((direct_left, direct_right))
            stats["parsed_pairs"] += 1
            continue
        if swap_valid:
            rows.add((swap_left, swap_right))
            stats["parsed_pairs"] += 1
            stats["swapped_orientation_lines"] += 1
            continue

        stats["invalid_lines"] += 1

    if stats["parsed_pairs"] == 0:
        raise RuntimeError(f"No valid pairs parsed for relation {left_type}->{right_type}")
    if stats["invalid_lines"] > 0:
        raise RuntimeError(
            f"Found invalid lines for relation {left_type}->{right_type}: {stats['invalid_lines']}"
        )

    return rows, stats


def index_pairs(pairs):
    idx = defaultdict(set)
    for left, right in pairs:
        idx[left].add(right)
    return idx


def load_database_rows(csv_path):
    rows = []
    with open(csv_path, "r", encoding="utf-8", newline="") as handle:
        reader = csv.DictReader(handle)
        required = {"cpd", "ko", "ec", "reaction"}
        missing = [c for c in required if c not in reader.fieldnames]
        if missing:
            raise RuntimeError(f"Missing required DB columns: {missing}")

        for raw in reader:
            cpd = normalize_token(raw.get("cpd"), "cpd")
            ko = normalize_token(raw.get("ko"), "ko")
            if cpd is None or ko is None:
                continue
            rows.append(
                {
                    "cpd": cpd,
                    "ko": ko,
                    "ec": normalize_token(raw.get("ec"), "ec"),
                    "reaction": normalize_token(raw.get("reaction"), "reaction"),
                    "referenceAG": (raw.get("referenceAG") or "").strip(),
                }
            )
    return rows


def analyze_na_consistency(db_rows, link_indices):
    ko_to_ec = link_indices["ko_to_ec"]
    ko_to_reaction = link_indices["ko_to_reaction"]
    cpd_to_ec = link_indices["cpd_to_ec"]
    cpd_to_reaction = link_indices["cpd_to_reaction"]
    reaction_to_ec = link_indices["reaction_to_ec"]
    ec_to_reaction = link_indices["ec_to_reaction"]

    classification_counts = Counter()
    reason_counts = Counter()
    incorrect_examples = []

    totals = {
        "rows_in_database": len(db_rows),
        "rows_with_any_na_in_ec_or_reaction": 0,
        "ec_na_rows": 0,
        "reaction_na_rows": 0,
        "both_na_rows": 0,
    }

    for row in db_rows:
        cpd = row["cpd"]
        ko = row["ko"]
        ec = row["ec"]
        reaction = row["reaction"]

        has_ec = ec is not None
        has_reaction = reaction is not None
        if has_ec and has_reaction:
            continue

        totals["rows_with_any_na_in_ec_or_reaction"] += 1
        pair_ec_sources = set(cpd_to_ec.get(cpd, set())) | set(ko_to_ec.get(ko, set()))
        pair_reaction_sources = set(cpd_to_reaction.get(cpd, set())) | set(ko_to_reaction.get(ko, set()))

        classification = "justified"
        reason = "unknown"
        fill_candidates = 0

        if (not has_ec) and has_reaction:
            totals["ec_na_rows"] += 1
            reaction_supported = reaction in pair_reaction_sources
            candidate_ec = set(reaction_to_ec.get(reaction, set())) & pair_ec_sources
            fill_candidates = len(candidate_ec)

            if reaction_supported and fill_candidates > 0:
                classification = "incorrect"
                reason = "ec_fillable_from_reaction_bridge_and_pair_sources"
            elif not reaction_supported:
                reason = "reaction_not_supported_by_pair_sources"
            elif len(reaction_to_ec.get(reaction, set())) == 0:
                reason = "reaction_has_no_ec_mapping_in_ec_reaction"
            elif len(pair_ec_sources) == 0:
                reason = "pair_has_no_ec_sources"
            else:
                reason = "no_intersection_reaction_ec_with_pair_ec_sources"

        elif has_ec and (not has_reaction):
            totals["reaction_na_rows"] += 1
            ec_supported = ec in pair_ec_sources
            candidate_reactions = set(ec_to_reaction.get(ec, set())) & pair_reaction_sources
            fill_candidates = len(candidate_reactions)

            if ec_supported and fill_candidates > 0:
                classification = "incorrect"
                reason = "reaction_fillable_from_ec_bridge_and_pair_sources"
            elif not ec_supported:
                reason = "ec_not_supported_by_pair_sources"
            elif len(ec_to_reaction.get(ec, set())) == 0:
                reason = "ec_has_no_reaction_mapping_in_ec_reaction"
            elif len(pair_reaction_sources) == 0:
                reason = "pair_has_no_reaction_sources"
            else:
                reason = "no_intersection_ec_reaction_with_pair_reaction_sources"

        else:
            totals["both_na_rows"] += 1
            ko_cartesian_fillable = len(ko_to_ec.get(ko, set())) > 0 and len(ko_to_reaction.get(ko, set())) > 0
            bridge_fillable = False
            for pair_reaction in pair_reaction_sources:
                if len(set(reaction_to_ec.get(pair_reaction, set())) & pair_ec_sources) > 0:
                    bridge_fillable = True
                    break

            if ko_cartesian_fillable:
                classification = "incorrect"
                reason = "both_fillable_by_ko_ec_and_ko_reaction"
            elif bridge_fillable:
                classification = "incorrect"
                reason = "both_fillable_by_reaction_ec_bridge_and_pair_sources"
            elif len(pair_ec_sources) == 0 and len(pair_reaction_sources) == 0:
                reason = "pair_has_no_ec_or_reaction_sources"
            elif len(pair_ec_sources) == 0:
                reason = "pair_has_no_ec_sources"
            elif len(pair_reaction_sources) == 0:
                reason = "pair_has_no_reaction_sources"
            else:
                reason = "pair_sources_exist_but_no_bridge"

        classification_counts[classification] += 1
        reason_counts[reason] += 1

        if classification == "incorrect" and len(incorrect_examples) < 200:
            incorrect_examples.append(
                {
                    "cpd": cpd,
                    "ko": ko,
                    "ec": ec,
                    "reaction": reaction,
                    "referenceAG": row["referenceAG"],
                    "reason": reason,
                    "fill_candidates_count": fill_candidates,
                }
            )

    return {
        "totals": totals,
        "classification_counts": {
            "justified": int(classification_counts.get("justified", 0)),
            "incorrect": int(classification_counts.get("incorrect", 0)),
        },
        "reason_counts": dict(sorted(reason_counts.items(), key=lambda kv: kv[0])),
        "all_remaining_na_justified": int(classification_counts.get("incorrect", 0)) == 0,
        "incorrect_examples_limited": incorrect_examples,
    }


def build_parser():
    parser = argparse.ArgumentParser(description="Validate key consistency for remaining NA values using KEGG API.")
    parser.add_argument("--database-csv", required=True)
    parser.add_argument("--base-url", required=True)
    parser.add_argument("--ko-ec-endpoint", required=True)
    parser.add_argument("--ko-reaction-endpoint", required=True)
    parser.add_argument("--cpd-ec-endpoint", required=True)
    parser.add_argument("--cpd-reaction-endpoint", required=True)
    parser.add_argument("--ec-reaction-endpoint", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--config", required=True)
    return parser


def main():
    args = build_parser().parse_args()

    db_rows = load_database_rows(args.database_csv)

    ko_ec_payload, ko_ec_url = fetch_text(args.base_url, args.ko_ec_endpoint)
    ko_reaction_payload, ko_reaction_url = fetch_text(args.base_url, args.ko_reaction_endpoint)
    cpd_ec_payload, cpd_ec_url = fetch_text(args.base_url, args.cpd_ec_endpoint)
    cpd_reaction_payload, cpd_reaction_url = fetch_text(args.base_url, args.cpd_reaction_endpoint)
    ec_reaction_payload, ec_reaction_url = fetch_text(args.base_url, args.ec_reaction_endpoint)

    ko_ec, ko_ec_stats = parse_link_payload(ko_ec_payload, "ko", "ec")
    ko_reaction, ko_reaction_stats = parse_link_payload(ko_reaction_payload, "ko", "reaction")
    cpd_ec, cpd_ec_stats = parse_link_payload(cpd_ec_payload, "cpd", "ec")
    cpd_reaction, cpd_reaction_stats = parse_link_payload(cpd_reaction_payload, "cpd", "reaction")
    ec_reaction, ec_reaction_stats = parse_link_payload(ec_reaction_payload, "ec", "reaction")

    link_indices = {
        "ko_to_ec": index_pairs(ko_ec),
        "ko_to_reaction": index_pairs(ko_reaction),
        "cpd_to_ec": index_pairs(cpd_ec),
        "cpd_to_reaction": index_pairs(cpd_reaction),
        "ec_to_reaction": index_pairs(ec_reaction),
        "reaction_to_ec": index_pairs((reaction, ec) for ec, reaction in ec_reaction),
    }

    results = analyze_na_consistency(db_rows, link_indices)

    report = {
        "generated_at_utc": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "input": {
            "database_csv": args.database_csv,
            "config_file": args.config,
        },
        "kegg_api": {
            "base_url": args.base_url,
            "endpoints": {
                "ko_ec": ko_ec_url,
                "ko_reaction": ko_reaction_url,
                "cpd_ec": cpd_ec_url,
                "cpd_reaction": cpd_reaction_url,
                "ec_reaction": ec_reaction_url,
            },
        },
        "api_parse_stats": {
            "ko_ec": ko_ec_stats,
            "ko_reaction": ko_reaction_stats,
            "cpd_ec": cpd_ec_stats,
            "cpd_reaction": cpd_reaction_stats,
            "ec_reaction": ec_reaction_stats,
        },
        "validation_policy": {
            "source_of_truth": "KEGG REST API endpoints fetched at runtime",
            "ec_na_incorrect_rule": "Reaction must be supported by pair sources and mappable to EC with pair EC support",
            "reaction_na_incorrect_rule": "EC must be supported by pair sources and mappable to reaction with pair reaction support",
            "both_na_incorrect_rule": "Pair fillable by ko_ec+ko_reaction or by reaction-ec bridge with pair sources",
        },
        "results": results,
    }

    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
