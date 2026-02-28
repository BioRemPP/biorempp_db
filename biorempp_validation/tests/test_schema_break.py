from __future__ import annotations

import json

import pandas as pd

from biorempp_validation.run_validation import main
from biorempp_validation.settings import load_settings


def test_schema_break_fails_critical(config_path, sample_results_root):
    csv_path = sample_results_root / "database" / "biorempp_database_v1.0.0.csv"
    df = pd.read_csv(csv_path)
    df = df.drop(columns=["ko"])
    df.to_csv(csv_path, index=False)

    exit_code = main(["--config", str(config_path)])
    assert exit_code == 1

    settings = load_settings(config_path)
    summary = json.loads((settings.output_dir / "validation_summary.json").read_text(encoding="utf-8"))
    failed_types = {item["expectation_type"] for item in summary["failed_expectations"]}
    assert "expect_table_columns_to_match_ordered_list" in failed_types
