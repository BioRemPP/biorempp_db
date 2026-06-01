# Reproducibility Checks

The validator now uses three complementary reproducibility layers:

- cross-consistency between the current CSV and current `basic_statistics.json`
- exact internal consistency between the current CSV and the current analysis
  JSON artifacts
- exact regression detection between the current CSV and the committed baseline

## 1. Cross-Consistency Validation

**Module:** `consistency_checks.py`  
**Suite:** `cross_consistency_critical`

This check compares metrics independently computed from the current CSV against
the values reported in the current `basic_statistics.json`.

It verifies metrics such as:

- total entries
- total columns
- unique compounds
- unique KOs
- unique gene symbols
- unique gene names
- unique enzyme activities
- 1:1 mapping invariants for compound names and KO gene annotations

This catches stale or partially regenerated analysis outputs inside the same
run.

## 2. Exact Internal Consistency

**Module:** `json_to_dataframe.py`  
**Suite:** `analysis_json_internal_consistency_critical`

`build_analysis_exact_df()` recomputes the analysis views directly from the
current CSV and checks exact equality against the current analysis JSON
artifacts.

The exact-match assertions include:

- basic statistics
- expected column order
- compound totals and top-20 ranking
- KO totals and top-20 ranking
- enzyme totals and top-30 ranking
- gene totals and top-20 ranking
- cross-tabulation summaries
- executive summary
- KEGG metadata embedded in analysis outputs

This is a same-run correctness check. If the CSV and JSON were both produced by
the same broken logic, this layer alone is not enough to detect drift.

## 3. Exact Regression Detection

**Module:** `json_to_dataframe.py`  
**Suite:** `analysis_json_regression_critical`

The same `build_analysis_exact_df()` logic is reused, but the expected values
come from the committed baseline snapshot declared by
`paths.regression_baseline_root`.

This turns exact-match validation into a real cross-run regression guard:

- the observed data source is always the current CSV
- the expected analysis payloads come from the blessed baseline
- the expected KEGG metadata comes from the blessed baseline

If the current pipeline output drifts from the baseline, this suite fails
critically even when the current run is internally self-consistent.

## Warning-Level Drift

Drift tolerance is handled separately by `database_warning`. It uses the
version-controlled ranges in `drift_thresholds`:

| Metric | Current shipped range |
|--------|-----------------------|
| Row count | `118000-130000` |
| Unique compounds | `360-410` |
| Unique KOs | `1440-1650` |
| Unique gene symbols | `1410-1625` |
| Unique gene names | `1320-1525` |
| Unique enzyme activities | `185-230` |

These checks are intentionally approximate. They complement the exact critical
checks by flagging scale changes and vocabulary drift without redefining the
baseline automatically.

## Failure Interpretation

| Failure | Likely meaning |
|---------|----------------|
| `cross_consistency_critical` only | Current CSV and current `basic_statistics.json` are out of sync. |
| `analysis_json_internal_consistency_critical` only | Current analysis JSON artifacts do not exactly match recomputation from the current CSV. |
| `analysis_json_regression_critical` only | Current CSV output drifted from the blessed baseline. |
| `database_warning` only | Cardinality or vocabulary moved outside the configured drift bands. |

## Recommended Operating Model

Keep both validation modes enabled by default:

```yaml
validation_modes:
  internal_consistency: true
  regression_detection: true
```

That gives you:

- exact same-run artifact verification
- exact cross-run regression detection
- bounded warning drift around the current release scale
