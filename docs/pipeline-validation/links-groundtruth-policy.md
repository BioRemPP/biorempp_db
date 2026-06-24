<!--
Page status: verified
Audience: operators, maintainers, reviewers
Applies to: Snakemake
Version scope: Snakemake output contract v1.1.0
Last verified on: 2026-06-24
Primary sources:
- biorempp_snakemake_version/workflow/rules/30_validation.smk
- biorempp_snakemake_version/workflow/scripts/validation/02_validate_links_groundtruth_policy_api.py
- biorempp_snakemake_version/workflow/scripts/validation/kegg_api_client.py
- biorempp_snakemake_version/workflow/scripts/validation/common_normalization.py
Observed artifacts:
- biorempp_snakemake_version/results/metadata/links_groundtruth_policy_report.json
Known gaps:
- the generated report currently records `kegg_api.cache_source` as `work/kegg_link_cache/`, but the rule outputs and observed cache files are under `cache/kegg_link_cache/`
-->

# Links Groundtruth Policy Report

`links_groundtruth_policy_report.json` evaluates populated KEGG-linked rows in the exported database against the cached KEGG relations and summarizes the result through pair-level diagnostics plus policy-aware metrics.

## What The Report Evaluates

This report focuses on rows where both of these fields are present:

- `ec`
- `reaction`

It reads the same core inputs as the keys consistency report:

- the exported database CSV
- the five KEGG cache files
- the configured CSV delimiter
- `validation.max_invalid_line_ratio`

It also accepts `--max-examples`, which defaults to `200`.

## Report Structure

The current top-level JSON keys are:

| Key | Meaning |
|---|---|
| `generated_at_utc` | report generation timestamp |
| `input` | recorded database path, delimiter, and config path |
| `kegg_api` | recorded cache source string plus per-relation cache paths |
| `api_parse_stats` | parsing statistics for each cached relation |
| `validation_policy` | current report mode and the exact policy definitions used by the script |
| `pair_level_validation` | relation-by-relation validation summaries |
| `policy_aware_metrics` | aggregate support metrics for dense rows |

The current `validation_policy` block explicitly sets:

- `mode: report_only`
- `strict5_definition: ko_ec + ko_reaction + cpd_ec + cpd_reaction + ec_reaction`
- `policy_union_definition: ko_complete_like OR ko_fallback_like OR compound_bridge_like`

## Pair-Level Validation

The report evaluates five relations:

- `ko_ec`
- `ko_reaction`
- `cpd_ec`
- `cpd_reaction`
- `ec_reaction`

Each relation block exposes the same fields:

- `applicable_rows`
- `matched_rows`
- `mismatched_rows`
- `match_rate_percent`
- `distinct_pairs_in_db`
- `distinct_pairs_present_in_api`
- `distinct_pairs_missing_in_api`
- `missing_pair_examples`
- `mismatched_row_examples`

These metrics are relation-specific diagnostics. They are intentionally stricter than the broader policy union used later in the same report.

## Policy-Aware Metrics

`policy_aware_metrics` summarizes dense rows using the exact logic implemented in `02_validate_links_groundtruth_policy_api.py`.

| Metric | Meaning |
|---|---|
| `dense_total` | rows where both `ec` and `reaction` are present |
| `strict5` | dense rows that satisfy all five relation checks |
| `ko_complete_like` | rows with `ko_ec`, `ko_reaction`, and `ec_reaction` support |
| `ko_fallback_like` | rows with `ko_ec` and `ko_reaction` support but without `ec_reaction` support |
| `compound_bridge_like` | rows with `cpd_ec` and `cpd_reaction` support plus at least one KO-side support |
| `policy_union` | rows supported by any of `ko_complete_like`, `ko_fallback_like`, or `compound_bridge_like` |
| `no_policy_support` | dense rows outside the policy union |
| `strict5_rate_percent` | `strict5 / dense_total * 100` |
| `policy_union_rate_percent` | `policy_union / dense_total * 100` |
| `policy_mismatch_patterns` | grouped combinations of failed checks for unsupported dense rows |
| `policy_mismatch_examples` | sample unsupported rows |

## How To Interpret Pair Mismatches

Low pair-level match rates do not automatically mean low policy support.

That distinction is visible in the observed artifact verified on `2026-06-24` at `biorempp_snakemake_version/results/metadata/links_groundtruth_policy_report.json`:

- `strict5_rate_percent` is `2.419622691643417`
- `policy_union_rate_percent` is `100.0`
- `no_policy_support` is `0`

This happens because the report distinguishes:

- strict agreement with all five relations
- broader support under the current policy union

Use the pair-level blocks for diagnosis and the policy-aware metrics for release-level interpretation.

## Failure Behavior

This report is currently informational. `mode` is explicitly `report_only`, and the script writes mismatch evidence into JSON instead of converting those findings into a workflow failure.

As with the keys consistency report, the rule can still fail when:

- cache files are missing
- required database columns are missing
- cached payloads cannot be parsed within the allowed invalid-line threshold

## Related Pages

- [Overview](overview.md)
- [KEGG Link Cache](kegg-link-cache.md)
- [Keys Consistency Report](keys-consistency.md)
