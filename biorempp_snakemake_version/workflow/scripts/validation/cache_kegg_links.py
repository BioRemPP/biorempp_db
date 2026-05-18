#!/usr/bin/env python3

import argparse
from pathlib import Path

from kegg_api_client import fetch_text

ENDPOINTS = {
    "ko_ec": None,
    "ko_reaction": None,
    "cpd_ec": None,
    "cpd_reaction": None,
    "ec_reaction": None,
}


def build_parser():
    parser = argparse.ArgumentParser(
        description="Fetch and cache all 5 KEGG link endpoints to disk for reuse by validation scripts."
    )
    parser.add_argument("--base-url", required=True)
    parser.add_argument("--ko-ec-endpoint", required=True)
    parser.add_argument("--ko-reaction-endpoint", required=True)
    parser.add_argument("--cpd-ec-endpoint", required=True)
    parser.add_argument("--cpd-reaction-endpoint", required=True)
    parser.add_argument("--ec-reaction-endpoint", required=True)
    parser.add_argument("--output-dir", required=True)
    return parser


def main():
    args = build_parser().parse_args()
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    fetches = [
        ("ko_ec",        args.ko_ec_endpoint),
        ("ko_reaction",  args.ko_reaction_endpoint),
        ("cpd_ec",       args.cpd_ec_endpoint),
        ("cpd_reaction", args.cpd_reaction_endpoint),
        ("ec_reaction",  args.ec_reaction_endpoint),
    ]

    for name, endpoint in fetches:
        print(f"[INFO] Fetching {endpoint} ...")
        text, url = fetch_text(args.base_url, endpoint)
        out_path = output_dir / f"{name}.tsv"
        out_path.write_text(text, encoding="utf-8")
        print(f"[INFO] Saved {len(text.splitlines())} lines -> {out_path}")

    print("[INFO] KEGG link cache complete.")


if __name__ == "__main__":
    main()
