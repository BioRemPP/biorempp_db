<!--
Page status: verified
Audience: maintainers, reviewers
Applies to: GX
Version scope: GX validator v1.1.0
Last verified on: 2026-06-24
Primary sources:
- biorempp_validation/great_expectations/checkpoints/critical_gate.yml
- biorempp_validation/great_expectations/checkpoints/warning_report.yml
- biorempp_validation/great_expectations/expectations/database_critical.json
- biorempp_validation/great_expectations/expectations/database_warning.json
- biorempp_validation/great_expectations/expectations/analysis_json_critical.json
- biorempp_validation/great_expectations/expectations/analysis_json_warning.json
- biorempp_validation/great_expectations/expectations/analysis_json_exact_critical.json
- biorempp_validation/great_expectations/expectations/metadata_kegg_critical.json
- biorempp_validation/great_expectations/expectations/cross_consistency_critical.json
- biorempp_validation/great_expectations/expectations/pipeline_reports_critical.json
- biorempp_validation/src/biorempp_validation/run_validation.py
Observed artifacts:
- biorempp_validation/results/critical_checkpoint_result.json
- biorempp_validation/results/warning_checkpoint_result.json
-->

# Expectation Suites

The validator ships eight expectation suite JSON files under `biorempp_validation/great_expectations/expectations/`. At runtime, one of them is cloned into two concrete suite names so the active checkpoint execution surface contains nine distinct suite identities.

## Suite Inventory

| Suite file | Checkpoint | Runtime dataset | Active when | Main role |
|---|---|---|---|---|
| `database_critical.json` | `critical_gate` | `database_csv` | always | enforce ordered schema, non-null critical columns, identifier regexes, and full-row uniqueness |
| `database_warning.json` | `warning_report` | `database_csv` | always | enforce controlled vocabularies and drift windows |
| `analysis_json_critical.json` | `critical_gate` | `analysis_critical` | `internal_consistency` | verify required sections and structural consistency of the current analysis bundle |
| `analysis_json_warning.json` | `warning_report` | `analysis_warning` | `internal_consistency` | verify top-N lengths, summary text presence, and reaction-description coverage range |
| `analysis_json_exact_critical.json` | `critical_gate` via runtime clones | template only | `internal_consistency` and/or `regression_detection` | exact parity checks between current CSV-derived metrics and a reference analysis snapshot |
| `metadata_kegg_critical.json` | `critical_gate` | `metadata_kegg` | always | enforce KEGG provenance fields and URL/timestamp format |
| `cross_consistency_critical.json` | `critical_gate` | `cross_consistency` | `internal_consistency` | enforce metric parity between the CSV and `basic_statistics.json` |
| `pipeline_reports_critical.json` | `critical_gate` | `pipeline_reports` | always | enforce sentinel expectations on the integrated pipeline validation reports and workflow summary |

## Runtime Clones

`analysis_json_exact_critical.json` is a template suite. `run_validation.py` clones it into:

- `analysis_json_internal_consistency_critical`
- `analysis_json_regression_critical`

The current observed critical checkpoint payload confirms both concrete suite names when both validation modes are enabled.

## Mode Wiring

The suites split into three groups:

### Mode-agnostic suites

These suites run regardless of the two GX mode flags:

- `database_critical`
- `database_warning`
- `metadata_kegg_critical`
- `pipeline_reports_critical`

### Internal-consistency suites

These suites run only when `validation_modes.internal_consistency: true`:

- `analysis_json_critical`
- `analysis_json_warning`
- `cross_consistency_critical`
- `analysis_json_internal_consistency_critical`

### Regression-only suite

This suite runs only when `validation_modes.regression_detection: true`:

- `analysis_json_regression_critical`

## Config-Driven Overrides

The suite JSON files are not completely static. `run_validation.py` mutates some expectation kwargs at runtime using `validation.yaml`.

### `database_critical`

Runtime overrides inject:

- `database_contract.expected_columns` into `expect_table_columns_to_match_ordered_list`
- the same column list into `expect_compound_columns_to_be_unique`

### `analysis_json_critical`

Runtime overrides set the `basic_total_columns` expectation so that both `min_value` and `max_value` equal `len(database_contract.expected_columns)`.

### `database_warning`

Runtime overrides inject:

- `database_contract.expected_reference_agencies`
- `database_contract.expected_compound_classes`
- `drift_thresholds.row_count`
- `drift_thresholds.unique_compounds`
- `drift_thresholds.unique_ko`
- `drift_thresholds.unique_genesymbol`
- `drift_thresholds.unique_genename`
- `drift_thresholds.unique_enzyme_activity`

This means the effective validator contract is the combination of suite JSON plus runtime config.

## About `expect_compound_columns_to_be_unique`

The repository does not define a local custom expectation class for `expect_compound_columns_to_be_unique`. The suite references it in `database_critical.json`, and the current `critical_checkpoint_result.json` shows that expectation executing successfully in the active runtime.

That matters for documentation because the behavior is present, but it is not implemented as repository-local extension code under `src/`.

## Related Pages

- [Architecture](architecture.md)
- [Validation Modes](validation-modes.md)
- [Configuration Reference](configuration.md)
