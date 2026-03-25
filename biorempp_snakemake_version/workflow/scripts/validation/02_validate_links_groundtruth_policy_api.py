#!/usr/bin/env python3

import argparse
import csv
import json
import re
import time
import urllib.error
import urllib.request
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path


NA_MARKERS = {"", "NA", "NAN", "<NA>", "NONE", "NULL"}

PATTERNS = {
    "ko": re.compile(r"(?:ko:)?(K\d{5})", re.IGNORECASE),
    "cpd": re.compile(r"(?:cpd:)?(C\d{5})", re.IGNORECASE),
    "reaction": re.compile(r"(?:rn:)?(R\d{5})", re.IGNORECASE),
    "ec": re.compile(r"(?:ec:)?((?:\d+\.){3}[0-9A-Za-z\-]+)", re.IGNORECASE),
}


def normalize_token(value, token_type):
    if value is None:
        return None
    text = str(value).strip()
    if text.upper() in NA_MARKERS:
        return None
    match = PATTERNS[token_type].search(text)
    if not match:
        return None
    token = match.group(1)
    if token_type in {"ko", "cpd", "reaction"}:
        return token.upper()
    return token


def fetch_text(base_url, endpoint, retries=3, timeout=60):
    url = base_url.rstrip("/") + "/" + endpoint.lstrip("/")
    last_error = None
    for attempt in range(1, retries + 1):
        try:
            with urllib.request.urlopen(url, timeout=timeout) as response:
                return response.read().decode("utf-8", errors="replace"), url
        except (urllib.error.URLError, TimeoutError) as err:
            last_error = err
            if attempt < retries:
                time.sleep(attempt)
    raise RuntimeError(f"Failed to fetch endpoint after {retries} attempts: {url} | {last_error}")


def parse_link_payload(payload, left_type, right_type):
    pairs = set()
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
            pairs.add((direct_left, direct_right))
            stats["parsed_pairs"] += 1
        elif swap_valid:
            pairs.add((swap_left, swap_right))
            stats["parsed_pairs"] += 1
            stats["swapped_orientation_lines"] += 1
        else:
            stats["invalid_lines"] += 1

    if stats["parsed_pairs"] == 0:
        raise RuntimeError(f"No valid pairs parsed for relation {left_type}->{right_type}")
    if stats["invalid_lines"] > 0:
        raise RuntimeError(
            f"Invalid lines found for relation {left_type}->{right_type}: {stats['invalid_lines']}"
        )

    return pairs, stats


def load_database_rows(csv_path):
    rows = []
    with open(csv_path, "r", encoding="utf-8", newline="") as handle:
        reader = csv.DictReader(handle)
        required = {"cpd", "ko", "ec", "reaction"}
        missing = [col for col in required if col not in reader.fieldnames]
        if missing:
            raise RuntimeError(f"Missing required DB columns: {missing}")

        for idx, raw in enumerate(reader, start=2):
            cpd = normalize_token(raw.get("cpd"), "cpd")
            ko = normalize_token(raw.get("ko"), "ko")
            if cpd is None or ko is None:
                continue

            rows.append(
                {
                    "row_number": idx,
                    "cpd": cpd,
                    "ko": ko,
                    "ec": normalize_token(raw.get("ec"), "ec"),
                    "reaction": normalize_token(raw.get("reaction"), "reaction"),
                    "referenceAG": (raw.get("referenceAG") or "").strip(),
                }
            )
    return rows


