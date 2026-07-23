from __future__ import annotations

import json

from biorempp_validation.run_validation import main
from biorempp_validation.settings import load_settings


def test_happy_path(config_path):
    exit_code = main(["--config", str(config_path)])
    assert exit_code == 0

    settings = load_settings(config_path)
    summary_path = settings.output_dir / "validation_summary.json"
    assert summary_path.exists()

    summary = json.loads(summary_path.read_text(encoding="utf-8"))
    assert summary["counts"]["critical_failed_expectations"] == 0
    assert summary["counts"]["warning_failed_expectations"] == 0

    critical_payload = json.loads((settings.output_dir / "critical_checkpoint_result.json").read_text(encoding="utf-8"))
    validation_modes = {item.get("validation_mode") for item in critical_payload["suite_results"]}
    assert "internal_consistency" in validation_modes
    assert "regression_detection" in validation_modes
