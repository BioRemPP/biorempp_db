# BioRemPP Validation Baseline Audit

Date: 2026-05-31

## Scope

Audit the current Great Expectations validation layer in `biorempp_validation` against the Snakemake outputs produced by `biorempp_snakemake_version`.

Validated artifacts and code paths reviewed:

- Current pipeline outputs under `biorempp_snakemake_version/results/`
- Great Expectations configuration and runtime overrides
- Analysis JSON producers in `workflow/scripts/analysis/`
- Reporting and KEGG validation artifacts in `workflow/scripts/validation/` and `workflow/scripts/reporting/`

## Executive Conclusion

The current Great Expectations pipeline is compliant with the current Snakemake outputs for the dataset present in the repository.

Observed execution status:

- `python -m biorempp_validation.run_validation --config biorempp_validation/config/validation.yaml`: passed
- `pytest biorempp_validation/tests -q`: `5 passed`

However, the validation layer has important blind spots and outdated fallback assumptions:

1. The default `strict_exact: true` mode is largely self-referential and does not act as an external regression baseline.
2. The fallback drift baseline for `strict_exact: false` is stale for row count and fails against the current dataset.
3. Great Expectations does not cover several artifacts that the current Snakemake pipeline treats as first-class outputs.
4. Documentation is materially outdated and still describes the old `v1.0.0` / 8-column contract.
5. Some exact-match checks are vulnerable to tie-order drift because Python recomputation uses deterministic secondary sorts while the R producers do not consistently define tie-breakers.

## Current Baseline

Source of truth used in this audit:

- Pipeline version: `1.1.0`
- Workflow summary timestamp: `2026-05-18T15:14:08Z`
- KEGG parsed version: `118.0+`
- KEGG retrieved at: `2026-05-18T15:12:59Z`

Observed database baseline:

- Rows: `123759`
- Columns: `11`
- Unique compounds: `384`
- Unique KO entries: `1543`
- Unique gene symbols: `1517`
- Unique gene names: `1422`
- Unique enzyme activities: `206`
- Unique reference agencies: `9`
- Unique compound classes: `12`

Observed missingness from `basic_statistics.json`:

- `ec`: `961`
- `reaction`: `2223`
- `reaction_description`: `2223`
- All other declared columns: `0`

Observed coverage / consistency baseline:

- Rows with any NA in `ec` or `reaction`: `3111`
- Remaining NA rows classified as justified: `true`
- Rows with reaction description among rows with reaction: `121536 / 121536` (`100.0%`)
- KO unmatched count in `metadata.link_match.coverage.kos`: `16`
- Compound unmatched count in `metadata.link_match.coverage.cpds`: `215`
- Pair support total: `3422`
- Unsupported pair count: `25`
- Dense rows: `120648`
- `ec_only`: `2150`
- `reaction_only`: `888`
- `both_na`: `73`
- Policy union rate: `100.0%`
- Strict5 rate: `2.4169%`

Important note on duplicates:

- Full-row duplicates in the final CSV: `0`
- The metadata field `link_match.consistency_sentinels.duplicate_full_rows = 74552` is not a full-row duplicate count. It is computed on the reduced normalized subset `cpd, ko, ec, reaction, reaction_description` in `workflow/scripts/analysis/07_metadata.R:115-123` and `:254`.

## What Is Correct Today

### Output contract alignment

The Snakemake pipeline currently exports the 11-column database contract:

- `workflow/lib/io_contracts.R:9-21`
- `workflow/scripts/generation/07_extract_enzymes_export.R:48-60`

The validation config expects the same 11 columns:

- `biorempp_validation/config/validation.yaml:33-45`

Even though the JSON suites still contain the old 8-column declaration:

- `biorempp_validation/great_expectations/expectations/database_critical.json:5-16`
- `biorempp_validation/great_expectations/expectations/analysis_json_critical.json:121-127`

runtime overrides correct those suites before execution:

- `biorempp_validation/src/biorempp_validation/run_validation.py:61-73`

### Structural and reproducibility checks

The current validator correctly enforces:

- CSV schema/order
- non-null required business columns
- regex format for `cpd` and `ko`
- required keys in analysis JSON files
- exact recomputation of analysis outputs from the CSV
- KEGG metadata structure
- parity between CSV-derived basic stats and `basic_statistics.json`

Relevant code:

- `biorempp_validation/src/biorempp_validation/run_validation.py:267-361`
- `biorempp_validation/src/biorempp_validation/json_to_dataframe.py:13-429`
- `biorempp_validation/src/biorempp_validation/consistency_checks.py:13-48`