def build_pair_validation(rows, link_sets, max_examples):
    pair_stats = {
        "ko_ec": {"applicable_rows": 0, "matched_rows": 0, "mismatched_rows": 0},
        "ko_reaction": {"applicable_rows": 0, "matched_rows": 0, "mismatched_rows": 0},
        "cpd_ec": {"applicable_rows": 0, "matched_rows": 0, "mismatched_rows": 0},
        "cpd_reaction": {"applicable_rows": 0, "matched_rows": 0, "mismatched_rows": 0},
        "ec_reaction": {"applicable_rows": 0, "matched_rows": 0, "mismatched_rows": 0},
    }

    distinct_db_pairs = {
        "ko_ec": set(),
        "ko_reaction": set(),
        "cpd_ec": set(),
        "cpd_reaction": set(),
        "ec_reaction": set(),
    }
    mismatch_examples = {
        "ko_ec": [],
        "ko_reaction": [],
        "cpd_ec": [],
        "cpd_reaction": [],
        "ec_reaction": [],
    }

    for row in rows:
        cpd = row["cpd"]
        ko = row["ko"]
        ec = row["ec"]
        reaction = row["reaction"]

        if ec is not None:
            pair = (ko, ec)
            distinct_db_pairs["ko_ec"].add(pair)
            pair_stats["ko_ec"]["applicable_rows"] += 1
            if pair in link_sets["ko_ec"]:
                pair_stats["ko_ec"]["matched_rows"] += 1
            else:
                pair_stats["ko_ec"]["mismatched_rows"] += 1
                if len(mismatch_examples["ko_ec"]) < max_examples:
                    mismatch_examples["ko_ec"].append(
                        {"row_number": row["row_number"], "cpd": cpd, "ko": ko, "ec": ec, "reaction": reaction}
                    )

        if reaction is not None:
            pair = (ko, reaction)
            distinct_db_pairs["ko_reaction"].add(pair)
            pair_stats["ko_reaction"]["applicable_rows"] += 1
            if pair in link_sets["ko_reaction"]:
                pair_stats["ko_reaction"]["matched_rows"] += 1
            else:
                pair_stats["ko_reaction"]["mismatched_rows"] += 1
                if len(mismatch_examples["ko_reaction"]) < max_examples:
                    mismatch_examples["ko_reaction"].append(
                        {
                            "row_number": row["row_number"],
                            "cpd": cpd,
                            "ko": ko,
                            "reaction": reaction,
                            "ec": ec,
                        }
                    )

        if ec is not None:
            pair = (cpd, ec)
            distinct_db_pairs["cpd_ec"].add(pair)
            pair_stats["cpd_ec"]["applicable_rows"] += 1
            if pair in link_sets["cpd_ec"]:
                pair_stats["cpd_ec"]["matched_rows"] += 1
            else:
                pair_stats["cpd_ec"]["mismatched_rows"] += 1
                if len(mismatch_examples["cpd_ec"]) < max_examples:
                    mismatch_examples["cpd_ec"].append(
                        {"row_number": row["row_number"], "cpd": cpd, "ko": ko, "ec": ec, "reaction": reaction}
                    )

        if reaction is not None:
            pair = (cpd, reaction)
            distinct_db_pairs["cpd_reaction"].add(pair)
            pair_stats["cpd_reaction"]["applicable_rows"] += 1
            if pair in link_sets["cpd_reaction"]:
                pair_stats["cpd_reaction"]["matched_rows"] += 1
            else:
                pair_stats["cpd_reaction"]["mismatched_rows"] += 1
                if len(mismatch_examples["cpd_reaction"]) < max_examples:
                    mismatch_examples["cpd_reaction"].append(
                        {
                            "row_number": row["row_number"],
                            "cpd": cpd,
                            "ko": ko,
                            "reaction": reaction,
                            "ec": ec,
                        }
                    )

        if ec is not None and reaction is not None:
            pair = (ec, reaction)
            distinct_db_pairs["ec_reaction"].add(pair)
            pair_stats["ec_reaction"]["applicable_rows"] += 1
            if pair in link_sets["ec_reaction"]:
                pair_stats["ec_reaction"]["matched_rows"] += 1
            else:
                pair_stats["ec_reaction"]["mismatched_rows"] += 1
                if len(mismatch_examples["ec_reaction"]) < max_examples:
                    mismatch_examples["ec_reaction"].append(
                        {
                            "row_number": row["row_number"],
                            "cpd": cpd,
                            "ko": ko,
                            "ec": ec,
                            "reaction": reaction,
                        }
                    )

    report = {}
    for relation, stats in pair_stats.items():
        applicable = stats["applicable_rows"]
        matched = stats["matched_rows"]
        mismatched = stats["mismatched_rows"]
        match_rate = (matched / applicable * 100.0) if applicable else None
        db_pairs = distinct_db_pairs[relation]
        api_pairs = link_sets[relation]
        missing_pairs = db_pairs - api_pairs

        report[relation] = {
            "applicable_rows": int(applicable),
            "matched_rows": int(matched),
            "mismatched_rows": int(mismatched),
            "match_rate_percent": match_rate,
            "distinct_pairs_in_db": int(len(db_pairs)),
            "distinct_pairs_present_in_api": int(len(db_pairs & api_pairs)),
            "distinct_pairs_missing_in_api": int(len(missing_pairs)),
            "missing_pair_examples": [list(pair) for pair in list(missing_pairs)[:max_examples]],
            "mismatched_row_examples": mismatch_examples[relation],
        }

    return report


