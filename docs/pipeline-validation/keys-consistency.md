<!--
Page status: verified
Audience: operators, maintainers, reviewers
Applies to: Snakemake
Version scope: Snakemake output contract v1.1.0
Last verified on: 2026-06-24
Primary sources:
- biorempp_snakemake_version/workflow/rules/30_validation.smk
- biorempp_snakemake_version/workflow/scripts/validation/01_validate_keys_consistency_api.py
- biorempp_snakemake_version/workflow/scripts/validation/kegg_api_client.py
- biorempp_snakemake_version/workflow/scripts/validation/common_normalization.py
Observed artifacts:
- biorempp_snakemake_version/results/metadata/keys_consistency_report.json
Known gaps:
- the generated report currently records `kegg_api.cache_source` as `work/kegg_link_cache/`, but the rule outputs and observed cache files are under `cache/kegg_link_cache/`
-->

# Keys Consistency Report

`keys_consistency_report.json` explains whether the remaining missing values in `ec` and `reaction` are still justified after the final database has been exported.

## What The Report Evaluates

The script only inspects rows where at least one of these fields is missing:

- `ec`
- `reaction`

Rows where both fields are already present are skipped by this report.

The current rule invocation uses:

- the exported database CSV
- the five KEGG cache files
- the configured CSV delimiter
- `validation.max_invalid_line_ratio`

## Report Structure

The current top-level JSON keys are:

| Key | Meaning |
|---|---|
| `generated_at_utc` | report generation timestamp |
| `input` | recorded database path, delimiter, and config path |
| `kegg_api` | recorded cache source string plus per-relation cache paths |
| `api_parse_stats` | parsing statistics for each cached relation |
| `validation_policy` | human-readable rule definitions for incorrect missing-value cases |
| `results` | row totals, classification counts, reason counts, boolean summary, and example rows |

Inside `results`, the current schema is:

- `totals`
- `classification_counts`
- `reason_counts`
- `all_remaining_na_justified`
- `incorrect_examples_limited`

## Classification Model

The script classifies every eligible row as either:

- `justified`
- `incorrect`

`all_remaining_na_justified` is `true` only when the report found zero `incorrect` rows. It does not mean the database has no missing `ec` or `reaction` values. It means the remaining missing values were not judged fillable by the current KEGG-linked rules.

## Reason Codes

The report uses exact reason strings from `01_validate_keys_consistency_api.py`.

### When `ec` is missing and `reaction` is present

- `ec_fillable_from_reaction_bridge_and_pair_sources`
  - classified as `incorrect`
- `reaction_not_supported_by_pair_sources`
- `reaction_has_no_ec_mapping_in_ec_reaction`
- `pair_has_no_ec_sources`
- `no_intersection_reaction_ec_with_pair_ec_sources`

### When `reaction` is missing and `ec` is present

- `reaction_fillable_from_ec_bridge_and_pair_sources`
  - classified as `incorrect`
- `ec_not_supported_by_pair_sources`
- `ec_has_no_reaction_mapping_in_ec_reaction`
- `pair_has_no_reaction_sources`
- `no_intersection_ec_reaction_with_pair_reaction_sources`

### When both `ec` and `reaction` are missing

- `both_fillable_by_ko_ec_and_ko_reaction`
  - classified as `incorrect`
- `both_fillable_by_reaction_ec_bridge_and_pair_sources`
  - classified as `incorrect`
- `pair_has_no_ec_or_reaction_sources`
- `pair_has_no_ec_sources`
- `pair_has_no_reaction_sources`
- `pair_sources_exist_but_no_bridge`

These codes are diagnostic contract values. They should be treated as literal identifiers, not paraphrased labels.

## Parse Statistics

Each relation in `api_parse_stats` reports:

- `total_lines`
- `parsed_pairs`
- `swapped_orientation_lines`
- `invalid_lines`
- `invalid_ratio`

These values describe cache parsing quality. They do not describe biological correctness of database rows.

## Observed Current Artifact

In the observed artifact verified on `2026-06-24` at `biorempp_snakemake_version/results/metadata/keys_consistency_report.json`:

- `rows_with_any_na_in_ec_or_reaction` is `3111`
- `classification_counts.incorrect` is `0`
- `all_remaining_na_justified` is `true`

Those values are run-specific observations, not timeless guarantees.

## Failure Behavior

The script can fail the rule if cache parsing or file-level inputs are invalid. It does not currently exit with failure just because `incorrect` rows were found. The mismatch evidence is written into the report instead.

## Related Pages

- [Overview](overview.md)
- [KEGG Link Cache](kegg-link-cache.md)
- [Links Groundtruth Policy Report](links-groundtruth-policy.md)
