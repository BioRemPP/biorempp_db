# Test Suite

The validation module uses mutation-based tests against a copied real results
directory. Each test mutates one artifact or one config branch and asserts that
the validator reports the expected failure.

## Run the Tests

The supported path is the Docker runtime:

```bash
docker compose -f biorempp_snakemake_version/env/docker-compose.yml run --rm validation \
  python -m pytest biorempp_validation/tests -q
```

The container already contains the pinned runtime and test dependencies.

## Test Infrastructure

Core fixtures in `biorempp_validation/tests/conftest.py`:

| Fixture | Purpose |
|---------|---------|
| `sample_results_root` | Copies `biorempp_snakemake_version/results/` into a temp directory. |
| `config_path` | Rewrites config paths to the temp results and temp output directory. |
| `project_root` | Resolves the repository-local validation project root. |

This keeps every mutation isolated from the committed baseline and from the
real pipeline outputs.

## Coverage Areas

### Happy path

Verifies that the shipped results pass with the shipped configuration.

### Missing-file preflight

Deletes a required file and expects a synthetic critical failure before Great
Expectations runs.

### Schema break

Mutates the CSV structure and expects `database_critical` to fail.

### Warning drift

Uses:

- `validation_modes.regression_detection: false`
- `policy.fail_on_warning: true`
- narrowed `drift_thresholds.row_count`

The test expects:

- no critical failures
- at least one warning failure
- failure type `expect_table_row_count_to_be_between`

### Internal consistency failure

Mutates a current analysis JSON artifact while keeping the CSV and baseline
intact. The test expects the internal-consistency exact suite to fail while
regression detection remains independent.

### Regression detection failure

Mutates the copied baseline snapshot while keeping the current run intact. The
test expects only the regression exact suite to fail.

### Baseline preflight

Enables regression detection with a missing or incomplete baseline and expects a
critical preflight failure.

### Legacy-config rejection

Asserts that `strict_exact` is rejected at settings-load time. This protects the
codebase from silently reviving the old compatibility path.

## Warning Threshold Guardrails

`test_warning_only_drift.py` now also verifies that:

- the shipped thresholds accept the current baseline
- warning-only mode remains usable when regression detection is disabled

This prevents stale threshold ranges from re-entering the repository.
