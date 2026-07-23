from __future__ import annotations

import shutil
from pathlib import Path

import pytest
import yaml


PROJECT_ROOT = Path(__file__).resolve().parents[1]
REPO_ROOT = Path(__file__).resolve().parents[2]


@pytest.fixture()
def project_root() -> Path:
    return PROJECT_ROOT


@pytest.fixture()
def sample_results_root(tmp_path: Path) -> Path:
    source = REPO_ROOT / "biorempp_snakemake_version" / "results"
    destination = tmp_path / "results"
    shutil.copytree(source, destination)
    return destination


@pytest.fixture()
def sample_baseline_root(tmp_path: Path, project_root: Path) -> Path:
    source = project_root / "baselines" / "release_v1_1_0_kegg_118_0plus"
    destination = tmp_path / "baseline"
    shutil.copytree(source, destination)
    return destination


@pytest.fixture()
def config_path(
    tmp_path: Path,
    project_root: Path,
    sample_results_root: Path,
    sample_baseline_root: Path,
) -> Path:
    template = project_root / "config" / "validation.yaml"
    cfg = yaml.safe_load(template.read_text(encoding="utf-8"))
    cfg["paths"]["input_results_root"] = str(sample_results_root.resolve())
    cfg["paths"]["regression_baseline_root"] = str(sample_baseline_root.resolve())
    cfg["paths"]["output_dir"] = str((tmp_path / "validation_results").resolve())
    cfg["paths"]["expectations_dir"] = str((project_root / "great_expectations" / "expectations").resolve())
    cfg["paths"]["checkpoints_dir"] = str((project_root / "great_expectations" / "checkpoints").resolve())

    path = tmp_path / "validation.yaml"
    path.write_text(yaml.safe_dump(cfg, sort_keys=False), encoding="utf-8")
    return path
