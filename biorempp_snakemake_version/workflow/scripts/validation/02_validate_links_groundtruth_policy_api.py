#!/usr/bin/env python3

import argparse
import json
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path

from common_normalization import load_na_markers
from kegg_api_client import (
    load_database_rows,
    parse_link_payload,
    read_link_cache,
)

NA_MARKERS = load_na_markers()


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


def parse_args():
    parser = argparse.ArgumentParser(description="Policy-aware links ground-truth validation against KEGG API.")
    parser.add_argument("--database-csv", required=True)
    parser.add_argument("--csv-delimiter", required=True)
    parser.add_argument("--ko-ec-cache", required=True)
    parser.add_argument("--ko-reaction-cache", required=True)
    parser.add_argument("--cpd-ec-cache", required=True)
    parser.add_argument("--cpd-reaction-cache", required=True)
    parser.add_argument("--ec-reaction-cache", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--config", required=True)
    parser.add_argument("--max-examples", type=int, default=200)
    parser.add_argument("--max-invalid-line-ratio", type=float, default=0.01)
    return parser.parse_args()


def main():
    args = parse_args()

    db_rows = load_database_rows(args.database_csv, args.csv_delimiter)

    ko_ec_payload, ko_ec_url = read_link_cache(args.ko_ec_cache)
    ko_reaction_payload, ko_reaction_url = read_link_cache(args.ko_reaction_cache)
    cpd_ec_payload, cpd_ec_url = read_link_cache(args.cpd_ec_cache)
    cpd_reaction_payload, cpd_reaction_url = read_link_cache(args.cpd_reaction_cache)
    ec_reaction_payload, ec_reaction_url = read_link_cache(args.ec_reaction_cache)

    max_ratio = args.max_invalid_line_ratio
    ko_ec, ko_ec_stats = parse_link_payload(ko_ec_payload, "ko", "ec", max_ratio)
    ko_reaction, ko_reaction_stats = parse_link_payload(ko_reaction_payload, "ko", "reaction", max_ratio)
    cpd_ec, cpd_ec_stats = parse_link_payload(cpd_ec_payload, "cpd", "ec", max_ratio)
    cpd_reaction, cpd_reaction_stats = parse_link_payload(cpd_reaction_payload, "cpd", "reaction", max_ratio)
    ec_reaction, ec_reaction_stats = parse_link_payload(ec_reaction_payload, "ec", "reaction", max_ratio)

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
            "csv_delimiter": args.csv_delimiter,
            "config_file": args.config,
        },
        "kegg_api": {
            "cache_source": "work/kegg_link_cache/",
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
            "source_of_truth": "KEGG REST API via shared link cache",
            "strict5_definition": "ko_ec + ko_reaction + cpd_ec + cpd_reaction + ec_reaction",
            "policy_union_definition": "ko_complete_like OR ko_fallback_like OR compound_bridge_like",
        },
        "pair_level_validation": pair_validation,
        "policy_aware_metrics": policy_metrics,
    }

    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
