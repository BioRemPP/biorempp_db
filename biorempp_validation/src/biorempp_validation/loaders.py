from __future__ import annotations

import json
from pathlib import Path
from typing import Any

import pandas as pd


def resolve_required_paths(results_root: Path, required_files: list[str]) -> dict[str, Path]:
    return {relative: (results_root / relative).resolve() for relative in required_files}


def find_missing_paths(resolved_paths: dict[str, Path]) -> list[str]:
    return [relative for relative, path in resolved_paths.items() if not path.exists()]


def load_json(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def load_database_csv(path: Path) -> pd.DataFrame:
    return pd.read_csv(path)


def load_analysis_payloads(results_root: Path) -> dict[str, dict[str, Any]]:
    analysis_dir = results_root / "analysis"
    payloads = {
        "basic_statistics": load_json(analysis_dir / "basic_statistics.json"),
        "compound_statistics": load_json(analysis_dir / "compound_statistics.json"),
        "ko_statistics": load_json(analysis_dir / "ko_statistics.json"),
        "enzyme_statistics": load_json(analysis_dir / "enzyme_statistics.json"),
        "gene_statistics": load_json(analysis_dir / "gene_statistics.json"),
        "crosstab_statistics": load_json(analysis_dir / "crosstab_statistics.json"),
        "database_metadata": load_json(analysis_dir / "database_metadata.json"),
        "executive_summary": load_json(analysis_dir / "executive_summary.json"),
        "complete_analysis": load_json(analysis_dir / "complete_analysis.json"),
    }
    return payloads
