# TESTING — BioRemPP DB 1.0.0

> Last mapped: 2026-05-31

## Summary

Testing in BioRemPP is layered across three distinct systems. The primary automated test suite lives in `biorempp_validation/tests/` and uses pytest against the `biorempp-validation` Python package. Structural and data-quality validation runs as a Great Expectations (GX) checkpoint suite invoked by the `biorempp-validate` CLI and by Snakemake rule `validate_keys_consistency`. The Snakemake pipeline itself embeds two additional validation scripts (`01_validate_keys_consistency_api.py`, `02_validate_links_groundtruth_policy_api.py`) that validate biological key consistency against a cached KEGG API. There is no CI pipeline for the Snakemake pipeline itself — the only CI workflow (`.github/workflows/docs-ci.yml`) tests documentation builds, not pipeline outputs.

---

## Test Framework

**Runner:** pytest  
**Version:** `>=8.0,<9.0` (declared in `biorempp_validation/pyproject.toml`)  
**Config:** `biorempp_validation/pyproject.toml`

```toml
[tool.pytest.ini_options]
testpaths = ["tests"]
```

**Run commands:**
```bash
# From the repo root
cd biorempp_validation
pytest tests/ -q

# Confirmed passing as of 2026-05-31 baseline audit: 5 passed
```

**Install:**
```bash
pip install -e "biorempp_validation[dev]"
```

---

## Test File Organization

All tests live in `biorempp_validation/tests/`. They are flat (no subdirectories). Each test file covers a single failure scenario or the happy path.

```
biorempp_validation/tests/
├── conftest.py                  # Shared fixtures (project_root, sample_results_root, config_path)
├── test_happy_path.py           # Full pipeline passes with real outputs
├── test_missing_files.py        # Missing required file → exit 1, critical failure
├── test_schema_break.py         # Dropped column → critical expectation failure
├── test_kegg_metadata.py        # Missing key in kegg_release.json → critical failure
└── test_warning_only_drift.py   # Warning threshold breach → exit 1 when fail_on_warning=True
```

---

## Test Fixtures (`conftest.py`)

Location: `biorempp_validation/tests/conftest.py`

Three fixtures, all function-scoped:

**`project_root`** — returns the `biorempp_validation/` directory as a `Path`.

**`sample_results_root`** — copies the real pipeline outputs from `biorempp_snakemake_version/results/` into `tmp_path` via `shutil.copytree`. This means tests run against the committed pipeline artifacts, not generated data. Tests that need to inject failures mutate this copy.

**`config_path`** — reads `biorempp_validation/config/validation.yaml`, rewrites the `paths` section to point at `tmp_path` locations (both input and output), then writes the patched config to `tmp_path/validation.yaml`. This isolates test runs from the real output directory.

```python
@pytest.fixture()
def sample_results_root(tmp_path: Path) -> Path:
    source = REPO_ROOT / "biorempp_snakemake_version" / "results"
    destination = tmp_path / "results"
    shutil.copytree(source, destination)
    return destination

@pytest.fixture()
def config_path(tmp_path: Path, project_root: Path, sample_results_root: Path) -> Path:
    template = project_root / "config" / "validation.yaml"
    cfg = yaml.safe_load(template.read_text(encoding="utf-8"))
    cfg["paths"]["input_results_root"] = str(sample_results_root.resolve())
    cfg["paths"]["output_dir"] = str((tmp_path / "validation_results").resolve())
    ...
    path = tmp_path / "validation.yaml"
    path.write_text(yaml.safe_dump(cfg, sort_keys=False), encoding="utf-8")
    return path
```

---

## Test Structure Pattern

Each test function:
1. Optionally mutates the `sample_results_root` copy to inject a fault
2. Calls `main(["--config", str(config_path)])` — the real CLI entry point
3. Asserts `exit_code == 0` (pass) or `exit_code == 1` (fail)
4. Reads `validation_summary.json` from the output dir and asserts on its structure

