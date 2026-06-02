# Testing & Validation Infrastructure

_Last updated: 2026-05-31_

## Summary

BioRemPP DB has no traditional unit test suite. Quality assurance is entirely handled by a Great Expectations (GE) validation layer in the `biorempp_validation/` package. Validation is split into two independent modes — internal consistency (current run vs. its own analysis JSONs) and regression detection (current run vs. a frozen baseline snapshot). Both modes must pass before a release is published.

---

## Architecture Overview

```
biorempp_validation/
├── config/
│   └── validation.yaml              ← single source of truth for all thresholds and contracts
├── great_expectations/
│   ├── checkpoints/
│   │   ├── critical_gate.yml        ← blocks release on failure
│   │   └── warning_report.yml       ← reports drift, configurable to block
│   └── expectations/
│       ├── database_critical.json
│       ├── database_warning.json
│       ├── analysis_json_critical.json
│       ├── analysis_json_exact_critical.json
│       ├── analysis_json_warning.json
│       ├── cross_consistency_critical.json
│       ├── metadata_kegg_critical.json
│       └── pipeline_reports_critical.json
├── baselines/
│   └── release_v1_1_0_kegg_118_0plus/
│       ├── analysis/                ← frozen analysis JSON snapshots
│       └── metadata/                ← frozen KEGG release JSON
├── results/
│   ├── validation_summary.json      ← human/machine-readable pass/fail summary
│   ├── critical_checkpoint_result.json
│   └── warning_checkpoint_result.json
└── src/biorempp_validation/
    ├── run_validation.py            ← main entry point
    ├── settings.py                  ← YAML → frozen dataclass
    ├── gx_context.py                ← GE context and suite runner
    ├── loaders.py                   ← file loading helpers
    ├── json_to_dataframe.py         ← build pandas DataFrames from JSON artifacts
    ├── consistency_checks.py        ← cross-consistency DataFrame builder
    └── report_builder.py            ← build validation_summary.json
```

---

## Validation Modes

Two modes are configured in `validation.yaml` under `validation_modes:` and are completely independent:

### `internal_consistency: true`
Validates the current pipeline run's CSV against the analysis JSON artifacts produced in that same run. Catches bugs where the CSV and the analysis JSONs disagree (e.g., different row counts, column count mismatches). Uses suites: `analysis_json_critical`, `analysis_json_warning`, `analysis_json_internal_consistency_critical`, `cross_consistency_critical`.

### `regression_detection: true`
Validates the current pipeline run's CSV against the frozen baseline snapshot in `baselines/release_v1_1_0_kegg_118_0plus/`. Catches unexpected changes in compound counts, KO distribution, enzyme totals, etc. relative to the reference release. Uses suite: `analysis_json_regression_critical` (a clone of `analysis_json_exact_critical`).

Both modes are enabled by default in the shipped `validation.yaml`.

---

## Checkpoints

### `critical_gate` (`great_expectations/checkpoints/critical_gate.yml`)

Blocks release (`exit 1`) on any failure. Runs these suite/dataset pairs:

| Suite | Dataset | Mode |
|---|---|---|
| `database_critical` | `database_csv` | always |
| `analysis_json_critical` | `analysis_critical` | `internal_consistency` |
| `analysis_json_internal_consistency_critical` | `analysis_internal_consistency` | `internal_consistency` |
| `analysis_json_regression_critical` | `analysis_regression` | `regression_detection` |
| `metadata_kegg_critical` | `metadata_kegg` | always |
| `cross_consistency_critical` | `cross_consistency` | `internal_consistency` |
| `pipeline_reports_critical` | `pipeline_reports` | always |

### `warning_report` (`great_expectations/checkpoints/warning_report.yml`)

Reports drift. Configured to also block (`fail_on_warning: true` in `validation.yaml`). Runs:

| Suite | Dataset | Mode |
|---|---|---|
| `database_warning` | `database_csv` | always |
| `analysis_json_warning` | `analysis_warning` | `internal_consistency` |

---

## Expectation Suites

### `database_critical.json`

Applies to the final database CSV (`biorempp_database_v1.1.0.csv`). Critical checks:
- Columns match the exact ordered list from `validation.yaml → database_contract.expected_columns` (12 columns, patched at runtime).
- Row count ≥ 1.
- No duplicate full rows (`expect_compound_columns_to_be_unique`).
- Non-null: `cpd`, `compoundclass`, `ko`, `referenceAG`, `compoundname`, `genesymbol`, `genename`, `enzyme_activity`.
- `cpd` matches `^C\d{5}$`.
- `ko` matches `^K\d{5}$`.

### `database_warning.json`

Drift bands applied to the CSV at warning level. All `min`/`max` values are patched at runtime from `validation.yaml → drift_thresholds`:

| Check | Column | Band (from validation.yaml) |
|---|---|---|
| `referenceAG` distinct values in set | `referenceAG` | 9 agencies |
| `compoundclass` distinct values in set | `compoundclass` | 12 classes |
| Unique compound count | `cpd` | 360–410 |
| Unique KO count | `ko` | 1440–1650 |
| Unique gene symbol count | `genesymbol` | 1410–1625 |
| Unique gene name count | `genename` | 1320–1525 |
| Unique enzyme activity count | `enzyme_activity` | 185–230 |
| Row count | (table) | 118000–130000 |

