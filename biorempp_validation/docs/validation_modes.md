# Validation Modes

`biorempp_validation` now has two independent validation responsibilities:

- `internal_consistency`: compare the current CSV with the current run's analysis JSON artifacts and current `metadata/kegg_release.json`.
- `regression_detection`: compare the current CSV with the blessed baseline snapshot committed under `baselines/`.

## Default Config

The shipped `config/validation.yaml` enables both modes:

```yaml
validation_modes:
  internal_consistency: true
  regression_detection: true
```

`strict_exact` is deprecated and exists only as a migration alias when `validation_modes` is absent:

- `strict_exact: true` -> enable both modes
- `strict_exact: false` -> disable only `regression_detection`

## Baseline Contract

The default regression baseline is:

`baselines/release_v1_1_0_kegg_118_0plus`

It must contain:

- `analysis/basic_statistics.json`
- `analysis/compound_statistics.json`
- `analysis/ko_statistics.json`
- `analysis/enzyme_statistics.json`
- `analysis/gene_statistics.json`
- `analysis/crosstab_statistics.json`
- `analysis/database_metadata.json`
- `analysis/executive_summary.json`
- `analysis/complete_analysis.json`
- `metadata/kegg_release.json`

If `regression_detection` is enabled and any of these files is missing, validation fails during preflight with a critical result.

## Baseline Refresh

Refresh the baseline only when the pipeline change is intentional and reviewed.

Recommended flow:

1. Generate the upstream Snakemake release outputs.
2. Confirm that validation drift is expected.
3. Replace the files under `baselines/<baseline_id>/`.
4. Adjust warning thresholds only if the acceptable drift window itself changed.
5. Commit the baseline refresh with the pipeline change that justified it.
