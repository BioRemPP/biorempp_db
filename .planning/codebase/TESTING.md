# Testing Patterns

**Analysis Date:** 2026-05-17

## Test Framework

**Runner:**
- `pytest` >= 8.0, < 9.0
- Declared in `biorempp_validation/pyproject.toml` under `[project.optional-dependencies] dev`
- Config: `[tool.pytest.ini_options]` in `biorempp_validation/pyproject.toml`

**Assertion Library:**
- pytest built-in `assert` statements only — no separate assertion library

**Run Commands:**
```bash
# From biorempp_validation/ directory
pip install -e ".[dev]"        # install package + test deps
pytest                         # run all tests (uses testpaths = ["tests"])
pytest -v                      # verbose output
pytest tests/test_happy_path.py  # run specific file
```

**No coverage configuration detected.** No `pytest-cov` or coverage thresholds defined.

---

## Test File Organization

**Location:** `biorempp_validation/tests/` — all tests are co-located in a single flat directory, separate from source

**Naming:**
- All test files: `test_<scenario>.py`
- All test functions: `test_<what_and_condition>()`

**Directory structure:**
```
biorempp_validation/
├── tests/
│   ├── conftest.py                 # shared fixtures
│   ├── test_happy_path.py          # full valid pipeline passes
│   ├── test_missing_files.py       # missing required file triggers critical failure
│   ├── test_schema_break.py        # dropped DB column triggers critical failure
│   ├── test_kegg_metadata.py       # missing KEGG metadata field triggers critical failure
│   └── test_warning_only_drift.py  # warning threshold breach with fail_on_warning=True
```

---

## Test Types

### Integration Tests (all 5 test files)

All tests are **end-to-end integration tests** that exercise the full `run_validation.main()` function against real filesystem artifacts. There are **no unit tests** for individual modules (`loaders.py`, `consistency_checks.py`, `json_to_dataframe.py`, `report_builder.py`, `gx_context.py`, `settings.py`).

Each test:
1. Copies the real pipeline results from `biorempp_snakemake_version/results/` into `tmp_path`
2. Mutates the data to simulate the failure scenario
3. Calls `main(["--config", str(config_path)])` and checks the exit code
4. Reads the generated `validation_summary.json` and asserts on its content

### E2E Tests

Not applicable — no Snakemake workflow tests or browser/API E2E tests exist.

### R Pipeline Tests

No automated tests exist for the R scripts in `biorempp_snakemake_version/workflow/scripts/`. The Snakemake pipeline is validated at runtime only via the GE validation suite (which is what the Python tests cover).

---

## Test Structure

**Suite organization pattern:**
```python
# Each test file: one function, one scenario
from biorempp_validation.run_validation import main
from biorempp_validation.settings import load_settings

def test_<scenario>(config_path, sample_results_root):
    # 1. Mutate the data
    some_file = sample_results_root / "path/to/file"
    some_file.unlink()   # or: modify contents

    # 2. Run the validator
    exit_code = main(["--config", str(config_path)])

    # 3. Assert exit code
    assert exit_code == 1

    # 4. Assert summary JSON content
    settings = load_settings(config_path)
    summary = json.loads((settings.output_dir / "validation_summary.json").read_text(encoding="utf-8"))
    assert summary["counts"]["critical_failed_expectations"] >= 1
    assert summary["failed_expectations"][0]["expectation_type"] == "expect_required_files_to_exist"
```

---

## Fixtures (`conftest.py`)

All fixtures defined in `biorempp_validation/tests/conftest.py`. No fixtures in test files themselves.

**`project_root` (session-scoped equivalent, function-scoped):**
```python
@pytest.fixture()
def project_root() -> Path:
    return PROJECT_ROOT  # biorempp_validation/
```

**`sample_results_root` (function-scoped, uses `tmp_path`):**
```python
@pytest.fixture()
def sample_results_root(tmp_path: Path) -> Path:
    source = REPO_ROOT / "biorempp_snakemake_version" / "results"
    destination = tmp_path / "results"
    shutil.copytree(source, destination)
    return destination
```
- Copies the real production results directory into pytest's `tmp_path` for isolation
- Each test gets a fresh copy — mutations don't affect other tests

**`config_path` (function-scoped):**
```python
@pytest.fixture()
def config_path(tmp_path: Path, project_root: Path, sample_results_root: Path) -> Path:
    template = project_root / "config" / "validation.yaml"
    cfg = yaml.safe_load(template.read_text(encoding="utf-8"))
    cfg["paths"]["input_results_root"] = str(sample_results_root.resolve())
    cfg["paths"]["output_dir"] = str((tmp_path / "validation_results").resolve())
    cfg["paths"]["expectations_dir"] = str((project_root / "great_expectations" / "expectations").resolve())
    cfg["paths"]["checkpoints_dir"] = str((project_root / "great_expectations" / "checkpoints").resolve())
    path = tmp_path / "validation.yaml"
    path.write_text(yaml.safe_dump(cfg, sort_keys=False), encoding="utf-8")
    return path
```
- Rewrites all paths in the YAML to point to `tmp_path`-based copies
- Uses the real `great_expectations/` suite definitions (not mocked)