### `analysis_json_critical.json`

Validates a single-row DataFrame built from the analysis JSON artifacts. Checks:
- Required keys present in all analysis JSON files (`basic_required_keys_present`, `compound_required_keys_present`, etc.).
- `basic_total_entries` ≥ 1.
- `basic_total_columns` == number of expected columns (patched at runtime from `settings.expected_columns`).
- `basic_expected_columns_match` is `true`.
- `basic_all_missing_values_zero` is `true` (no NA in non-nullable columns).
- `reaction_description_consistent_with_reaction` is `true`.

### `analysis_json_exact_critical.json`

Shared template for both `internal_consistency` and `regression_detection` modes. It is loaded once and cloned into two named suite instances at runtime:
- `analysis_json_internal_consistency_critical` — current run vs. current analysis JSONs
- `analysis_json_regression_critical` — current run vs. baseline snapshot

Checks exact match for: `basic_stats_exact_match`, `compound_total_exact_match`, `compound_class_distribution_exact_match`, `compound_agency_distribution_exact_match`, `compound_top20_exact_match`, `ko_total_exact_match`, `ko_top20_exact_match`, `enzyme_total_exact_match`, `enzyme_top30_exact_match`, `gene_totals_exact_match`, `gene_top20_exact_match`, `crosstab_exact_match`, `executive_summary_exact_match`, `metadata_kegg_exact_match`.

### `analysis_json_warning.json`

Warning-level checks on analysis JSON artifacts:
- `compound_top_n` ≥ 1
- `ko_top_n` ≥ 1
- `enzyme_top_n` ≥ 1
- `executive_text_fields_non_empty` is `true`
- `crosstab_required_sections_present` is `true`
- `reaction_description_fill_rate_percent` between 0 and 100

### `cross_consistency_critical.json`

Validates a 12-row DataFrame where each row is a named metric (`total_entries`, `unique_compounds`, `unique_ko_entries`, etc.). Checks:
- Exactly 12 rows (one per metric).
- `csv_value == stats_value` (the CSV-derived value matches the analysis JSON-derived value for every metric).
- Both `csv_value` and `stats_value` ≥ 0.

### `metadata_kegg_critical.json`

Validates KEGG release metadata (`kegg_release.json`). Checks:
- `release_text`, `parsed_version`, `retrieved_at_utc`, `source_url` are non-null.
- `source_url` is exactly `https://rest.kegg.jp/info/kegg`.
- `parsed_version` matches `^\d+\.\d+\+?$`.
- `retrieved_at_utc` matches ISO 8601 format `^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$`.
- `raw_response_len` ≥ 1.

### `pipeline_reports_critical.json`

Validates pipeline consistency reports. Checks:
- `keys_consistency_na_justified` is `true`.
- `links_policy_union_rate_percent` == 100.0 (all rows have a policy-supported link).
- `links_no_policy_support` == 0.
- `workflow_artifact_hashes_present` is `true`.

---

## Runtime Override Pattern

The JSON suite files on disk contain placeholder values. At runtime, `_apply_config_overrides_to_suite_payloads()` in `run_validation.py` (lines 57–114) patches the loaded suite payloads in memory before handing them to GE:

- `database_critical`: replaces `column_list` in `expect_table_columns_to_match_ordered_list` and `expect_compound_columns_to_be_unique` with `settings.expected_columns`.
- `analysis_json_critical`: replaces `min_value`/`max_value` for the `basic_total_columns` check with `len(settings.expected_columns)`.
- `database_warning`: replaces `value_set` for `referenceAG` and `compoundclass`, and all `{min_value, max_value}` pairs for unique-count expectations, using `settings.drift_thresholds` and `settings.expected_reference_agencies` / `settings.expected_compound_classes`.

This means the JSON files in `great_expectations/expectations/` are not authoritative at runtime — `validation.yaml` is. Do not edit the JSON files to change thresholds; edit `validation.yaml` instead.

---

## Baseline Regression Detection

The baseline lives at `biorempp_validation/baselines/release_v1_1_0_kegg_118_0plus/`. Its structure mirrors the pipeline's `results/analysis/` and `results/metadata/` directories:

```
baselines/release_v1_1_0_kegg_118_0plus/
├── analysis/
│   ├── basic_statistics.json
│   ├── complete_analysis.json
│   ├── compound_statistics.json
│   ├── crosstab_statistics.json
│   ├── database_metadata.json
│   ├── enzyme_statistics.json
│   ├── executive_summary.json
│   ├── gene_statistics.json
│   └── ko_statistics.json
└── metadata/
    └── kegg_release.json
```

The `regression_detection` mode builds a `build_analysis_exact_df()` DataFrame by diffing the current run's analysis payloads against these frozen files. Any change in compound totals, KO distributions, enzyme lists, etc. triggers a critical failure. To update the baseline after an intentional database change, replace the files in this directory and commit.

The `DEFAULT_REGRESSION_BASELINE_ROOT` constant in `settings.py` (line 10) points to this path as the default.

