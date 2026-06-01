from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Any

import yaml


DEFAULT_REGRESSION_BASELINE_ROOT = "baselines/release_v1_1_0_kegg_118_0plus"


@dataclass(frozen=True)
class ValidationModes:
    internal_consistency: bool
    regression_detection: bool


@dataclass(frozen=True)
class ValidationSettings:
    version: str
    fail_on_critical: bool
    fail_on_warning: bool
    generate_summary_page: bool
    validation_modes: ValidationModes
    csv_delimiter: str
    input_results_root: Path
    regression_baseline_root: Path
    output_dir: Path
    expectations_dir: Path
    checkpoints_dir: Path
    required_files: list[str]
    expected_columns: list[str]
    expected_reference_agencies: list[str]
    expected_compound_classes: list[str]
    drift_thresholds: dict[str, dict[str, int]]
    config_path: Path


def _resolve_from_project_root(project_root: Path, candidate: str) -> Path:
    path = Path(candidate)
    if path.is_absolute():
        return path
    return (project_root / path).resolve()


def _resolve_validation_modes(cfg: dict[str, Any]) -> ValidationModes:
    validation_modes = cfg.get("validation_modes")
    if "strict_exact" in cfg:
        raise ValueError(
            "`strict_exact` is no longer supported. Use `validation_modes.internal_consistency` "
            "and `validation_modes.regression_detection`."
        )

    if isinstance(validation_modes, dict):
        return ValidationModes(
            internal_consistency=bool(validation_modes.get("internal_consistency", True)),
            regression_detection=bool(validation_modes.get("regression_detection", True)),
        )

    return ValidationModes(
        internal_consistency=True,
        regression_detection=True,
    )


def load_settings(config_path: str | Path) -> ValidationSettings:
    config_path = Path(config_path).resolve()
    project_root = config_path.parent.parent

    with config_path.open("r", encoding="utf-8") as handle:
        cfg: dict[str, Any] = yaml.safe_load(handle)

    paths = cfg["paths"]
    policy = cfg["policy"]
    db_contract = cfg["database_contract"]
    csv_cfg = cfg.get("csv", {})
    validation_modes = _resolve_validation_modes(cfg)

    return ValidationSettings(
        version=str(cfg.get("version", "1.1.0")),
        fail_on_critical=bool(policy.get("fail_on_critical", True)),
        fail_on_warning=bool(policy.get("fail_on_warning", False)),
        generate_summary_page=bool(policy.get("generate_summary_page", True)),
        validation_modes=validation_modes,
        csv_delimiter=str(csv_cfg.get("delimiter", ",")),
        input_results_root=_resolve_from_project_root(project_root, paths["input_results_root"]),
        regression_baseline_root=_resolve_from_project_root(
            project_root,
            paths.get("regression_baseline_root", DEFAULT_REGRESSION_BASELINE_ROOT),
        ),
        output_dir=_resolve_from_project_root(project_root, paths["output_dir"]),
        expectations_dir=_resolve_from_project_root(project_root, paths["expectations_dir"]),
        checkpoints_dir=_resolve_from_project_root(project_root, paths["checkpoints_dir"]),
        required_files=list(cfg["required_files"]),
        expected_columns=list(db_contract["expected_columns"]),
        expected_reference_agencies=list(db_contract["expected_reference_agencies"]),
        expected_compound_classes=list(db_contract["expected_compound_classes"]),
        drift_thresholds=dict(cfg["drift_thresholds"]),
        config_path=config_path,
    )