def build_policy_metrics(rows, link_sets, max_examples):
    dense_total = 0
    strict5 = 0
    ko_complete_like = 0
    ko_fallback_like = 0
    compound_bridge_like = 0
    policy_union = 0

    mismatch_pattern_counter = Counter()
    mismatch_examples = []

    for row in rows:
        cpd = row["cpd"]
        ko = row["ko"]
        ec = row["ec"]
        reaction = row["reaction"]
        if ec is None or reaction is None:
            continue

        dense_total += 1

        has_ko_ec = (ko, ec) in link_sets["ko_ec"]
        has_ko_reaction = (ko, reaction) in link_sets["ko_reaction"]
        has_cpd_ec = (cpd, ec) in link_sets["cpd_ec"]
        has_cpd_reaction = (cpd, reaction) in link_sets["cpd_reaction"]
        has_ec_reaction = (ec, reaction) in link_sets["ec_reaction"]

        checks = {
            "ko_ec": has_ko_ec,
            "ko_reaction": has_ko_reaction,
            "cpd_ec": has_cpd_ec,
            "cpd_reaction": has_cpd_reaction,
            "ec_reaction": has_ec_reaction,
        }

        is_strict5 = all(checks.values())
        is_ko_complete_like = has_ko_ec and has_ko_reaction and has_ec_reaction
        is_ko_fallback_like = has_ko_ec and has_ko_reaction and (not has_ec_reaction)
        is_compound_bridge_like = has_cpd_ec and has_cpd_reaction and (has_ko_ec or has_ko_reaction)
        is_policy_supported = is_ko_complete_like or is_ko_fallback_like or is_compound_bridge_like

        if is_strict5:
            strict5 += 1
        if is_ko_complete_like:
            ko_complete_like += 1
        if is_ko_fallback_like:
            ko_fallback_like += 1
        if is_compound_bridge_like:
            compound_bridge_like += 1
        if is_policy_supported:
            policy_union += 1
        else:
            failed = sorted([name for name, ok in checks.items() if not ok])
            pattern = "+".join(failed) if failed else "unknown"
            mismatch_pattern_counter[pattern] += 1
            if len(mismatch_examples) < max_examples:
                mismatch_examples.append(
                    {
                        "row_number": row["row_number"],
                        "cpd": cpd,
                        "ko": ko,
                        "ec": ec,
                        "reaction": reaction,
                        "referenceAG": row["referenceAG"],
                        "failed_checks": failed,
                    }
                )

    no_policy_support = dense_total - policy_union

    return {
        "dense_total": int(dense_total),
        "strict5": int(strict5),
        "ko_complete_like": int(ko_complete_like),
        "ko_fallback_like": int(ko_fallback_like),
        "compound_bridge_like": int(compound_bridge_like),
        "policy_union": int(policy_union),
        "no_policy_support": int(no_policy_support),
        "strict5_rate_percent": (strict5 / dense_total * 100.0) if dense_total else None,
        "policy_union_rate_percent": (policy_union / dense_total * 100.0) if dense_total else None,
        "policy_mismatch_patterns": dict(sorted(mismatch_pattern_counter.items(), key=lambda kv: kv[1], reverse=True)),
        "policy_mismatch_examples": mismatch_examples,
    }


def build_sentinel(rows, cpd, ko):
    subset = [row for row in rows if row["cpd"] == cpd and row["ko"] == ko]
    return {
        "cpd": cpd,
        "ko": ko,
        "rows": len(subset),
        "dense_rows": sum(1 for row in subset if row["ec"] is not None and row["reaction"] is not None),
        "ec_na_rows": sum(1 for row in subset if row["ec"] is None),
        "reaction_na_rows": sum(1 for row in subset if row["reaction"] is None),
        "both_na_rows": sum(1 for row in subset if row["ec"] is None and row["reaction"] is None),
    }


def parse_args():
    parser = argparse.ArgumentParser(description="Policy-aware links ground-truth validation against KEGG API.")
    parser.add_argument("--database-csv", required=True)
    parser.add_argument("--base-url", required=True)
    parser.add_argument("--ko-ec-endpoint", required=True)
    parser.add_argument("--ko-reaction-endpoint", required=True)
    parser.add_argument("--cpd-ec-endpoint", required=True)
    parser.add_argument("--cpd-reaction-endpoint", required=True)
    parser.add_argument("--ec-reaction-endpoint", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--config", required=True)
    parser.add_argument("--max-examples", type=int, default=200)
    return parser.parse_args()


def main():
    args = parse_args()

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

    link_sets = {
        "ko_ec": ko_ec,
        "ko_reaction": ko_reaction,
        "cpd_ec": cpd_ec,
        "cpd_reaction": cpd_reaction,
        "ec_reaction": ec_reaction,
    }

    pair_validation = build_pair_validation(db_rows, link_sets, args.max_examples)
    policy_metrics = build_policy_metrics(db_rows, link_sets, args.max_examples)

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
            "mode": "report_only",
            "source_of_truth": "KEGG REST API endpoints fetched at runtime",
            "strict5_definition": "ko_ec + ko_reaction + cpd_ec + cpd_reaction + ec_reaction",
            "policy_union_definition": "ko_complete_like OR ko_fallback_like OR compound_bridge_like",
        },
        "pair_level_validation": pair_validation,
        "policy_aware_metrics": policy_metrics,
        "sentinel_cases": [
            build_sentinel(db_rows, "C00230", "K20218"),
            build_sentinel(db_rows, "C00038", "K00001"),
        ],
    }

    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