```python
def test_schema_break_fails_critical(config_path, sample_results_root):
    settings = load_settings(config_path)
    csv_path = sample_results_root / "database" / "biorempp_database_v1.1.0.csv"
    df = pd.read_csv(csv_path, sep=settings.csv_delimiter)
    df = df.drop(columns=["ko"])
    df.to_csv(csv_path, sep=settings.csv_delimiter, index=False)

    exit_code = main(["--config", str(config_path)])
    assert exit_code == 1

    summary = json.loads((settings.output_dir / "validation_summary.json").read_text(encoding="utf-8"))
    failed_types = {item["expectation_type"] for item in summary["failed_expectations"]}
    assert "expect_table_columns_to_match_ordered_list" in failed_types
```

No `pytest.mark` decorators, no parametrize, no `pytest.raises`. All assertions use plain `assert`.

---

## Great Expectations Validation Layer

This is the core data-quality system, not pytest tests. It runs independently of pytest.

**Invocation:**
```bash
biorempp-validate --config biorempp_validation/config/validation.yaml
# or
python -m biorempp_validation.run_validation --config biorempp_validation/config/validation.yaml
```

**Architecture:**
- Entry point: `biorempp_validation/src/biorempp_validation/run_validation.py`
- GX context mode: `ephemeral` (no file-system GX store)
- Datasource: in-memory pandas

**Two checkpoints:**

| Checkpoint | File | Failure mode |
|---|---|---|
| `critical_gate` | `biorempp_validation/great_expectations/checkpoints/critical_gate.yml` | Blocks release; `exit_code=1` |
| `warning_report` | `biorempp_validation/great_expectations/checkpoints/warning_report.yml` | Warning only (configurable via `fail_on_warning`) |

**Seven expectation suites:**

| Suite file | Dataset | Tier |
|---|---|---|
| `database_critical.json` | `database_csv` | critical |
| `database_warning.json` | `database_csv` | warning |
| `analysis_json_critical.json` | `analysis_critical` DataFrame | critical |
| `analysis_json_exact_critical.json` | `analysis_exact` DataFrame | critical |
| `analysis_json_warning.json` | `analysis_warning` DataFrame | warning |
| `metadata_kegg_critical.json` | `metadata_kegg` DataFrame | critical |
| `cross_consistency_critical.json` | `cross_consistency` DataFrame | critical |

All suites live in `biorempp_validation/great_expectations/expectations/`.

**Config-driven overrides:** Suite payloads are mutated at runtime in `run_validation.py:_apply_config_overrides_to_suite_payloads()` to inject expected column lists, drift thresholds, and cardinality constraints from `validation.yaml`. This means suite JSON files are templates, not fixed contracts.

**`strict_exact` mode:** When `strict_exact: true` in `validation.yaml`, drift thresholds are replaced by exact counts re-read from the committed analysis JSON files. This makes the validation self-referential (it checks that the CSV is consistent with its own analysis outputs).

**Output artifacts:**
- `biorempp_validation/results/critical_checkpoint_result.json`
- `biorempp_validation/results/warning_checkpoint_result.json`
- `biorempp_validation/results/validation_summary.json`
- `biorempp_validation/results/data_docs/index.html`

---

## Snakemake Validation Scripts

Two additional validation scripts run as Snakemake rules in `biorempp_snakemake_version/workflow/rules/30_validation.smk`:

### `01_validate_keys_consistency_api.py`
- Location: `biorempp_snakemake_version/workflow/scripts/validation/01_validate_keys_consistency_api.py`
- What it checks: For every row with `ec=NA` or `reaction=NA`, it checks whether KEGG link caches support filling the missing value. Rows where filling is possible are flagged `"incorrect"`.
- Output: `biorempp_snakemake_version/results/metadata/keys_consistency_report.json`
- Trigger: Snakemake rule `validate_keys_consistency`

### `02_validate_links_groundtruth_policy_api.py`
- Location: `biorempp_snakemake_version/workflow/scripts/validation/02_validate_links_groundtruth_policy_api.py`
- What it checks: Row-level link support against KEGG ground truth (direct compound support, KO-level support, or unsupported)
- Output: `biorempp_snakemake_version/results/metadata/links_groundtruth_policy_report.json`
- Trigger: Snakemake rule `validate_links_groundtruth_policy`

