# Configuration Reference

All runtime behavior of the validation module is controlled by
`biorempp_validation/config/validation.yaml`.

## Shipped Configuration

```yaml
version: "1.1.0"

policy:
  fail_on_critical: true
  fail_on_warning: true
  generate_data_docs: true

validation_modes:
  internal_consistency: true
  regression_detection: true

csv:
  delimiter: ";"

paths:
  input_results_root: ../biorempp_snakemake_version/results
  regression_baseline_root: baselines/release_v1_1_0_kegg_118_0plus
  output_dir: results
  expectations_dir: great_expectations/expectations
  checkpoints_dir: great_expectations/checkpoints

required_files:
  - database/biorempp_database_v1.1.0.csv
  - analysis/basic_statistics.json
  - analysis/compound_statistics.json
  - analysis/ko_statistics.json
  - analysis/enzyme_statistics.json
  - analysis/gene_statistics.json
  - analysis/crosstab_statistics.json
  - analysis/database_metadata.json
  - analysis/executive_summary.json
  - analysis/complete_analysis.json
  - metadata/kegg_release.json

database_contract:
  expected_columns:
    - cpd
    - compoundclass
    - ko
    - ec
    - reaction
    - reaction_description
    - referenceAG
    - compoundname
    - genesymbol
    - genename
    - enzyme_activity

drift_thresholds:
  row_count: {min: 118000, max: 130000}
  unique_compounds: {min: 360, max: 410}
  unique_ko: {min: 1440, max: 1650}
  unique_genesymbol: {min: 1410, max: 1625}
  unique_genename: {min: 1320, max: 1525}
  unique_enzyme_activity: {min: 185, max: 230}
```

## Section Reference

### `policy`

Controls how validation outcomes map to exit codes.

| Key | Type | Shipped value | Meaning |
|-----|------|---------------|---------|
| `fail_on_critical` | bool | `true` | Return exit code `1` when any critical expectation fails. |
| `fail_on_warning` | bool | `true` | Return exit code `1` when any warning expectation fails. |
| `generate_data_docs` | bool | `true` | Write `results/data_docs/index.html`. |

### `validation_modes`

This is the only supported mode-selection interface.

| Key | Type | Default | Meaning |
|-----|------|---------|---------|
| `internal_consistency` | bool | `true` | Validate the current CSV against the current run's analysis JSON artifacts. |
| `regression_detection` | bool | `true` | Validate the current CSV against the committed regression baseline snapshot. |

`strict_exact` is no longer supported and is rejected at config load time.

### `csv`

| Key | Type | Shipped value | Meaning |
|-----|------|---------------|---------|
| `delimiter` | string | `";"` | Delimiter used when loading the BioRemPP CSV. |

### `paths`

All relative paths are resolved from the `biorempp_validation/` project root.

| Key | Shipped value | Meaning |
|-----|---------------|---------|
| `input_results_root` | `../biorempp_snakemake_version/results` | Snakemake output directory to validate. |
| `regression_baseline_root` | `baselines/release_v1_1_0_kegg_118_0plus` | Frozen baseline snapshot for regression detection. |
| `output_dir` | `results` | Directory where validation artifacts are written. |
| `expectations_dir` | `great_expectations/expectations` | Expectation-suite templates. |
| `checkpoints_dir` | `great_expectations/checkpoints` | Checkpoint YAML files. |

### `required_files`

Defines the minimum artifact set for the current run. The validator always
requires the CSV and KEGG metadata. When `internal_consistency: true`, it also
requires the current analysis JSON files. When `regression_detection: true`,
baseline analysis JSON files are required under `regression_baseline_root`.

### `database_contract`

The contract declares:

- the expected ordered CSV columns
- the allowed `referenceAG` vocabulary
- the allowed `compoundclass` vocabulary

These values are injected into Great Expectations suites at runtime.

### `drift_thresholds`

These thresholds drive the warning-level drift checks in `database_warning`.
They are range-based and version-controlled; they are not auto-pinned from the
current run.

| Metric | Min | Max |
|--------|----:|----:|
| `row_count` | 118000 | 130000 |
| `unique_compounds` | 360 | 410 |
| `unique_ko` | 1440 | 1650 |
| `unique_genesymbol` | 1410 | 1625 |
| `unique_genename` | 1320 | 1525 |
| `unique_enzyme_activity` | 185 | 230 |

## Common Scenarios

### Default release-grade validation

```yaml
validation_modes:
  internal_consistency: true
  regression_detection: true
```

Checks exact parity with current artifacts and with the frozen baseline.

### Internal consistency only

```yaml
validation_modes:
  internal_consistency: true
  regression_detection: false
```

Useful when iterating on intended pipeline changes before blessing a new
baseline.

### Regression-only gate

```yaml
validation_modes:
  internal_consistency: false
  regression_detection: true
```

Useful when the current analysis JSON artifacts are not part of the contract
being verified, but drift against the blessed snapshot still matters.
