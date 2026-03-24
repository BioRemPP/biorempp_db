#!/usr/bin/env python3

import argparse
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
    parser.add_argument("--database-xlsx", required=True)
    parser.add_argument("--metadata-json", required=True)
    parser.add_argument("--complete-json", required=True)
    parser.add_argument("--kegg-json", required=True)
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
    }

    for file_path in files.values():
        if not file_path.exists():
            raise FileNotFoundError(f"Required file does not exist: {file_path}")

    with Path(args.kegg_json).open("r", encoding="utf-8") as handle:
        kegg_info = json.load(handle)
    with Path(args.metadata_json).open("r", encoding="utf-8") as handle:
        metadata_info = json.load(handle)

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
        "link_match": metadata_info.get("link_match", {}),
        "artifacts": {name: file_info(path) for name, path in files.items()},
    }

    with output_path.open("w", encoding="utf-8") as handle:
        json.dump(summary, handle, indent=2)


if __name__ == "__main__":
    main()