---

## Mocking

**Framework:** None. No `unittest.mock`, `pytest-mock`, or any mock library is used.

All external dependencies (filesystem, GE context, pandas) are exercised directly against real data. The `sample_results_root` fixture substitutes for mocking by providing an isolated copy of real artifacts.

**What is tested with real artifacts:**
- `great_expectations` suite execution via `gx_context.create_context()` (ephemeral, in-memory)
- Pandas DataFrame loading from real CSV files
- JSON file reading and writing

**What is not mocked:**
- KEGG API calls — no tests exercise the network-calling scripts (`01_validate_keys_consistency_api.py`, `02_validate_links_groundtruth_policy_api.py`)
- Snakemake rules
- R scripts

---

## Test Scenarios Covered

| Test File | Scenario | Trigger | Expected Exit |
|-----------|----------|---------|---------------|
| `test_happy_path.py` | All valid data passes | Real production results | `0` |
| `test_missing_files.py` | Required file deleted | `analysis/basic_statistics.json` unlinked | `1` |
| `test_schema_break.py` | Column `ko` dropped from CSV | DataFrame column removal | `1` |
| `test_kegg_metadata.py` | `source_url` missing from KEGG JSON | Key popped from payload | `1` |
| `test_warning_only_drift.py` | Warning threshold breached with `fail_on_warning=True` | Row count max=100 | `1` |

---

## Coverage Gaps

**Not covered by automated tests:**

- **Unit-level module tests** — `loaders.py`, `consistency_checks.py`, `json_to_dataframe.py`, `report_builder.py`, `gx_context.py`, `settings.py` have zero dedicated unit tests
- **`strict_exact=False` path** — the default `strict_exact: true` config is used in all tests; the range-based threshold path is partially tested only in `test_warning_only_drift.py`
- **Multiple database CSV files error** — `_resolve_database_csv_relative_path()` raises `ValueError` for multiple candidates; not tested
- **API retry logic** — `fetch_text()` in `01_validate_keys_consistency_api.py` and `02_validate_links_groundtruth_policy_api.py` has no tests
- **R generation scripts** — zero automated tests for `workflow/scripts/generation/`, `workflow/scripts/analysis/`, or `workflow/lib/`
- **Snakemake rules** — no Snakemake test harness
- **`generate_data_docs=True` path** — `_write_data_docs_placeholder()` is never exercised in tests (config uses default, not checked)
- **`fail_on_warning=False` with warning failures** — no test verifies exit=0 when warnings fail but `fail_on_warning=False`

---

## Great Expectations Suites (Runtime Validation, Not pytest)

The following GE expectation suites run via the `biorempp-validate` CLI (not pytest):

- `biorempp_validation/great_expectations/expectations/database_critical.json`
- `biorempp_validation/great_expectations/expectations/database_warning.json`
- `biorempp_validation/great_expectations/expectations/analysis_json_critical.json`
- `biorempp_validation/great_expectations/expectations/analysis_json_exact_critical.json`
- `biorempp_validation/great_expectations/expectations/analysis_json_warning.json`
- `biorempp_validation/great_expectations/expectations/metadata_kegg_critical.json`
- `biorempp_validation/great_expectations/expectations/cross_consistency_critical.json`

Checkpoints:
- `biorempp_validation/great_expectations/checkpoints/critical_gate.yml`
- `biorempp_validation/great_expectations/checkpoints/warning_report.yml`

These are the primary quality gate for the database — the pytest suite validates that the validation framework itself behaves correctly.

---

## Test Data

**Source:** Real Snakemake pipeline outputs at `biorempp_snakemake_version/results/`

The `sample_results_root` fixture copies this live data. There are no synthetic fixtures, factory functions, or dedicated test data files. This means:
- Tests require the Snakemake pipeline to have been run and results to be present
- Tests reflect the actual state of production data at time of running

**Required output files for tests:**
```
biorempp_snakemake_version/results/
├── analysis/
│   ├── basic_statistics.json
│   ├── compound_statistics.json
│   ├── ko_statistics.json
│   ├── enzyme_statistics.json
│   ├── gene_statistics.json
│   ├── crosstab_statistics.json
│   ├── database_metadata.json
│   ├── executive_summary.json
│   └── complete_analysis.json
├── database/
│   └── biorempp_database_v1.1.0.csv
└── metadata/
    └── kegg_release.json
```

---

*Testing analysis: 2026-05-17*
