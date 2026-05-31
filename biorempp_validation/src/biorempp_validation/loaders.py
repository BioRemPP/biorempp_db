from __future__ import annotations

import json
from pathlib import Path
from typing import Any

import pandas as pd


ANALYSIS_PAYLOAD_FILES = {
    "basic_statistics": "basic_statistics.json",
    "compound_statistics": "compound_statistics.json",
    "ko_statistics": "ko_statistics.json",
    "enzyme_statistics": "enzyme_statistics.json",
    "gene_statistics": "gene_statistics.json",
    "crosstab_statistics": "crosstab_statistics.json",
    "database_metadata": "database_metadata.json",
    "executive_summary": "executive_summary.json",
    "complete_analysis": "complete_analysis.json",
}


def resolve_required_paths(results_root: Path, required_files: list[str]) -> dict[str, Path]:
    return {relative: (results_root / relative).resolve() for relative in required_files}


def find_missing_paths(resolved_paths: dict[str, Path]) -> list[str]:
    return [relative for relative, path in resolved_paths.items() if not path.exists()]


def load_json(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def load_database_csv(path: Path, sep: str = ",") -> pd.DataFrame:
    return pd.read_csv(path, sep=sep)


def load_analysis_payloads(results_root: Path) -> dict[str, dict[str, Any]]:
    analysis_dir = results_root / "analysis"
    return {name: load_json(analysis_dir / filename) for name, filename in ANALYSIS_PAYLOAD_FILES.items()}
