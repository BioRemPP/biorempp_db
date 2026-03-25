# Testing Patterns

**Analysis Date:** 2026-03-24

## Test Framework

**Runner:**
- pytest 8.x (from `pyproject.toml`: `"pytest>=8.0,<9.0"`)
- Config: `biorempp_validation/pyproject.toml` specifies `testpaths = ["tests"]`

**Assertion Library:**
- Python built-in `assert` statements (no additional assertion library)

**Run Commands:**
```bash
pytest tests/                  # Run all tests
pytest tests/ -v              # Run with verbose output
pytest tests/ --collect-only  # List tests without running
```

## Test File Organization

**Location:**
- Co-located in separate `tests/` directory (not alongside source)
- Tests are in: `biorempp_validation/tests/`
- Source code in: `biorempp_validation/src/biorempp_validation/`

**Naming:**
- Pattern: `test_<feature>.py`
- Examples:
  - `test_happy_path.py` - Happy path scenario
  - `test_schema_break.py` - Schema contract violations
  - `test_kegg_metadata.py` - KEGG metadata validation
  - `test_missing_files.py` - Missing file handling
  - `test_warning_only_drift.py` - Warning-level drift with policy

**Structure:**
```
biorempp_validation/tests/
├── conftest.py               # Shared fixtures
├── test_happy_path.py
├── test_schema_break.py
├── test_kegg_metadata.py
├── test_missing_files.py
└── test_warning_only_drift.py
```

## Test Structure

**Suite Organization:**
```python
# From test_happy_path.py
def test_happy_path(config_path):
    exit_code = main(["--config", str(config_path)])
    assert exit_code == 0

    settings = load_settings(config_path)
    summary_path = settings.output_dir / "validation_summary.json"
    assert summary_path.exists()

    summary = json.loads(summary_path.read_text(encoding="utf-8"))
    assert summary["counts"]["critical_failed_expectations"] == 0
```

**Patterns:**
- Test functions take fixture parameters: `def test_name(config_path, sample_results_root)`
- Single assertion per semantic unit (may have multiple assert statements)
- Tests load configuration and call `main()` which returns exit codes
- Tests verify output files exist and contain expected structure
- Setup by fixture injection, no explicit setup/teardown code in test functions

**Fixture Usage Pattern:**
```python
@pytest.fixture()
def config_path(tmp_path: Path, project_root: Path, sample_results_root: Path) -> Path:
    template = project_root / "config" / "validation.yaml"
    cfg = yaml.safe_load(template.read_text(encoding="utf-8"))
    # Modify config
    cfg["paths"]["input_results_root"] = str(sample_results_root.resolve())
    # Write to tmp
    path = tmp_path / "validation.yaml"
    path.write_text(yaml.safe_dump(cfg, sort_keys=False), encoding="utf-8")
    return path
```

## Mocking

**Framework:** No mocking library used (no pytest-mock, unittest.mock, etc.)

**Patterns:**
- Tests manipulate real files in temporary directories via fixtures
- No function mocking; tests invoke actual `main()` function
- Files are copied/modified in `tmp_path` to simulate different scenarios

**What to Mock:**
- Nothing is mocked; full integration testing approach

**What NOT to Mock:**
- External API calls: Tests work with file-based data, not real APIs
- Database operations: No database layer, file-based persistence only
- Great Expectations library: Used as-is, not mocked

## Fixtures and Factories

**Test Data:**
```python
# From conftest.py
@pytest.fixture()
def sample_results_root(tmp_path: Path) -> Path:
    source = REPO_ROOT / "biorempp_snakemake_version" / "results"
    destination = tmp_path / "results"
    shutil.copytree(source, destination)
    return destination
```

**Location:**
- `biorempp_validation/tests/conftest.py`
- Fixtures are module-scoped (default `@pytest.fixture()`)
- Three fixtures defined: `project_root`, `sample_results_root`, `config_path`

**Fixture Composition:**
- `config_path` depends on `tmp_path` (pytest built-in), `project_root`, and `sample_results_root`
- Fixtures return Path objects for file manipulation

**Test Data Source:**
- Sample results copied from actual pipeline output: `biorempp_snakemake_version/results/`
- Configuration template: `biorempp_validation/config/validation.yaml`
- Tests modify configuration and files within `tmp_path` to avoid test pollution

## Coverage

**Requirements:** None enforced

**View Coverage:**
- No coverage configuration present
- To measure: `pytest --cov=biorempp_validation tests/` (requires pytest-cov package)

## Test Types

**Unit Tests:**
- Not used; all tests are integration tests
- No isolated function testing

**Integration Tests:**
- All tests are end-to-end validation scenarios
- Tests invoke `main()` function which orchestrates entire validation pipeline
- Tests verify output files and exit codes

Scope of integration tests:
- Happy path: Valid data passes validation
- Schema break: Drops required column, expects failure
- Missing files: Removes required input files, expects failure
- KEGG metadata: Corrupts metadata, expects critical failure
- Warning drift: Exceeds warning thresholds, policy determines exit code

**E2E Tests:**
- Not used; integration tests serve E2E purpose for validation pipeline

## Common Patterns

**Exit Code Testing:**
```python
# Success case
exit_code = main(["--config", str(config_path)])
assert exit_code == 0

# Failure case
exit_code = main(["--config", str(config_path)])
assert exit_code == 1
```

**Output File Verification:**
```python
settings = load_settings(config_path)
summary_path = settings.output_dir / "validation_summary.json"
assert summary_path.exists()

summary = json.loads(summary_path.read_text(encoding="utf-8"))
assert summary["counts"]["critical_failed_expectations"] == 0
```

**File Manipulation in Tests:**
```python
# From test_schema_break.py
csv_path = sample_results_root / "database" / "biorempp_database_v1.0.0.csv"
df = pd.read_csv(csv_path)
df = df.drop(columns=["ko"])
df.to_csv(csv_path, index=False)
```

**Configuration Override Pattern:**
```python
# From test_warning_only_drift.py
cfg = yaml.safe_load(config_path.read_text(encoding="utf-8"))
cfg["strict_exact"] = False
cfg["policy"]["fail_on_warning"] = True
cfg["drift_thresholds"]["row_count"]["max"] = 100
config_path.write_text(yaml.safe_dump(cfg, sort_keys=False), encoding="utf-8")
```

## Test Assertions

**Common Assertions:**
- Exit code checks: `assert exit_code == 0` or `assert exit_code == 1`
- File existence: `assert summary_path.exists()`
- Dictionary key presence: `assert "counts" in summary`
- Array length: `assert len(metadata_failures) > 0`
- Set membership: `assert "expect_table_columns_to_match_ordered_list" in failed_types`
- Numeric equality: `assert summary["counts"]["critical_failed_expectations"] == 0`

## Test Data Flow

**Typical Test Execution:**
1. Fixture `config_path` creates temp directory with copied pipeline results
2. Configuration YAML is loaded and modified (if needed for the test scenario)
3. `main(["--config", str(config_path)])` is called
4. Validation pipeline runs and produces output JSON files
5. Output files are loaded and assertions check structure/counts
6. Exit code indicates overall pass/fail

**Example: Schema Break Test**
1. Copy sample results to temp directory
2. Load CSV and drop required column
3. Run validation with modified CSV
4. Assert exit code is 1
5. Assert specific expectation type in failed list

---

*Testing analysis: 2026-03-24*