### Current tests

The packaged tests still pass against the repository sample results:

- `biorempp_validation/tests/test_happy_path.py`
- `biorempp_validation/tests/test_missing_files.py`
- `biorempp_validation/tests/test_schema_break.py`
- `biorempp_validation/tests/test_kegg_metadata.py`
- `biorempp_validation/tests/test_warning_only_drift.py`

## Findings

### F1. `strict_exact` is self-referential and weak as a drift baseline

Severity: High

When `strict_exact: true`, warning thresholds are overwritten using the same run's own analysis JSON payloads:

- `biorempp_validation/src/biorempp_validation/run_validation.py:75-155`

Examples:

- row count warning becomes `min == max == basic_statistics.total_entries`
- unique value warnings become `min == max ==` values computed by the same run
- agency and class vocabularies are replaced by keys extracted from `compound_statistics.json`

Impact:

- The validator is very good at checking internal consistency between the CSV and JSON produced by the same pipeline run.
- It is not a strong external regression guard against unintended output drift across pipeline revisions.
- A materially changed pipeline can still pass as long as it produces self-consistent CSV + JSON and the declared schema remains aligned.

### F2. Fallback drift thresholds are stale for the current row-count scale

Severity: High

Configured fallback thresholds:

- `biorempp_validation/config/validation.yaml:70-76`

Current row-count threshold:

- `7000-20000`

Current observed row count:

- `123759`

Contraprova performed with temporary config:

- set `strict_exact: false`
- set `fail_on_warning: false`
- validation result: warning checkpoint failed on `expect_table_row_count_to_be_between`

Impact:

- The fallback baseline does not represent the current pipeline output scale.
- If someone disables `strict_exact`, the validator immediately becomes inconsistent with the present dataset.

### F3. Great Expectations does not validate several current pipeline outputs

Severity: High

The Snakemake `all` rule declares these outputs as part of the pipeline contract:

- `database_xlsx`
- `metadata/keys_consistency_report.json`
- `metadata/links_groundtruth_policy_report.json`
- `reports/workflow_summary.json`

References:

- `biorempp_snakemake_version/Snakefile:33-41`
- `biorempp_snakemake_version/workflow/rules/30_validation.smk:39-102`
- `biorempp_snakemake_version/workflow/rules/90_reporting.smk:3-35`

But the Great Expectations preflight only requires:

- one CSV
- analysis JSONs
- `metadata/kegg_release.json`

Reference:

- `biorempp_validation/config/validation.yaml:20-31`

Contraprova performed with temporary copied results:

- removed `reports/workflow_summary.json`
- removed `metadata/keys_consistency_report.json`
- removed `metadata/links_groundtruth_policy_report.json`
- validation still passed with `0` failures

Impact:

- The current GE layer does not validate all artifacts that the pipeline itself considers release outputs.
- High-signal metadata about KEGG support policy and report provenance can disappear or drift without affecting validation status.

### F4. Documentation still describes the old `v1.0.0` / 8-column world

Severity: Medium

Examples:

- `docs/validation-gx/data-contracts.md:11-35`
- `docs/validation-gx/data-contracts.md:136-163`
- `docs/validation-gx/expectation-suites.md:23-48`
- `docs/validation-gx/expectation-suites.md:84-105`

Observed issues:

- references to `biorempp_database_v1.0.0.csv`
- 8-column schema instead of 11
- claim that all missing values must be zero
- claim that `expect_compound_columns_to_be_unique` is a custom expectation implemented locally

Impact:

- Readers of the docs get the wrong contract.
- The code is right today only because runtime mutation compensates for stale suite JSON and stale documentation.

### F5. Exact-match ordering is potentially fragile on ties

Severity: Medium

Python exact recomputation uses deterministic tie-break sorting:

- `biorempp_validation/src/biorempp_validation/json_to_dataframe.py:154-274`

Examples:

- compounds sorted by `frequency desc, cpd asc`
- KOs sorted by `frequency desc, ko asc`
- enzymes sorted by `frequency desc, enzyme_activity asc`
- crosstabs sorted by `count desc` plus lexical secondary keys

But the R producers often only sort by descending count/frequency:

- `workflow/scripts/analysis/02_compound_statistics.R:23-27`
- `workflow/scripts/analysis/03_ko_statistics.R:13-22`
- `workflow/scripts/analysis/04_enzyme_statistics.R:13-23`
- `workflow/scripts/analysis/05_gene_statistics.R:12-24`
- `workflow/scripts/analysis/06_crosstab_statistics.R:12-28`

