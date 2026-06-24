<!--
Page status: verified
Audience: operators, maintainers, reviewers
Applies to: GX
Version scope: GX validator v1.1.0
Last verified on: 2026-06-24
Primary sources:
- biorempp_validation/config/validation.yaml
- biorempp_validation/src/biorempp_validation/settings.py
- biorempp_validation/src/biorempp_validation/run_validation.py
- biorempp_validation/src/biorempp_validation/report_builder.py
- biorempp_validation/tests/test_dual_mode_validation.py
- biorempp_validation/docs/validation_modes.md
Observed artifacts:
- biorempp_validation/results/critical_checkpoint_result.json
- biorempp_validation/results/validation_summary.json
-->

# Validation Modes

The GX validator has two explicit mode flags under `validation_modes`, but those flags do not describe the entire validator. They only control the analysis-comparison portions of the runtime.

## The Two Mode Flags

The shipped config enables both:

```yaml
validation_modes:
  internal_consistency: true
  regression_detection: true
```

`settings.py` resolves these flags into a `ValidationModes` object and rejects the legacy `strict_exact` key.

## Internal Consistency

`internal_consistency` compares the current release CSV against the current release analysis and metadata outputs.

When enabled, the validator:

- preflights the current analysis JSON files listed in `required_files`
- builds `analysis_critical`, `analysis_warning`, `analysis_internal_consistency`, and `cross_consistency`
- runs `analysis_json_critical`
- runs `analysis_json_warning`
- runs `cross_consistency_critical`
- runs `analysis_json_internal_consistency_critical`

This mode checks whether the current release artifacts agree with each other.

## Regression Detection

`regression_detection` compares the current release CSV against a frozen baseline snapshot committed under `baselines/`.

When enabled, the validator:

- preflights the baseline files required by `_resolve_regression_baseline_required_files()`
- loads baseline analysis JSON payloads
- loads baseline `metadata/kegg_release.json`
- builds `analysis_regression`
- runs `analysis_json_regression_critical`

This mode checks whether the current release still matches the blessed baseline snapshot.

## What Still Runs When Modes Change

Some validator surfaces are independent of both flags. These suites still run even if one mode or both modes are disabled:

- `database_critical`
- `database_warning`
- `metadata_kegg_critical`
- `pipeline_reports_critical`

That behavior comes from `_build_suite_payloads()` and `_build_checkpoint_validations()`. Disabling both mode flags does not disable the validator entirely.

## Output Tagging

Mode information appears in two places:

- each `suite_results` entry in the checkpoint JSON payloads
- each failed item inside `validation_summary.json`

In the current observed critical checkpoint payload:

- analysis parity suites are tagged `internal_consistency` or `regression_detection`
- `metadata_kegg_critical` is tagged `current_artifacts`
- mode-agnostic suites such as `database_critical` and `pipeline_reports_critical` carry `null` for `validation_mode`

## Failure Isolation

The test suite verifies that the two mode families fail independently:

- `test_regression_failure_is_isolated_from_internal_consistency`
- `test_internal_consistency_failure_does_not_fail_regression`

Those tests modify either the baseline snapshot or the current analysis payloads and confirm that only the expected mode is reported in `validation_summary.json`.

## Preflight Behavior By Mode

Mode selection also changes preflight requirements:

- enabling `internal_consistency` makes the current analysis JSON files required
- enabling `regression_detection` makes the baseline snapshot required

If regression detection is enabled and any required baseline file is missing, the validator writes a preflight failure summary using `expect_regression_baseline_files_to_exist` and returns `1`.

## Related Pages

- [Architecture](architecture.md)
- [Expectation Suites](expectation-suites.md)
- [Baseline Management](baseline-management.md)
- [Testing](testing.md)
