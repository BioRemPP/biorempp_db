# Test Suite

The validation module ships with a **mutation-based** test suite that
deliberately breaks pipeline artefacts and asserts that the GX framework
detects each fault correctly.  All tests live under
`biorempp_validation/tests/` and run with pytest.

---

## Running the Tests

```bash
cd biorempp_validation
pip install -e ".[dev]"    # install package + test dependencies
pytest tests/ -v
```

!!! tip
    The test fixtures copy the full Snakemake `results/` directory into a
    temporary folder, so every test runs against **real pipeline output** —
    no synthetic data or mocks.

---

## Test Infrastructure

### Shared Fixtures (`conftest.py`)

| Fixture | Scope | Description |
|---------|-------|-------------|
| `project_root` | function | Resolves to the `biorempp_validation/` directory. |
| `sample_results_root` | function | Deep-copies `biorempp_snakemake_version/results/` into `tmp_path/results/` so mutations are isolated. |
| `config_path` | function | Writes a temporary `validation.yaml` with all paths rewritten to `tmp_path`. Expectations and checkpoints still reference the real GX directories. |

The `config_path` fixture rewrites four path keys:

1. `input_results_root` → temporary copy of pipeline results.
2. `output_dir` → `tmp_path/validation_results/`.
3. `expectations_dir` → real `great_expectations/expectations/`.
4. `checkpoints_dir` → real `great_expectations/checkpoints/`.

This ensures mutations only affect the temporary copy while expectations and
checkpoints remain unchanged.

---

## Test Scenarios

### 1. Happy Path (`test_happy_path.py`)

**Mutation:** None — runs against unmodified pipeline output.

**Asserts:**

- `main()` returns exit code **0**.
- `validation_summary.json` exists in the output directory.
- `critical_failed_expectations == 0`.

This is the baseline test: if the pipeline output is correct and the
validation module is working, everything passes.

---

### 2. Missing Required File (`test_missing_files.py`)

**Mutation:** Deletes `analysis/basic_statistics.json` from the temporary
results.

**Asserts:**

- Exit code is **1**.
- `critical_failed_expectations ≥ 1`.
- The first failed expectation type is `expect_required_files_to_exist`.

Tests the preflight file-existence check in the `preflight_critical` suite.

---

### 3. Schema Break (`test_schema_break.py`)

**Mutation:** Drops the `ko` column from the CSV database using pandas.

**Asserts:**

- Exit code is **1**.
- Failed expectation types include
  `expect_table_columns_to_match_ordered_list`.

Tests that column-schema validation catches missing columns at critical
severity.

---

### 4. Warning-Only Drift (`test_warning_only_drift.py`)

**Mutation:** Sets `strict_exact: false`, `fail_on_warning: true`, and
forces `drift_thresholds.row_count.max` to `100` (the actual database has
thousands of rows).

**Asserts:**

- Exit code is **1** (because `fail_on_warning` is `true`).
- `critical_failed_expectations == 0` (schema and reproducibility still pass).
- `warning_failed_expectations ≥ 1`.

Tests that warning-level cardinality drift is correctly detected and that the
`fail_on_warning` policy flag controls the exit code.

---

### 5. KEGG Metadata Corruption (`test_kegg_metadata.py`)

**Mutation:** Removes the `source_url` key from `metadata/kegg_release.json`.

**Asserts:**

- Exit code is **1**.
- At least one failed expectation belongs to the `metadata_kegg_critical`
  suite.

Tests the KEGG metadata contract: every required field must be present.

---

## Mutation Coverage Matrix

| Test | Mutated Artefact | Severity | Suite Triggered |
|------|-----------------|----------|----------------|
| Happy path | *(none)* | — | All pass |
| Missing file | `basic_statistics.json` | Critical | `preflight_critical` |
| Schema break | CSV column `ko` removed | Critical | `database_schema_critical` |
| Warning drift | Config thresholds narrowed | Warning | `database_schema_warning` |
| KEGG metadata | `source_url` key removed | Critical | `metadata_kegg_critical` |

---

## Adding New Tests

Follow the existing mutation pattern:

1. Use the `config_path` and `sample_results_root` fixtures.
2. Mutate a specific artefact in the temporary results directory.
3. Call `main(["--config", str(config_path)])`.
4. Assert exit code and inspect `validation_summary.json` for the expected
   failure type and suite.

```python
def test_my_new_scenario(config_path, sample_results_root):
    # 1. Mutate an artefact
    target = sample_results_root / "analysis" / "some_file.json"
    target.write_text("{}", encoding="utf-8")

    # 2. Run validation
    exit_code = main(["--config", str(config_path)])

    # 3. Assert expected failure
    assert exit_code == 1
    settings = load_settings(config_path)
    summary = json.loads(
        (settings.output_dir / "validation_summary.json").read_text()
    )
    assert summary["counts"]["critical_failed_expectations"] >= 1
```