Impact:

- The current sample outputs pass.
- Future runs can fail exact checks purely because of tie-order differences across runtime/library versions, even if the counts are semantically correct.

### F6. `duplicate_full_rows` in metadata is mislabeled

Severity: Medium

The metadata report names the metric `duplicate_full_rows`, but it is computed after reducing the table to:

- `cpd`
- `ko`
- `ec`
- `reaction`
- `reaction_description`

References:

- `workflow/scripts/analysis/07_metadata.R:115-123`
- `workflow/scripts/analysis/07_metadata.R:254-305`

Observed reality:

- actual full-row duplicates in the CSV: `0`
- reported `duplicate_full_rows`: `74552`

Impact:

- The metric name suggests a stronger invariant than what is actually measured.
- This can confuse downstream interpretation of workflow reports and metadata.

### F7. Generated "data docs" are only a placeholder HTML file

Severity: Low

`generate_data_docs: true` currently writes a minimal placeholder page, not real Great Expectations Data Docs:

- `biorempp_validation/src/biorempp_validation/run_validation.py:208-224`

Impact:

- The feature name suggests richer GX-native documentation than what is actually produced.

## Recommended Adjustments

### Priority 1

1. Decide whether `biorempp_validation` should be an internal-consistency validator or a release-regression validator.
   - If internal consistency is the goal, keep `strict_exact` but document that it is self-referential.
   - If regression control is the goal, add an external frozen baseline artifact and compare against that instead of the same run's JSON.

2. Expand required artifact coverage to include:
   - `database/biorempp_database_v1.1.0.xlsx`
   - `metadata/keys_consistency_report.json`
   - `metadata/links_groundtruth_policy_report.json`
   - `reports/workflow_summary.json`

3. Add new suites or lightweight checks for those artifacts.
   Suggested minimum checks:
   - `keys_consistency_report.json`: `all_remaining_na_justified == true`, totals consistent with `basic_statistics.json`
   - `links_groundtruth_policy_report.json`: `policy_union_rate_percent == 100.0`, `no_policy_support == 0`
   - `workflow_summary.json`: hashes present, timestamps present, embedded counts consistent with metadata
   - XLSX: file exists and row/column count matches CSV

### Priority 2

4. Recalibrate `strict_exact: false` drift thresholds to the current baseline.
   Minimum immediate fix:
   - row_count max must be raised above `123759`

5. Freeze tie-break rules in the R analysis producers so they match the Python exact recomputation.
   Add explicit secondary `arrange()` keys in:
   - `02_compound_statistics.R`
   - `03_ko_statistics.R`
   - `04_enzyme_statistics.R`
   - `05_gene_statistics.R`
   - `06_crosstab_statistics.R`

6. Rename or recompute `duplicate_full_rows`.
   Two valid options:
   - rename it to something like `duplicate_link_signature_rows`
   - compute true full-row duplicates on the final exported schema

### Priority 3

7. Update the documentation to `v1.1.0` and the 11-column schema.
   Files needing revision:
   - `docs/validation-gx/data-contracts.md`
   - `docs/validation-gx/expectation-suites.md`
   - `biorempp_validation/README.md`

8. Clarify in docs that `expect_compound_columns_to_be_unique` is available in the active GE runtime and is not implemented locally in this repository.

9. Rename or document the placeholder data docs output so the behavior matches user expectation.

## Suggested Next Implementation Pass

If you want to harden the validator now, the highest-value patch sequence is:

1. Extend `required_files` and loaders to include the missing pipeline outputs.
2. Add a `workflow_reports_critical` suite for `workflow_summary.json`.
3. Add a `pipeline_validation_reports_critical` suite for `keys_consistency_report.json` and `links_groundtruth_policy_report.json`.
4. Recalibrate fallback drift thresholds.
5. Make the R analysis ranking order deterministic.
6. Update docs to remove the old 8-column / `v1.0.0` contract.

## Audit Evidence

Primary commands executed during this audit:

```powershell
venv\Scripts\python.exe -m pip install -r biorempp_validation\requirements.txt
venv\Scripts\python.exe -m biorempp_validation.run_validation --config biorempp_validation\config\validation.yaml
venv\Scripts\python.exe -m pytest biorempp_validation\tests -q
```

Additional temporary contraprovas performed:

- validation with `strict_exact: false`
- validation against copied results with `workflow_summary.json`, `keys_consistency_report.json`, and `links_groundtruth_policy_report.json` removed

