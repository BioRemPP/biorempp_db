#!/usr/bin/env python3

import argparse
import csv
import hashlib
import json
from datetime import datetime, timezone
from pathlib import Path


def sha256sum(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(8192), b""):
            digest.update(chunk)
    return digest.hexdigest()


def file_info(path: Path) -> dict:
    return {
        "path": str(path),
        "size_bytes": path.stat().st_size,
        "sha256": sha256sum(path),
    }


def main() -> None:
    parser = argparse.ArgumentParser(description="Build Snakemake workflow summary report")
    parser.add_argument("--database-csv", required=True)
    parser.add_argument("--database-csv-delimiter", required=True)
    parser.add_argument("--database-xlsx", required=True)
    parser.add_argument("--metadata-json", required=True)
    parser.add_argument("--complete-json", required=True)
    parser.add_argument("--kegg-json", required=True)
    parser.add_argument("--keys-consistency-json", required=True)
    parser.add_argument("--links-groundtruth-policy-json", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--version", required=True)
    parser.add_argument("--config", required=True)
    args = parser.parse_args()

    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)

    files = {
        "database_csv": Path(args.database_csv),
        "database_xlsx": Path(args.database_xlsx),
        "database_metadata_json": Path(args.metadata_json),
        "complete_analysis_json": Path(args.complete_json),
        "kegg_release_json": Path(args.kegg_json),
        "keys_consistency_json": Path(args.keys_consistency_json),
        "links_groundtruth_policy_json": Path(args.links_groundtruth_policy_json),
    }

    for file_path in files.values():
        if not file_path.exists():
            raise FileNotFoundError(f"Required file does not exist: {file_path}")

    with Path(args.kegg_json).open("r", encoding="utf-8") as handle:
        kegg_info = json.load(handle)
    with Path(args.metadata_json).open("r", encoding="utf-8") as handle:
        metadata_info = json.load(handle)
    with Path(args.keys_consistency_json).open("r", encoding="utf-8") as handle:
        keys_consistency_info = json.load(handle)
    with Path(args.links_groundtruth_policy_json).open("r", encoding="utf-8") as handle:
        links_groundtruth_policy_info = json.load(handle)

    reaction_rows = 0
    reaction_description_filled = 0
    unmatched_reaction_ids: set[str] = set()
    with Path(args.database_csv).open("r", encoding="utf-8", newline="") as handle:
        reader = csv.DictReader(handle, delimiter=args.database_csv_delimiter)
        for row in reader:
            reaction = (row.get("reaction") or "").strip()
            reaction_description = (row.get("reaction_description") or "").strip()
            if reaction and reaction.upper() != "NA":
                reaction_rows += 1
                if reaction_description and reaction_description.upper() != "NA":
                    reaction_description_filled += 1
                else:
                    unmatched_reaction_ids.add(reaction)

    reaction_description_fill_rate_percent = (
        round((reaction_description_filled / reaction_rows) * 100, 4) if reaction_rows else 0.0
    )

    policy_metrics = links_groundtruth_policy_info.get("policy_aware_metrics", {})

    summary = {
        "pipeline": {
            "name": "BioRemPP Snakemake Pipeline",
            "version": args.version,
            "config_file": args.config,
            "generated_at_utc": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        },
        "kegg_reference": {
            "source_url": kegg_info.get("source_url"),
            "release_text": kegg_info.get("release_text"),
            "parsed_version": kegg_info.get("parsed_version"),
            "retrieved_at_utc": kegg_info.get("retrieved_at_utc"),
        },
        "keys_consistency": {
            "all_remaining_na_justified": keys_consistency_info.get("results", {}).get(
                "all_remaining_na_justified"
            ),
            "classification_counts": keys_consistency_info.get("results", {}).get("classification_counts", {}),
            "totals": keys_consistency_info.get("results", {}).get("totals", {}),
        },
        "links_groundtruth_policy": {
            "dense_total": policy_metrics.get("dense_total"),
            "strict5_rate_percent": policy_metrics.get("strict5_rate_percent"),
            "policy_union_rate_percent": policy_metrics.get("policy_union_rate_percent"),
            "no_policy_support": policy_metrics.get("no_policy_support"),
        },
        "reaction_description_coverage": {
            "rows_with_reaction": reaction_rows,
            "rows_with_reaction_description": reaction_description_filled,
            "fill_rate_percent": reaction_description_fill_rate_percent,
            "unmatched_reaction_id_count": len(unmatched_reaction_ids),
        },
        "link_match": metadata_info.get("link_match", {}),
        "artifacts": {name: file_info(path) for name, path in files.items()},
    }

    with output_path.open("w", encoding="utf-8") as handle:
        json.dump(summary, handle, indent=2)


if __name__ == "__main__":
    main()
