from __future__ import annotations

import argparse
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


def _apply_config_overrides_to_suite_payloads(
    suite_payloads: dict[str, dict[str, Any]],
    settings: ValidationSettings,
    analysis_payloads: dict[str, dict[str, Any]],
) -> None:
    db_critical = suite_payloads["database_critical"]
    db_warning = suite_payloads["database_warning"]
    analysis_critical = suite_payloads["analysis_json_critical"]
    analysis_warning = suite_payloads["analysis_json_warning"]
    expected_reference_agencies = list(settings.expected_reference_agencies)
    expected_compound_classes = list(settings.expected_compound_classes)

    for expectation in db_critical.get("expectations", []):
        if expectation.get("type") == "expect_table_columns_to_match_ordered_list":
            expectation["kwargs"]["column_list"] = settings.expected_columns
        if expectation.get("type") == "expect_compound_columns_to_be_unique":
            expectation["kwargs"]["column_list"] = settings.expected_columns

    for expectation in analysis_critical.get("expectations", []):
        if expectation.get("type") == "expect_column_values_to_be_between":
            kwargs = expectation.get("kwargs", {})
            if kwargs.get("column") == "basic_total_columns":
                expected_column_count = len(settings.expected_columns)
                kwargs["min_value"] = expected_column_count
                kwargs["max_value"] = expected_column_count

    thresholds = settings.drift_thresholds
    if settings.strict_exact:
        basic = analysis_payloads["basic_statistics"]
        compound = analysis_payloads["compound_statistics"]
        ko = analysis_payloads["ko_statistics"]
        enzyme = analysis_payloads["enzyme_statistics"]

        thresholds = {
            "row_count": {
                "min": int(basic.get("total_entries", -1)),
                "max": int(basic.get("total_entries", -1)),
            },
            "unique_compounds": {
                "min": int(basic.get("unique_compounds", -1)),
                "max": int(basic.get("unique_compounds", -1)),
            },
            "unique_ko": {
                "min": int(basic.get("unique_ko_entries", -1)),
                "max": int(basic.get("unique_ko_entries", -1)),
            },
            "unique_genesymbol": {
                "min": int(basic.get("unique_gene_symbols", -1)),
                "max": int(basic.get("unique_gene_symbols", -1)),
            },
            "unique_genename": {
                "min": int(basic.get("unique_gene_names", -1)),
                "max": int(basic.get("unique_gene_names", -1)),
            },
            "unique_enzyme_activity": {
                "min": int(basic.get("unique_enzyme_activities", -1)),
                "max": int(basic.get("unique_enzyme_activities", -1)),
            },
        }
        expected_reference_agencies = list((compound.get("compounds_per_agency", {}) or {}).keys())
        expected_compound_classes = list((compound.get("compounds_per_class", {}) or {}).keys())

        compound_top_n = len((compound.get("top_20_compounds", {}) or {}).get("compound_ids", []))
        ko_top_n = len((ko.get("top_20_ko", {}) or {}).get("ko_ids", []))
        enzyme_top_n = len((enzyme.get("top_30_enzymes", {}) or {}).get("enzyme_names", []))
        for expectation in analysis_warning.get("expectations", []):
            expectation_type = expectation.get("type")
            kwargs = expectation.get("kwargs", {})
            column = kwargs.get("column")
            if expectation_type != "expect_column_values_to_be_between":
                continue
            if column == "compound_top_n":
                kwargs["min_value"] = compound_top_n
                kwargs["max_value"] = compound_top_n
            elif column == "ko_top_n":
                kwargs["min_value"] = ko_top_n
                kwargs["max_value"] = ko_top_n
            elif column == "enzyme_top_n":
                kwargs["min_value"] = enzyme_top_n
                kwargs["max_value"] = enzyme_top_n
    for expectation in db_warning.get("expectations", []):
        expectation_type = expectation.get("type")
        kwargs = expectation.get("kwargs", {})
        column = kwargs.get("column")

        if expectation_type == "expect_column_distinct_values_to_be_in_set" and column == "referenceAG":
            kwargs["value_set"] = expected_reference_agencies
        elif expectation_type == "expect_column_distinct_values_to_be_in_set" and column == "compoundclass":
            kwargs["value_set"] = expected_compound_classes
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


