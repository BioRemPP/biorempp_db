<!--
Page status: verified
Audience: operators, maintainers, reviewers
Applies to: Snakemake
Version scope: Snakemake output contract v1.1.0
Last verified on: 2026-06-24
Primary sources:
- biorempp_snakemake_version/workflow/rules/30_validation.smk
- biorempp_snakemake_version/workflow/scripts/validation/cache_kegg_links.py
- biorempp_snakemake_version/workflow/scripts/validation/01_validate_keys_consistency_api.py
- biorempp_snakemake_version/workflow/scripts/validation/02_validate_links_groundtruth_policy_api.py
- biorempp_snakemake_version/workflow/scripts/reporting/build_run_report.py
- biorempp_snakemake_version/config/config.yaml
Observed artifacts:
- biorempp_snakemake_version/results/metadata/keys_consistency_report.json
- biorempp_snakemake_version/results/metadata/links_groundtruth_policy_report.json
-->

# Overview

This section documents the validation that runs inside the Snakemake workflow itself. It covers the `30_validation.smk` module and the artifacts it produces under `results/metadata/`.

## What This Validation Layer Does

The integrated validation layer contains three rules:

| Rule | Main outputs | Role |
|---|---|---|
| `fetch_kegg_link_cache` | `cache/kegg_link_cache/*.tsv` | fetch the KEGG link payloads reused by the validation reports |
| `validate_keys_consistency` | `results/metadata/keys_consistency_report.json` | explain whether remaining `NA` values in `ec` and `reaction` are justified under the current KEGG-linked logic |
| `validate_links_groundtruth_policy` | `results/metadata/links_groundtruth_policy_report.json` | compare populated rows against five KEGG relations and summarize policy-aware support |

These artifacts are part of the pipeline release contract and are later consumed by `build_run_report`.

## Boundary With GX Validation

This validation layer is not the standalone GX validator.

The Snakemake-integrated layer:

- runs inside the workflow DAG
- reads the exported database CSV plus the KEGG link cache
- writes report-oriented JSON artifacts to `results/metadata/`

The GX validator is a separate project under `biorempp_validation/` and performs expectation-based checks plus regression detection against a stored baseline.

## Runtime Position In The DAG

The two JSON report rules depend on:

- `results/database/biorempp_database_v1.1.0.csv`
- the five cache files under `cache/kegg_link_cache/`
- `outputs.database_csv_delimiter`
- `validation.max_invalid_line_ratio`

`fetch_kegg_link_cache` itself does not depend on the database export, so Snakemake may create the cache before the release CSV exists.

## Failure Semantics

The current implementation is report-oriented.

The validation rules can fail when:

- cache fetching fails after the configured retry logic
- cached payloads cannot be parsed into valid pairs
- invalid-line ratios exceed `validation.max_invalid_line_ratio`
- required input files or columns are missing

The current scripts do not turn row-level mismatch findings into a Snakemake failure condition. They write diagnostic JSON reports instead.

## Why This Layer Exists

This layer gives the pipeline its own KEGG-linked interpretation artifacts before GX runs. In practice, that means:

- remaining nullable `ec` and `reaction` values are explained by `keys_consistency_report.json`
- dense KEGG-linked rows are profiled by `links_groundtruth_policy_report.json`
- the final workflow summary can include validation context without re-running these checks

## Related Pages

- [KEGG Link Cache](kegg-link-cache.md)
- [Keys Consistency Report](keys-consistency.md)
- [Links Groundtruth Policy Report](links-groundtruth-policy.md)
- [Understanding Outputs](../user-guide/understanding-output.md)
