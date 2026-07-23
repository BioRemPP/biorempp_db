from __future__ import annotations

import json

import pytest
import yaml

from biorempp_validation.loaders import load_json
from biorempp_validation.run_validation import main
from biorempp_validation.settings import load_settings


def _load_critical_payload(config_path):
    settings = load_settings(config_path)
    payload = json.loads((settings.output_dir / "critical_checkpoint_result.json").read_text(encoding="utf-8"))
    return settings, payload


def _suite_results_for_mode(payload: dict, validation_mode: str) -> list[dict]:
    return [item for item in payload["suite_results"] if item.get("validation_mode") == validation_mode]


def test_regression_failure_is_isolated_from_internal_consistency(
    config_path,
    sample_baseline_root,
):
    baseline_path = sample_baseline_root / "analysis" / "basic_statistics.json"
    payload = load_json(baseline_path)
    payload["total_entries"] = int(payload["total_entries"]) - 1
    baseline_path.write_text(json.dumps(payload, indent=2), encoding="utf-8")

    exit_code = main(["--config", str(config_path)])
    assert exit_code == 1

    settings, critical_payload = _load_critical_payload(config_path)
    internal_results = _suite_results_for_mode(critical_payload, "internal_consistency")
    regression_results = _suite_results_for_mode(critical_payload, "regression_detection")

    assert internal_results
    assert all(item["success"] for item in internal_results)
    assert regression_results
    assert any(not item["success"] for item in regression_results)

    summary = json.loads((settings.output_dir / "validation_summary.json").read_text(encoding="utf-8"))
    failed_modes = {item["validation_mode"] for item in summary["failed_expectations"]}
    assert "regression_detection" in failed_modes
    assert "internal_consistency" not in failed_modes


def test_internal_consistency_failure_does_not_fail_regression(
    config_path,
    sample_results_root,
):
    analysis_path = sample_results_root / "analysis" / "basic_statistics.json"
    payload = load_json(analysis_path)
    payload["total_entries"] = int(payload["total_entries"]) - 1
    analysis_path.write_text(json.dumps(payload, indent=2), encoding="utf-8")

    exit_code = main(["--config", str(config_path)])
    assert exit_code == 1

    settings, critical_payload = _load_critical_payload(config_path)
    internal_results = _suite_results_for_mode(critical_payload, "internal_consistency")
    regression_results = _suite_results_for_mode(critical_payload, "regression_detection")

    assert internal_results
    assert any(not item["success"] for item in internal_results)
    assert regression_results
    assert all(item["success"] for item in regression_results)

    summary = json.loads((settings.output_dir / "validation_summary.json").read_text(encoding="utf-8"))
    failed_modes = {item["validation_mode"] for item in summary["failed_expectations"]}
    assert "internal_consistency" in failed_modes
    assert "regression_detection" not in failed_modes


def test_missing_regression_baseline_fails_preflight(config_path):
    cfg = yaml.safe_load(config_path.read_text(encoding="utf-8"))
    cfg["paths"]["regression_baseline_root"] = str((config_path.parent / "missing-baseline").resolve())
    config_path.write_text(yaml.safe_dump(cfg, sort_keys=False), encoding="utf-8")

    exit_code = main(["--config", str(config_path)])
    assert exit_code == 1

    settings = load_settings(config_path)
    summary = json.loads((settings.output_dir / "validation_summary.json").read_text(encoding="utf-8"))
    assert summary["failed_expectations"][0]["expectation_type"] == "expect_regression_baseline_files_to_exist"
    assert summary["failed_expectations"][0]["validation_mode"] == "regression_detection"


def test_legacy_strict_exact_key_is_rejected(config_path):
    cfg = yaml.safe_load(config_path.read_text(encoding="utf-8"))
    cfg["strict_exact"] = True
    config_path.write_text(yaml.safe_dump(cfg, sort_keys=False), encoding="utf-8")

    with pytest.raises(ValueError, match="strict_exact"):
        load_settings(config_path)
