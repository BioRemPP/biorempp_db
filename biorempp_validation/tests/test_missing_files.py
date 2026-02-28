from __future__ import annotations

import json

from biorempp_validation.run_validation import main
from biorempp_validation.settings import load_settings


def test_missing_required_file(config_path, sample_results_root):
    missing_file = sample_results_root / "analysis" / "basic_statistics.json"
    missing_file.unlink()

    exit_code = main(["--config", str(config_path)])
    assert exit_code == 1

    settings = load_settings(config_path)
    summary = json.loads((settings.output_dir / "validation_summary.json").read_text(encoding="utf-8"))
    assert summary["counts"]["critical_failed_expectations"] >= 1
    assert summary["failed_expectations"][0]["expectation_type"] == "expect_required_files_to_exist"
