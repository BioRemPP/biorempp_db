#!/usr/bin/env python3

import argparse
import json
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path

from common_normalization import load_na_markers
from kegg_api_client import (
    load_database_rows,
    parse_link_payload,
    read_link_cache,
)

NA_MARKERS = load_na_markers()


def index_pairs(pairs):
    idx = defaultdict(set)
    for left, right in pairs:
        idx[left].add(right)
    return idx


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
    parser.add_argument("--csv-delimiter", required=True)
    parser.add_argument("--ko-ec-cache", required=True)
    parser.add_argument("--ko-reaction-cache", required=True)
    parser.add_argument("--cpd-ec-cache", required=True)
    parser.add_argument("--cpd-reaction-cache", required=True)
    parser.add_argument("--ec-reaction-cache", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--config", required=True)
    parser.add_argument("--max-invalid-line-ratio", type=float, default=0.01)
    return parser


def main():
    args = build_parser().parse_args()

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
            "source_of_truth": "KEGG REST API via shared link cache",
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
