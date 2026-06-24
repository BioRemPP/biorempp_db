<!--
Page status: verified
Audience: operators, maintainers
Applies to: Snakemake and GX
Version scope: Snakemake output contract v1.1.0 and GX validator v1.1.0
Last verified on: 2026-06-24
Primary sources:
- biorempp_snakemake_version/scripts/run_snakemake.sh
- biorempp_snakemake_version/scripts/run_snakemake.bat
- biorempp_snakemake_version/workflow/scripts/generation/00_check_inputs.R
- biorempp_snakemake_version/workflow/scripts/generation/03_fetch_kegg_data.R
- biorempp_snakemake_version/workflow/rules/30_validation.smk
- biorempp_validation/config/validation.yaml
- biorempp_validation/README.md
- biorempp_validation/results/validation_summary.json
- biorempp_snakemake_version/logs directory listing
-->

# Troubleshooting

This page focuses on operational failures after the project has already been set up. For initial environment preparation, use the Getting Started section first.

## First Places To Inspect

When a run fails, start with these locations:

- `biorempp_snakemake_version/logs/`
- `biorempp_snakemake_version/results/metadata/`
- `biorempp_validation/results/validation_summary.json`

The workflow is already split into per-rule logs, so most failures can be localized quickly.

## Common Failure Patterns

| Symptom | First file to inspect | Typical cause |
|---|---|---|
| pipeline stops before generation starts | `logs/preflight_check_inputs.log` | missing input directory or missing required curated files |
| local curated bundle is not produced | `logs/load_local_data.log` | malformed local input file, unexpected columns, or unreadable workbook/text file |
| KEGG fetch stage fails | `logs/fetch_kegg_info.log` or `logs/fetch_kegg_data.log` | network failure, timeout, or KEGG endpoint issue |
| integrated validation fails | `logs/validate_keys_consistency.log` or `logs/validate_links_groundtruth_policy.log` | malformed CSV, cache issue, or unexpected link-policy inconsistency |
| final report is missing | `logs/build_run_report.log` | one or more upstream artifacts required by `build_run_report` is missing |
| GX validator exits with status `1` | `biorempp_validation/results/validation_summary.json` | critical failure, or warning failure because `fail_on_warning: true` |

## Log Map By Stage

| Stage | Main logs |
|---|---|
| Preflight | `preflight_check_inputs.log` |
| Local input loading | `load_local_data.log` |
| KEGG retrieval | `fetch_kegg_info.log`, `fetch_kegg_data.log`, `fetch_kegg_link_cache.log` |
| Generation and enrichment | `merge_relationships.log`, `add_classifications.log`, `enrich_gene_info.log`, `extract_enzymes_export.log` |
| Analysis | `analysis_basic_statistics.log`, `analysis_compound_statistics.log`, `analysis_ko_statistics.log`, `analysis_enzyme_statistics.log`, `analysis_gene_statistics.log`, `analysis_crosstab_statistics.log`, `analysis_database_metadata.log`, `analysis_executive_summary.log`, `analysis_complete_analysis.log` |
| Integrated validation | `validate_keys_consistency.log`, `validate_links_groundtruth_policy.log` |
| Final reporting | `build_run_report.log` |

## When Preflight Fails

If the run fails before `load_local_data`, verify:

- `input_data/` exists at the repository root
- every required filename matches the active contract exactly
- no file was moved into `biorempp_snakemake_version/` by mistake

The workflow does not use fuzzy matching or fallback discovery for renamed inputs.

## When KEGG Requests Are Unstable

The KEGG fetch script `03_fetch_kegg_data.R` uses retry and backoff logic. The active implementation reads these optional environment variables:

- `BIOREMPP_API_MAX_RETRIES`
- `BIOREMPP_API_TIMEOUT_SECONDS`
- `BIOREMPP_API_BACKOFF_BASE_SECONDS`
- `BIOREMPP_API_BACKOFF_MAX_SECONDS`
- `BIOREMPP_API_BACKOFF_JITTER_RATIO`

If KEGG failures are transient, inspect `fetch_kegg_data.log` before changing the workflow or the input files.

## When Integrated Validation Flags NA-Related Issues

Do not interpret `NA` values in `ec` or `reaction` directly from the CSV without context.

Instead inspect:

- `results/metadata/keys_consistency_report.json`
- `results/metadata/links_groundtruth_policy_report.json`

These reports explain whether residual sparse rows remain justified under the active KEGG-based policy.

## When GX Validation Fails

The standalone validator is configured with:

- `fail_on_critical: true`
- `fail_on_warning: true`
- `validation_modes.internal_consistency: true`
- `validation_modes.regression_detection: true`

That means a validator exit status of `1` may come from:

- a blocking schema or artifact consistency failure
- a regression against the committed baseline
- a warning-level failure, because warnings are currently configured to block

Start with `biorempp_validation/results/validation_summary.json`, then inspect the checkpoint result files if needed.

## When Outputs Look Incomplete

If a run generated some artifacts but not the full release set, compare the missing file against the `all` rule in `Snakefile`. The final pipeline contract includes:

- database exports
- nine analysis JSON files
- `kegg_release.json`
- `keys_consistency_report.json`
- `links_groundtruth_policy_report.json`
- `workflow_summary.json`

If one of these is absent, the corresponding upstream rule or dependency chain is the right place to investigate.

## Related Pages

- [Input Data Contract](input-data.md)
- [Running The Snakemake Pipeline](run-snakemake.md)
- [Understanding Outputs](understanding-output.md)
