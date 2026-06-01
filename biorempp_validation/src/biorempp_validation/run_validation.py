from __future__ import annotations

import argparse
from copy import deepcopy
import json
from pathlib import Path
from typing import Any

from great_expectations.core.expectation_suite import ExpectationSuite

from .consistency_checks import build_cross_consistency_df
from .gx_context import (
    create_context,
    create_pandas_datasource,
    load_checkpoint_config,
    run_suite_on_dataframe,
)
from .json_to_dataframe import (
    build_analysis_critical_df,
    build_analysis_exact_df,
    build_analysis_warning_df,
    build_kegg_metadata_df,
    build_pipeline_reports_critical_df,
)
from .loaders import (
    find_missing_paths,
    load_analysis_payloads,
    load_database_csv,
    load_json,
    resolve_required_paths,
)
from .report_builder import build_validation_summary
from .settings import ValidationSettings, load_settings


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Run BioRemPP Great Expectations validation.")
    parser.add_argument(
        "--config",
        required=True,
        help="Path to validation configuration YAML (e.g. biorempp_validation/config/validation.yaml).",
    )
    return parser.parse_args(argv)


def _load_suite_payload(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def _clone_suite_payload(payload: dict[str, Any], name: str) -> dict[str, Any]:
    cloned = deepcopy(payload)
    cloned["name"] = name
    return cloned


def _apply_config_overrides_to_suite_payloads(
    suite_payloads: dict[str, dict[str, Any]],
    settings: ValidationSettings,
) -> None:
    db_critical = suite_payloads.get("database_critical")
    db_warning = suite_payloads.get("database_warning")
    analysis_critical = suite_payloads.get("analysis_json_critical")

    if db_critical:
        for expectation in db_critical.get("expectations", []):
            if expectation.get("type") == "expect_table_columns_to_match_ordered_list":
                expectation["kwargs"]["column_list"] = settings.expected_columns
            if expectation.get("type") == "expect_compound_columns_to_be_unique":
                expectation["kwargs"]["column_list"] = settings.expected_columns

    if analysis_critical:
        for expectation in analysis_critical.get("expectations", []):
            if expectation.get("type") != "expect_column_values_to_be_between":
                continue
            kwargs = expectation.get("kwargs", {})
            if kwargs.get("column") != "basic_total_columns":
                continue
            expected_column_count = len(settings.expected_columns)
            kwargs["min_value"] = expected_column_count
            kwargs["max_value"] = expected_column_count

    if not db_warning:
        return

    thresholds = settings.drift_thresholds
    for expectation in db_warning.get("expectations", []):
        expectation_type = expectation.get("type")
        kwargs = expectation.get("kwargs", {})
        column = kwargs.get("column")

        if expectation_type == "expect_column_distinct_values_to_be_in_set" and column == "referenceAG":
            kwargs["value_set"] = list(settings.expected_reference_agencies)
        elif expectation_type == "expect_column_distinct_values_to_be_in_set" and column == "compoundclass":
            kwargs["value_set"] = list(settings.expected_compound_classes)
        elif expectation_type == "expect_column_unique_value_count_to_be_between" and column == "cpd":
            kwargs["min_value"] = thresholds["unique_compounds"]["min"]
            kwargs["max_value"] = thresholds["unique_compounds"]["max"]
        elif expectation_type == "expect_column_unique_value_count_to_be_between" and column == "ko":
            kwargs["min_value"] = thresholds["unique_ko"]["min"]
            kwargs["max_value"] = thresholds["unique_ko"]["max"]
        elif expectation_type == "expect_column_unique_value_count_to_be_between" and column == "genesymbol":
            kwargs["min_value"] = thresholds["unique_genesymbol"]["min"]
            kwargs["max_value"] = thresholds["unique_genesymbol"]["max"]
        elif expectation_type == "expect_column_unique_value_count_to_be_between" and column == "genename":
            kwargs["min_value"] = thresholds["unique_genename"]["min"]
            kwargs["max_value"] = thresholds["unique_genename"]["max"]
        elif expectation_type == "expect_column_unique_value_count_to_be_between" and column == "enzyme_activity":
            kwargs["min_value"] = thresholds["unique_enzyme_activity"]["min"]
            kwargs["max_value"] = thresholds["unique_enzyme_activity"]["max"]
        elif expectation_type == "expect_table_row_count_to_be_between":
            kwargs["min_value"] = thresholds["row_count"]["min"]
            kwargs["max_value"] = thresholds["row_count"]["max"]


def _build_validation_entry(
    suite_name: str,
    dataset_name: str,
    validation_mode: str | None = None,
) -> dict[str, Any]:
    validation = {"suite": suite_name, "dataset": dataset_name}
    if validation_mode is not None:
        validation["validation_mode"] = validation_mode
    return validation


def _build_checkpoint_validations(
    checkpoint_name: str,
    checkpoint_config: dict[str, Any],
    settings: ValidationSettings,
) -> list[dict[str, Any]]:
    validations: list[dict[str, Any]] = []

    for validation in checkpoint_config.get("validations", []):
        suite_name = validation["suite"]
        dataset_name = validation["dataset"]

        if checkpoint_name == "critical_gate":
            if suite_name == "analysis_json_critical":
                if settings.validation_modes.internal_consistency:
                    validations.append(_build_validation_entry(suite_name, dataset_name, "internal_consistency"))
                continue

            if suite_name == "analysis_json_exact_critical":
                if settings.validation_modes.internal_consistency:
                    validations.append(
                        _build_validation_entry(
                            "analysis_json_internal_consistency_critical",
                            "analysis_internal_consistency",
                            "internal_consistency",
                        )
                    )
                if settings.validation_modes.regression_detection:
                    validations.append(
                        _build_validation_entry(
                            "analysis_json_regression_critical",
                            "analysis_regression",
                            "regression_detection",
                        )
                    )
                continue

            if suite_name == "cross_consistency_critical":
                if settings.validation_modes.internal_consistency:
                    validations.append(_build_validation_entry(suite_name, dataset_name, "internal_consistency"))
                continue

            if suite_name == "metadata_kegg_critical":
                validations.append(_build_validation_entry(suite_name, dataset_name, "current_artifacts"))
                continue

            validations.append(_build_validation_entry(suite_name, dataset_name))
            continue

        if suite_name == "analysis_json_warning":
            if settings.validation_modes.internal_consistency:
                validations.append(_build_validation_entry(suite_name, dataset_name, "internal_consistency"))
            continue

        validations.append(_build_validation_entry(suite_name, dataset_name))

    return validations


def _run_checkpoint(
    checkpoint_name: str,
    validations: list[dict[str, Any]],
    suite_payloads: dict[str, dict[str, Any]],
    dataframe_by_dataset: dict[str, Any],
    datasource,
) -> dict[str, Any]:
    suite_results: list[dict[str, Any]] = []
    checkpoint_success = True

    for validation in validations:
        suite_name = validation["suite"]
        dataset_name = validation["dataset"]
        validation_mode = validation.get("validation_mode")

        suite_payload = suite_payloads[suite_name]
        suite = ExpectationSuite(**suite_payload)

        result = run_suite_on_dataframe(
            datasource=datasource,
            dataframe=dataframe_by_dataset[dataset_name],
            suite=suite,
            asset_name=f"{dataset_name}_{suite_name}",
        )
        suite_success = bool(result.get("success", False))
        checkpoint_success = checkpoint_success and suite_success

        suite_results.append(
            {
                "suite_name": suite_name,
                "dataset": dataset_name,
                "validation_mode": validation_mode,
                "success": suite_success,
                "result": result,
            }
        )

    return {
        "checkpoint_name": checkpoint_name,
        "success": checkpoint_success,
        "suite_results": suite_results,
    }


def _write_json(path: Path, payload: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as handle:
        json.dump(payload, handle, indent=2)


def _write_data_docs_placeholder(output_dir: Path, summary: dict[str, Any]) -> None:
    data_docs_dir = output_dir / "data_docs"
    data_docs_dir.mkdir(parents=True, exist_ok=True)
    html = f"""<!doctype html>
<html lang="en">
<head><meta charset="utf-8"><title>BioRemPP Validation Data Docs</title></head>
<body>
  <h1>BioRemPP Validation Data Docs</h1>
  <p>Generated at: {summary["run_timestamp_utc"]}</p>
  <p>Critical checkpoint success: {summary["critical_checkpoint_success"]}</p>
  <p>Warning checkpoint success: {summary["warning_checkpoint_success"]}</p>
  <p>Critical failures: {summary["counts"]["critical_failed_expectations"]}</p>
  <p>Warning failures: {summary["counts"]["warning_failed_expectations"]}</p>
</body>
</html>
"""
    (data_docs_dir / "index.html").write_text(html, encoding="utf-8")


def _build_preflight_failure_outputs(
    output_dir: Path,
    suite_name: str,
    dataset: str,
    expectation_type: str,
    missing_files: list[str],
    validation_mode: str | None = None,
) -> None:
    critical_payload = {
        "checkpoint_name": "critical_gate",
        "success": False,
        "suite_results": [
            {
                "suite_name": suite_name,
                "dataset": dataset,
                "validation_mode": validation_mode,
                "success": False,
                "result": {
                    "success": False,
                    "results": [
                        {
                            "success": False,
                            "expectation_config": {
                                "type": expectation_type,
                                "kwargs": {"missing_files": missing_files},
                            },
                        }
                    ],
                },
            }
        ],
    }
    warning_payload = {"checkpoint_name": "warning_report", "success": True, "suite_results": []}
    summary = build_validation_summary(critical_payload, warning_payload)
    _write_json(output_dir / "critical_checkpoint_result.json", critical_payload)
    _write_json(output_dir / "warning_checkpoint_result.json", warning_payload)
    _write_json(output_dir / "validation_summary.json", summary)


def _resolve_database_csv_relative_path(required_files: list[str]) -> str:
    candidates = [item for item in required_files if item.startswith("database/") and item.endswith(".csv")]
    if not candidates:
        raise KeyError("No database CSV file declared in required_files.")
    if len(candidates) > 1:
        raise ValueError(f"Multiple database CSV files declared in required_files: {candidates}")
    return candidates[0]


_ALWAYS_REQUIRED_NON_CSV = (
    "metadata/kegg_release.json",
    "metadata/keys_consistency_report.json",
    "metadata/links_groundtruth_policy_report.json",
    "reports/workflow_summary.json",
)


def _resolve_current_required_files(settings: ValidationSettings) -> list[str]:
    database_csv_relative_path = _resolve_database_csv_relative_path(settings.required_files)
    required_files = [database_csv_relative_path, *_ALWAYS_REQUIRED_NON_CSV]

    if settings.validation_modes.internal_consistency:
        always_required_set = {database_csv_relative_path, *_ALWAYS_REQUIRED_NON_CSV}
        required_files.extend(
            item
            for item in settings.required_files
            if item not in always_required_set
        )

    return list(dict.fromkeys(required_files))


_PIPELINE_REPORT_FILES = frozenset({
    "metadata/keys_consistency_report.json",
    "metadata/links_groundtruth_policy_report.json",
    "reports/workflow_summary.json",
})


def _resolve_regression_baseline_required_files(settings: ValidationSettings) -> list[str]:
    return [
        item for item in settings.required_files
        if not item.startswith("database/") and item not in _PIPELINE_REPORT_FILES
    ]


def _build_suite_payloads(settings: ValidationSettings) -> dict[str, dict[str, Any]]:
    suite_payloads = {
        "database_critical": _load_suite_payload(settings.expectations_dir / "database_critical.json"),
        "database_warning": _load_suite_payload(settings.expectations_dir / "database_warning.json"),
        "metadata_kegg_critical": _load_suite_payload(settings.expectations_dir / "metadata_kegg_critical.json"),
        "pipeline_reports_critical": _load_suite_payload(settings.expectations_dir / "pipeline_reports_critical.json"),
    }

    if settings.validation_modes.internal_consistency or settings.validation_modes.regression_detection:
        exact_suite_payload = _load_suite_payload(settings.expectations_dir / "analysis_json_exact_critical.json")

        if settings.validation_modes.internal_consistency:
            suite_payloads["analysis_json_internal_consistency_critical"] = _clone_suite_payload(
                exact_suite_payload,
                "analysis_json_internal_consistency_critical",
            )

        if settings.validation_modes.regression_detection:
            suite_payloads["analysis_json_regression_critical"] = _clone_suite_payload(
                exact_suite_payload,
                "analysis_json_regression_critical",
            )

    if settings.validation_modes.internal_consistency:
        suite_payloads["analysis_json_critical"] = _load_suite_payload(
            settings.expectations_dir / "analysis_json_critical.json"
        )
        suite_payloads["analysis_json_warning"] = _load_suite_payload(
            settings.expectations_dir / "analysis_json_warning.json"
        )
        suite_payloads["cross_consistency_critical"] = _load_suite_payload(
            settings.expectations_dir / "cross_consistency_critical.json"
        )

    return suite_payloads


def _build_validation_dataframes(
    settings: ValidationSettings,
    database_csv,
    current_kegg_release: dict[str, Any],
    current_analysis_payloads: dict[str, dict[str, Any]] | None,
    baseline_analysis_payloads: dict[str, dict[str, Any]] | None,
    baseline_kegg_release: dict[str, Any] | None,
    keys_consistency_report: dict[str, Any],
    links_groundtruth_policy_report: dict[str, Any],
    workflow_summary: dict[str, Any],
) -> dict[str, Any]:
    dataframe_by_dataset = {
        "database_csv": database_csv,
        "metadata_kegg": build_kegg_metadata_df(kegg_release=current_kegg_release),
        "pipeline_reports": build_pipeline_reports_critical_df(
            keys_consistency=keys_consistency_report,
            links_groundtruth_policy=links_groundtruth_policy_report,
            workflow_summary=workflow_summary,
        ),
    }

    if settings.validation_modes.internal_consistency and current_analysis_payloads is not None:
        dataframe_by_dataset["analysis_critical"] = build_analysis_critical_df(
            database_df=database_csv,
            analysis_payloads=current_analysis_payloads,
            expected_columns=settings.expected_columns,
        )
        dataframe_by_dataset["analysis_warning"] = build_analysis_warning_df(
            analysis_payloads=current_analysis_payloads
        )
        dataframe_by_dataset["analysis_internal_consistency"] = build_analysis_exact_df(
            database_df=database_csv,
            analysis_payloads=current_analysis_payloads,
            kegg_release=current_kegg_release,
            expected_columns=settings.expected_columns,
        )
        dataframe_by_dataset["cross_consistency"] = build_cross_consistency_df(
            database_df=database_csv,
            basic_stats=current_analysis_payloads["basic_statistics"],
        )

    if settings.validation_modes.regression_detection and baseline_analysis_payloads is not None and baseline_kegg_release is not None:
        dataframe_by_dataset["analysis_regression"] = build_analysis_exact_df(
            database_df=database_csv,
            analysis_payloads=baseline_analysis_payloads,
            kegg_release=baseline_kegg_release,
            expected_columns=settings.expected_columns,
            observed_kegg_release=current_kegg_release,
        )

    return dataframe_by_dataset


def run(settings: ValidationSettings) -> int:
    output_dir = settings.output_dir
    output_dir.mkdir(parents=True, exist_ok=True)

    current_required_files = _resolve_current_required_files(settings)
    resolved_paths = resolve_required_paths(settings.input_results_root, current_required_files)
    missing_files = find_missing_paths(resolved_paths)
    if missing_files:
        _build_preflight_failure_outputs(
            output_dir=output_dir,
            suite_name="preflight_current_required_files",
            dataset="current_results",
            expectation_type="expect_required_files_to_exist",
            missing_files=missing_files,
        )
        return 1

    database_csv_relative_path = _resolve_database_csv_relative_path(settings.required_files)
    database_csv = load_database_csv(
        resolved_paths[database_csv_relative_path],
        sep=settings.csv_delimiter,
    )
    current_kegg_release = load_json(resolved_paths["metadata/kegg_release.json"])
    keys_consistency_report = load_json(resolved_paths["metadata/keys_consistency_report.json"])
    links_groundtruth_policy_report = load_json(resolved_paths["metadata/links_groundtruth_policy_report.json"])
    workflow_summary = load_json(resolved_paths["reports/workflow_summary.json"])

    current_analysis_payloads: dict[str, dict[str, Any]] | None = None
    if settings.validation_modes.internal_consistency:
        current_analysis_payloads = load_analysis_payloads(settings.input_results_root)

    baseline_analysis_payloads: dict[str, dict[str, Any]] | None = None
    baseline_kegg_release: dict[str, Any] | None = None
    if settings.validation_modes.regression_detection:
        baseline_required_files = _resolve_regression_baseline_required_files(settings)
        baseline_resolved_paths = resolve_required_paths(
            settings.regression_baseline_root,
            baseline_required_files,
        )
        missing_baseline_files = find_missing_paths(baseline_resolved_paths)
        if missing_baseline_files:
            _build_preflight_failure_outputs(
                output_dir=output_dir,
                suite_name="preflight_regression_baseline_files",
                dataset="regression_baseline",
                expectation_type="expect_regression_baseline_files_to_exist",
                missing_files=missing_baseline_files,
                validation_mode="regression_detection",
            )
            return 1

        baseline_analysis_payloads = load_analysis_payloads(settings.regression_baseline_root)
        baseline_kegg_release = load_json(baseline_resolved_paths["metadata/kegg_release.json"])

    dataframe_by_dataset = _build_validation_dataframes(
        settings=settings,
        database_csv=database_csv,
        current_kegg_release=current_kegg_release,
        current_analysis_payloads=current_analysis_payloads,
        baseline_analysis_payloads=baseline_analysis_payloads,
        baseline_kegg_release=baseline_kegg_release,
        keys_consistency_report=keys_consistency_report,
        links_groundtruth_policy_report=links_groundtruth_policy_report,
        workflow_summary=workflow_summary,
    )

    suite_payloads = _build_suite_payloads(settings)
    _apply_config_overrides_to_suite_payloads(suite_payloads=suite_payloads, settings=settings)

    context = create_context()
    datasource = create_pandas_datasource(context=context)

    critical_checkpoint_cfg = load_checkpoint_config(settings.checkpoints_dir / "critical_gate.yml")
    warning_checkpoint_cfg = load_checkpoint_config(settings.checkpoints_dir / "warning_report.yml")

    critical_checkpoint_name = critical_checkpoint_cfg.get("name", "critical_gate")
    warning_checkpoint_name = warning_checkpoint_cfg.get("name", "warning_report")

    critical_payload = _run_checkpoint(
        checkpoint_name=critical_checkpoint_name,
        validations=_build_checkpoint_validations(
            checkpoint_name=critical_checkpoint_name,
            checkpoint_config=critical_checkpoint_cfg,
            settings=settings,
        ),
        suite_payloads=suite_payloads,
        dataframe_by_dataset=dataframe_by_dataset,
        datasource=datasource,
    )
    warning_payload = _run_checkpoint(
        checkpoint_name=warning_checkpoint_name,
        validations=_build_checkpoint_validations(
            checkpoint_name=warning_checkpoint_name,
            checkpoint_config=warning_checkpoint_cfg,
            settings=settings,
        ),
        suite_payloads=suite_payloads,
        dataframe_by_dataset=dataframe_by_dataset,
        datasource=datasource,
    )

    summary = build_validation_summary(
        critical_payload=critical_payload,
        warning_payload=warning_payload,
    )

    _write_json(output_dir / "critical_checkpoint_result.json", critical_payload)
    _write_json(output_dir / "warning_checkpoint_result.json", warning_payload)
    _write_json(output_dir / "validation_summary.json", summary)

    if settings.generate_data_docs:
        _write_data_docs_placeholder(output_dir=output_dir, summary=summary)

    if settings.fail_on_critical and not critical_payload.get("success", False):
        return 1
    if settings.fail_on_warning and not warning_payload.get("success", False):
        return 1
    return 0


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    settings = load_settings(args.config)
    return run(settings)


def main_cli() -> None:
    raise SystemExit(main())


if __name__ == "__main__":
    raise SystemExit(main())
