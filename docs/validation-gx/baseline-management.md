<!--
Page status: verified
Audience: maintainers, reviewers
Applies to: GX
Version scope: GX validator v1.1.0
Last verified on: 2026-06-24
Primary sources:
- biorempp_validation/config/validation.yaml
- biorempp_validation/src/biorempp_validation/settings.py
- biorempp_validation/src/biorempp_validation/run_validation.py
- biorempp_validation/src/biorempp_validation/loaders.py
- biorempp_validation/tests/test_dual_mode_validation.py
- biorempp_validation/docs/validation_modes.md
- biorempp_validation/README.md
Observed artifacts:
- biorempp_validation/baselines/release_v1_1_0_kegg_118_0plus/analysis/basic_statistics.json
- biorempp_validation/baselines/release_v1_1_0_kegg_118_0plus/metadata/kegg_release.json
-->

# Baseline Management

The GX regression baseline is a committed snapshot under `biorempp_validation/baselines/`. The shipped default baseline root is:

- `baselines/release_v1_1_0_kegg_118_0plus`

## What The Baseline Contains

The current baseline directory contains:

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

This is the exact file family that `run_validation.py` requires for regression detection.

## What The Baseline Excludes

The regression baseline does not include:

- the database CSV
- `metadata/keys_consistency_report.json`
- `metadata/links_groundtruth_policy_report.json`
- `reports/workflow_summary.json`

That exclusion is explicit in `_resolve_regression_baseline_required_files()`.

## How Regression Detection Uses The Baseline

Regression detection does not compare the current release against a frozen baseline database file. Instead, it:

1. loads the current database CSV
2. loads the baseline analysis JSON payloads
3. loads the baseline `metadata/kegg_release.json`
4. builds the `analysis_regression` DataFrame through `build_analysis_exact_df()`
5. runs `analysis_json_regression_critical`

The regression reference is therefore an analysis-and-metadata snapshot, not a full copy of the database export tree.

## Baseline Preflight

If regression detection is enabled, the validator checks that every required baseline file exists before running the checkpoint suite.

When files are missing, `run_validation.py` writes preflight failure outputs and reports:

- suite name `preflight_regression_baseline_files`
- expectation type `expect_regression_baseline_files_to_exist`
- validation mode `regression_detection`

The test `test_missing_regression_baseline_fails_preflight` verifies this behavior.

## Refresh Workflow

The current repository supports this baseline refresh sequence:

1. regenerate the upstream Snakemake release outputs that should become the new reference
2. replace the analysis JSON files and `metadata/kegg_release.json` under the intended baseline root
3. update `paths.regression_baseline_root` if the baseline directory name changes
4. rerun the GX validator and the GX pytest suite
5. commit the baseline refresh together with the pipeline change that justifies it

This flow matches the code contract and the repository guidance in `README.md` and `docs/validation_modes.md`.

## Drift Thresholds Are Separate

The baseline snapshot and the warning drift thresholds are different controls.

- the baseline snapshot supports `analysis_json_regression_critical`
- `drift_thresholds` support `database_warning`

Adjust warning thresholds only when the acceptable warning window itself should change. Replacing the baseline snapshot alone does not update those threshold ranges.

## Related Pages

- [Validation Modes](validation-modes.md)
- [Configuration Reference](configuration.md)
- [Testing](testing.md)
