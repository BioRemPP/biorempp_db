from __future__ import annotations

import json

import yaml

from biorempp_validation.loaders import load_json
from biorempp_validation.run_validation import main
from biorempp_validation.settings import load_settings


def test_warning_mode_passes_with_shipped_thresholds(config_path):
    cfg = yaml.safe_load(config_path.read_text(encoding="utf-8"))
    cfg["validation_modes"]["regression_detection"] = False
    cfg["policy"]["fail_on_warning"] = True
    config_path.write_text(yaml.safe_dump(cfg, sort_keys=False), encoding="utf-8")

    exit_code = main(["--config", str(config_path)])
    assert exit_code == 0

    settings = load_settings(config_path)
    summary = json.loads((settings.output_dir / "validation_summary.json").read_text(encoding="utf-8"))
    assert summary["counts"]["critical_failed_expectations"] == 0
    assert summary["counts"]["warning_failed_expectations"] == 0


def test_shipped_thresholds_cover_current_baseline(config_path, sample_results_root):
    cfg = yaml.safe_load(config_path.read_text(encoding="utf-8"))
    thresholds = cfg["drift_thresholds"]
    basic_stats = load_json(sample_results_root / "analysis" / "basic_statistics.json")

    observed_metrics = {
        "row_count": int(basic_stats["total_entries"]),
        "unique_compounds": int(basic_stats["unique_compounds"]),
        "unique_ko": int(basic_stats["unique_ko_entries"]),
        "unique_genesymbol": int(basic_stats["unique_gene_symbols"]),
        "unique_genename": int(basic_stats["unique_gene_names"]),
        "unique_enzyme_activity": int(basic_stats["unique_enzyme_activities"]),
    }

    for metric_name, observed_value in observed_metrics.items():
        assert thresholds[metric_name]["min"] <= observed_value <= thresholds[metric_name]["max"]


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
    failed_types = {item["expectation_type"] for item in summary["failed_expectations"]}
    assert "expect_table_row_count_to_be_between" in failed_types