---

## `validation_summary.json`

Written to `biorempp_validation/results/validation_summary.json` after every run. Structure:

```json
{
  "run_timestamp_utc": "2026-06-01T01:43:02Z",
  "critical_checkpoint_success": true,
  "warning_checkpoint_success": true,
  "counts": {
    "critical_failed_expectations": 0,
    "warning_failed_expectations": 0
  },
  "failed_expectations": [],
  "recommendation": "All critical and warning expectations passed."
}
```

`failed_expectations` is a list of objects, each with: `severity`, `validation_mode`, `suite`, `dataset`, `expectation_type`, `kwargs`. This is the primary artifact for CI consumption.

`recommendation` is one of three strings:
- `"All critical and warning expectations passed."`
- `"No critical failures. Review warning-level drift and decide whether to recalibrate thresholds."`
- `"Critical expectations failed. Block release and fix data contract violations before publishing."`

---

## How to Run Validation

### Docker (canonical, reproducible)

From the project root (`BioRemPP_DB_1.0.0/`):

```bash
docker build -f biorempp_validation/env/Dockerfile -t biorempp-validator .
docker run --rm \
  -v "$(pwd)":/workspace \
  biorempp-validator \
  biorempp-validate --config biorempp_validation/config/validation.yaml
```

The Docker image is based on `python:3.11-slim-bookworm`. The entry point is the `biorempp-validate` CLI installed from the `biorempp_validation` package.

### Direct Python (development)

```bash
cd BioRemPP_DB_1.0.0
pip install -e biorempp_validation/
python -m biorempp_validation.run_validation --config biorempp_validation/config/validation.yaml
# or
biorempp-validate --config biorempp_validation/config/validation.yaml
```

### Snakemake Integration

Validation is triggered automatically at the end of the Snakemake pipeline through rules in `biorempp_snakemake_version/workflow/rules/30_validation.smk`:
- `fetch_kegg_link_cache` — downloads fresh KEGG link tables to `cache/kegg_link_cache/`
- `validate_keys_consistency` — produces `results/metadata/keys_consistency_report.json`
- `validate_links_groundtruth_policy` — produces `results/metadata/links_groundtruth_policy_report.json`

---

## Required Input Files for Validation

`validation.yaml → required_files` lists 14 files that must exist under `biorempp_snakemake_version/results/` before validation can proceed:

```
database/biorempp_database_v1.1.0.csv
analysis/basic_statistics.json
analysis/compound_statistics.json
analysis/ko_statistics.json
analysis/enzyme_statistics.json
analysis/gene_statistics.json
analysis/crosstab_statistics.json
analysis/database_metadata.json
analysis/executive_summary.json
analysis/complete_analysis.json
metadata/kegg_release.json
metadata/keys_consistency_report.json
metadata/links_groundtruth_policy_report.json
reports/workflow_summary.json
```

If any file is missing, `run_validation.py` writes a `preflight` failure directly to the output JSONs and exits with code 1 before attempting any GE suite.

---

## What Is Covered

| Area | Covered | Mechanism |
|---|---|---|
| Database CSV schema (column order, types) | Yes | `database_critical` |
| Database CSV row count sanity | Yes | `database_critical` + `database_warning` |
| Non-nullable columns | Yes | `database_critical` |
| KEGG ID format (`^C\d{5}$`, `^K\d{5}$`) | Yes | `database_critical` |
| Duplicate row detection | Yes | `database_critical` (`expect_compound_columns_to_be_unique`) |
| Allowed reference agencies | Yes | `database_warning` (runtime-patched from YAML) |
| Allowed compound classes | Yes | `database_warning` (runtime-patched from YAML) |
| Cardinality drift (unique cpd, ko, gene counts) | Yes | `database_warning` drift bands |
| Analysis JSON structure (required keys) | Yes | `analysis_json_critical` |
| Analysis JSON / CSV cross-consistency | Yes | `cross_consistency_critical` (12 metrics) |
| Exact match to prior release (regression) | Yes | `analysis_json_regression_critical` vs. baseline |
| KEGG metadata traceability | Yes | `metadata_kegg_critical` |
| Pipeline report integrity | Yes | `pipeline_reports_critical` |
| `reaction_description` / `reaction` consistency | Yes | `analysis_json_critical` |
| EC number format validation | No | Not checked in GE suites |
| Reaction ID format (`^R\d{5}$`) | No | Not checked in GE suites |
| Support stage value enumeration | No | No expectation on `support_stage` values |
| End-to-end pipeline execution testing | No | No automated test harness; relies on Snakemake run |

---

## Updating Thresholds

When a KEGG version upgrade intentionally changes row counts or unique-value counts:

1. Run the pipeline to get new output.
2. Update `drift_thresholds` in `biorempp_validation/config/validation.yaml`.
3. Update the baseline snapshot in `biorempp_validation/baselines/release_v1_1_0_kegg_118_0plus/` with the new analysis JSONs.
4. Re-run validation to confirm all expectations pass.
5. Commit with `chore(results):` or `fix(validation):` depending on whether a bug was also fixed.
