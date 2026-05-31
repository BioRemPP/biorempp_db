from __future__ import annotations

import json

import yaml

from biorempp_validation.run_validation import main
from biorempp_validation.settings import load_settings


def test_warning_failure_blocks_when_fail_on_warning(config_path):
    cfg = yaml.safe_load(config_path.read_text(encoding="utf-8"))
    cfg["validation_modes"]["regression_detection"] = False
    cfg["policy"]["fail_on_warning"] = True
    cfg["drift_thresholds"]["row_count"]["max"] = 100
    cfg["drift_thresholds"]["row_count"]["min"] = 1
    config_path.write_text(yaml.safe_dump(cfg, sort_keys=False), encoding="utf-8")

    exit_code = main(["--config", str(config_path)])
    assert exit_code == 1

    settings = load_settings(config_path)
    summary = json.loads((settings.output_dir / "validation_summary.json").read_text(encoding="utf-8"))
    assert summary["counts"]["critical_failed_expectations"] == 0
    assert summary["counts"]["warning_failed_expectations"] >= 1
