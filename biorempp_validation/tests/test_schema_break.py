from __future__ import annotations

import json

import pandas as pd

from biorempp_validation.run_validation import main
from biorempp_validation.settings import load_settings


def test_schema_break_fails_critical(config_path, sample_results_root):
    settings = load_settings(config_path)
    csv_path = sample_results_root / "database" / "biorempp_database_v1.1.0.csv"
    df = pd.read_csv(csv_path, sep=settings.csv_delimiter)
    df = df.drop(columns=["ko"])
    df.to_csv(csv_path, sep=settings.csv_delimiter, index=False)

    exit_code = main(["--config", str(config_path)])
    assert exit_code == 1

    summary = json.loads((settings.output_dir / "validation_summary.json").read_text(encoding="utf-8"))
    failed_types = {item["expectation_type"] for item in summary["failed_expectations"]}
    assert "expect_table_columns_to_match_ordered_list" in failed_types
