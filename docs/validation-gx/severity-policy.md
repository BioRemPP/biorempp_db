# Severity Policy

The validator uses two Great Expectations checkpoints:

- `critical_gate`: hard failures that can block a release
- `warning_report`: drift and advisory checks

Whether those failures return exit code `1` is controlled by
`policy.fail_on_critical` and `policy.fail_on_warning`.

## Critical Gate

The critical gate is mode-aware. Depending on `validation_modes`, it runs up to
six suites:

| Suite | When it runs | Purpose |
|-------|--------------|---------|
| `database_critical` | Always | Schema, required columns, core null checks, identifier regex, row count >= 1. |
| `analysis_json_critical` | `internal_consistency: true` | Required keys and structural checks on current analysis JSON artifacts. |
| `analysis_json_internal_consistency_critical` | `internal_consistency: true` | Exact recomputation from the current CSV against the current analysis JSON artifacts. |
| `analysis_json_regression_critical` | `regression_detection: true` | Exact recomputation from the current CSV against the committed baseline snapshot. |
| `metadata_kegg_critical` | Always | Validates `metadata/kegg_release.json`. |
| `cross_consistency_critical` | `internal_consistency: true` | Current CSV metrics must match `basic_statistics.json`. |

Any failed suite in this checkpoint is treated as a contract break.

## Warning Gate

The warning gate is lighter and focuses on bounded drift:

| Suite | When it runs | Purpose |
|-------|--------------|---------|
| `database_warning` | Always | Vocabulary checks plus row-count and cardinality drift thresholds. |
| `analysis_json_warning` | `internal_consistency: true` | Soft checks on current analysis JSON content. |

## Validation Modes

### `internal_consistency`

Uses the current run's artifacts only. It answers:

- is the current CSV internally coherent with the current JSON outputs?
- were the analysis JSON files regenerated correctly from the same run?

This mode is exact, but not a cross-run regression guard by itself.

### `regression_detection`

Uses the committed baseline under `paths.regression_baseline_root`. It answers:

- does the current CSV still match the blessed baseline snapshot?
- did a pipeline or upstream data change introduce output drift?

This is the strict regression check.

### Warning drift

`database_warning` uses the ranges in `drift_thresholds`. Those ranges are
intentionally approximate and version-controlled. They are not derived from the
current run.

## Exit Code Logic

The validator returns:

- `1` if a critical check fails and `fail_on_critical: true`
- `1` if a warning check fails and `fail_on_warning: true`
- `0` otherwise

Missing files are handled before Great Expectations runs. The validator writes a
synthetic critical result payload and exits `1`.

## Recommended Default

The shipped configuration is strict and stable:

```yaml
policy:
  fail_on_critical: true
  fail_on_warning: true

validation_modes:
  internal_consistency: true
  regression_detection: true
```

That combination gives you:

- exact same-run consistency checks
- exact cross-run regression checks
- bounded warning drift for scale and vocabulary changes