def _run_checkpoint(
    checkpoint_path: Path,
    suite_payloads: dict[str, dict[str, Any]],
    dataframe_by_dataset: dict[str, Any],
    datasource,
) -> dict[str, Any]:
    checkpoint_cfg = load_checkpoint_config(checkpoint_path)
    checkpoint_name = checkpoint_cfg.get("name", checkpoint_path.stem)

    suite_results: list[dict[str, Any]] = []
    checkpoint_success = True

    for validation in checkpoint_cfg.get("validations", []):
        suite_name = validation["suite"]
        dataset_name = validation["dataset"]

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


def _build_missing_files_outputs(output_dir: Path, missing_files: list[str]) -> None:
    critical_payload = {
        "checkpoint_name": "critical_gate",
        "success": False,
        "suite_results": [
            {
                "suite_name": "preflight_required_files",
                "dataset": "filesystem",
                "success": False,
                "result": {
                    "success": False,
                    "results": [
                        {
                            "success": False,
                            "expectation_config": {
                                "type": "expect_required_files_to_exist",
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


def run(settings: ValidationSettings) -> int:
    output_dir = settings.output_dir
    output_dir.mkdir(parents=True, exist_ok=True)

    resolved_paths = resolve_required_paths(settings.input_results_root, settings.required_files)
    missing_files = find_missing_paths(resolved_paths)
    if missing_files:
        _build_missing_files_outputs(output_dir=output_dir, missing_files=missing_files)
        return 1

    database_csv_relative_path = _resolve_database_csv_relative_path(settings.required_files)
    database_csv = load_database_csv(
        resolved_paths[database_csv_relative_path],
        sep=settings.csv_delimiter,
    )
    analysis_payloads = load_analysis_payloads(settings.input_results_root)
    kegg_release = load_json(resolved_paths["metadata/kegg_release.json"])

    analysis_critical_df = build_analysis_critical_df(
        database_df=database_csv,
        analysis_payloads=analysis_payloads,
        expected_columns=settings.expected_columns,
    )
    analysis_warning_df = build_analysis_warning_df(analysis_payloads=analysis_payloads)
    analysis_exact_df = build_analysis_exact_df(
        database_df=database_csv,
        analysis_payloads=analysis_payloads,
        kegg_release=kegg_release,
        expected_columns=settings.expected_columns,
    )
    kegg_df = build_kegg_metadata_df(kegg_release=kegg_release)
    cross_consistency_df = build_cross_consistency_df(
        database_df=database_csv,
        basic_stats=analysis_payloads["basic_statistics"],
    )

    dataframe_by_dataset = {
        "database_csv": database_csv,
        "analysis_critical": analysis_critical_df,
        "analysis_warning": analysis_warning_df,
        "analysis_exact": analysis_exact_df,
        "metadata_kegg": kegg_df,
        "cross_consistency": cross_consistency_df,
    }

    suite_payloads = {
        "database_critical": _load_suite_payload(settings.expectations_dir / "database_critical.json"),
        "database_warning": _load_suite_payload(settings.expectations_dir / "database_warning.json"),
        "analysis_json_critical": _load_suite_payload(settings.expectations_dir / "analysis_json_critical.json"),
        "analysis_json_exact_critical": _load_suite_payload(
            settings.expectations_dir / "analysis_json_exact_critical.json"
        ),
        "analysis_json_warning": _load_suite_payload(settings.expectations_dir / "analysis_json_warning.json"),
        "metadata_kegg_critical": _load_suite_payload(settings.expectations_dir / "metadata_kegg_critical.json"),
        "cross_consistency_critical": _load_suite_payload(settings.expectations_dir / "cross_consistency_critical.json"),
    }
    _apply_config_overrides_to_suite_payloads(
        suite_payloads=suite_payloads,
        settings=settings,
        analysis_payloads=analysis_payloads,
    )

    context = create_context()
    datasource = create_pandas_datasource(context=context)

    critical_payload = _run_checkpoint(
        checkpoint_path=settings.checkpoints_dir / "critical_gate.yml",
        suite_payloads=suite_payloads,
        dataframe_by_dataset=dataframe_by_dataset,
        datasource=datasource,
    )
    warning_payload = _run_checkpoint(
        checkpoint_path=settings.checkpoints_dir / "warning_report.yml",
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
