<!--
Page status: verified
Audience: maintainers, reviewers, advanced operators
Applies to: GX
Version scope: GX validator v1.1.0
Last verified on: 2026-06-24
Primary sources:
- biorempp_validation/config/validation.yaml
- biorempp_validation/src/biorempp_validation/settings.py
- biorempp_validation/src/biorempp_validation/run_validation.py
- biorempp_validation/src/biorempp_validation/gx_context.py
- biorempp_validation/src/biorempp_validation/json_to_dataframe.py
- biorempp_validation/src/biorempp_validation/loaders.py
- biorempp_validation/great_expectations/great_expectations.yml
- biorempp_validation/great_expectations/checkpoints/critical_gate.yml
- biorempp_validation/great_expectations/checkpoints/warning_report.yml
Known gaps:
- `version` is loaded into `ValidationSettings`, but the current runtime does not consume it elsewhere in `src/`
-->

# Configuration Reference

The GX validator is configured by `biorempp_validation/config/validation.yaml`. `settings.py` resolves that file into a `ValidationSettings` object and normalizes every configured path relative to the `biorempp_validation/` project root.

## Top-Level Sections

| Section | Role |
|---|---|
| `version` | release label stored in settings |
| `policy` | blocking behavior and summary-page toggle |
| `validation_modes` | enable or disable the two analysis-comparison mode families |
| `csv` | delimiter used to load the database CSV |
| `paths` | input, baseline, output, expectations, and checkpoint locations |
| `required_files` | current results contract used by preflight and downstream loading |
| `database_contract` | public schema, nullable fields, and controlled vocabularies |
| `drift_thresholds` | warning-level row count and uniqueness windows |

## `policy`

The shipped config currently sets:

- `fail_on_critical: true`
- `fail_on_warning: true`
- `generate_summary_page: true`

Runtime behavior:

- `fail_on_critical` determines whether a failed critical checkpoint returns exit code `1`
- `fail_on_warning` determines whether a failed warning checkpoint also returns exit code `1`
- `generate_summary_page` controls whether `results/data_docs/index.html` is written

If `fail_on_warning` is omitted, `settings.py` defaults it to `false`. The shipped config overrides that default to `true`.

## `validation_modes`

The validator supports exactly two mode keys:

- `internal_consistency`
- `regression_detection`

If the legacy key `strict_exact` appears in the YAML, `settings.py` raises `ValueError` at load time.

## `csv`

The current config sets:

- `delimiter: ";"`

This value is passed into `load_database_csv()` and therefore controls how the final database file is parsed by the validator.

## `paths`

The current path block is:

| Key | Current value | Meaning |
|---|---|---|
| `paths.input_results_root` | `../biorempp_snakemake_version/results` | current Snakemake results tree |
| `paths.regression_baseline_root` | `baselines/release_v1_1_0_kegg_118_0plus` | frozen baseline snapshot |
| `paths.output_dir` | `results` | GX validator output directory |
| `paths.expectations_dir` | `great_expectations/expectations` | suite JSON directory |
| `paths.checkpoints_dir` | `great_expectations/checkpoints` | checkpoint YAML directory |

All relative paths are resolved from the `biorempp_validation/` project root, not from the repository root.

## `required_files`

`required_files` is the current-results contract used by preflight. The shipped list includes:

- one database CSV file
- nine analysis JSON files
- three metadata/report JSON files
- one workflow summary JSON file

The validator does not use that list uniformly across every mode.

### Current results preflight

`_resolve_current_required_files()` always requires:

- the database CSV
- `metadata/kegg_release.json`
- `metadata/keys_consistency_report.json`
- `metadata/links_groundtruth_policy_report.json`
- `reports/workflow_summary.json`

It adds the remaining analysis JSON files only when `internal_consistency` is enabled.

### Regression baseline preflight

`_resolve_regression_baseline_required_files()` derives the baseline contract from the same `required_files` list but excludes:

- all `database/*` files
- `metadata/keys_consistency_report.json`
- `metadata/links_groundtruth_policy_report.json`
- `reports/workflow_summary.json`

That is why the regression baseline snapshot contains analysis JSON plus KEGG release metadata, not a full copy of the current results tree.

## `database_contract`

The contract block currently defines:

- `nullable_columns`
- `expected_columns`
- `expected_reference_agencies`
- `expected_compound_classes`

These values are consumed at runtime in two ways.

### DataFrame construction

`json_to_dataframe.py` uses:

- `expected_columns` to compare ordered schema and compute exact analysis parity
- `nullable_columns` to exclude allowed nullable fields from the zero-missing check in `build_analysis_critical_df()`

### Suite overrides

`run_validation.py` injects:

- `expected_columns` into `database_critical`
- `expected_reference_agencies` into `database_warning`
- `expected_compound_classes` into `database_warning`

## `drift_thresholds`

The shipped threshold keys are:

- `row_count`
- `unique_compounds`
- `unique_ko`
- `unique_genesymbol`
- `unique_genename`
- `unique_enzyme_activity`

`run_validation.py` wires these values into the warning suite at runtime. They do not affect the critical checkpoint.

## Runtime Override Summary

Three configuration areas materially rewrite suite behavior at runtime:

| Config area | Affected suite(s) | Effect |
|---|---|---|
| `database_contract.expected_columns` | `database_critical`, `analysis_json_critical` | ordered schema and total-column expectations |
| `database_contract.expected_reference_agencies`, `database_contract.expected_compound_classes` | `database_warning` | controlled vocabulary sets |
| `drift_thresholds.*` | `database_warning` | warning-level range limits |

This means `validation.yaml` is not just environment configuration. It is part of the effective validation contract.

## Great Expectations Assets

The config also points to filesystem locations for suite JSON files and checkpoint YAML files. In the current runtime, those assets are loaded directly by Python code from `expectations_dir` and `checkpoints_dir`.

The validator does not currently load suites or checkpoints through GE stores in `great_expectations.yml`.

## Related Pages

- [Architecture](architecture.md)
- [Expectation Suites](expectation-suites.md)
- [Validation Modes](validation-modes.md)
- [Baseline Management](baseline-management.md)