Both use a shared KEGG link cache in `biorempp_snakemake_version/work/kegg_link_cache/` (populated by rule `fetch_kegg_link_cache` via `cache_kegg_links.py`).

---

## CI/CD Configuration

**`.github/workflows/docs-ci.yml`** — the only active CI workflow. It:
- Triggers on push/PR to `main`/`dev` when `docs/**` or `mkdocs.yml` changes
- Builds the MkDocs documentation site
- Verifies `site/index.html` exists
- Uploads the built site as an artifact

**No CI workflow exists for:**
- Running the Snakemake pipeline
- Running pytest on `biorempp_validation/`
- Running the `biorempp-validate` CLI against pipeline outputs

---

## Data Validation Patterns

### Preflight (R, Snakemake)
`workflow/scripts/generation/00_check_inputs.R` checks all `REQUIRED_INPUT_FILES` exist before the pipeline starts. Fails with `stop()` on first missing file. Output: `work/preflight_ok.json` (sentinel file used as Snakemake dependency by downstream rules).

### Schema contract
The 11-column schema is declared in two places:
- `workflow/lib/io_contracts.R`: `EXPECTED_DATABASE_COLUMNS`
- `biorempp_validation/config/validation.yaml`: `database_contract.expected_columns`

Column order is enforced at export via `dplyr::select(dplyr::all_of(EXPECTED_DATABASE_COLUMNS))` in `07_extract_enzymes_export.R`.

GX validates column presence and order via `expect_table_columns_to_match_ordered_list`.

### Cross-consistency check
`biorempp_validation/src/biorempp_validation/consistency_checks.py:build_cross_consistency_df()` recomputes key counts (row count, unique compounds, unique KOs, etc.) directly from the CSV and compares them against the committed analysis JSON. The GX suite `cross_consistency_critical.json` then asserts `csv_value == stats_value` for each metric.

### KEGG value format validation
Regex patterns for KEGG identifiers are declared in `workflow/lib/io_contracts.R` (`KEGG_VALUE_PATTERNS`) and also implemented in `workflow/scripts/validation/kegg_api_client.py` (`PATTERNS`). Both check:
- `ko`: `K\d{5}`
- `cpd`: `C\d{5}`
- `reaction`: `R\d{5}`
- `ec`: `(\d+\.){3}[0-9A-Za-z\-]+`

---

## Benchmark Infrastructure

The `.benchmarks/` directory exists in the repo but is empty — no benchmark results are committed. No pytest-benchmark or equivalent framework is configured.

---

## Coverage Gaps

The following are not covered by any automated test:

| Gap | Details | Risk |
|---|---|---|
| Snakemake pipeline execution | No CI runs `snakemake` | Pipeline regressions go undetected until manual run |
| `biorempp-validate` CLI in CI | No GitHub Actions workflow triggers pytest | Validation layer breaks silently on dependency updates |
| R script unit testing | No `testthat` suite | All R logic tested only via full pipeline runs |
| KEGG API client retries | `kegg_api_client.py:fetch_text()` has retry/backoff logic with no test coverage | Retry behavior untested |
| `cache_kegg_links.py` | Not covered by any test | KEGG cache population untested |
| `build_run_report.py` | Not covered by any test | Report generation untested |
| `02_validate_links_groundtruth_policy_api.py` | Not covered by any test | Policy validation logic untested |
| GX suite JSON files | No test exercises changes to expectation JSON directly | Suite edits can silently change validation behavior |
| `strict_exact: false` mode | Only `strict_exact: true` path exercised in committed test suite | Drift threshold mode untested by default |

---

## Confidence

- HIGH: pytest test structure, conftest fixtures, test count (5) — directly observed
- HIGH: GX checkpoint/suite architecture — directly observed from code and config files
- HIGH: Snakemake validation scripts and their outputs — directly read
- HIGH: CI workflow scope (docs only) — directly read from `.github/workflows/docs-ci.yml`
- HIGH: coverage gaps — confirmed by absence of test files and CI workflow triggers
- MEDIUM: `.benchmarks/` is empty — observed from directory listing (no files found)
