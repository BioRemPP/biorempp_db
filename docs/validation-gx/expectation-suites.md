# Expectation Suites

The validator ships Great Expectations JSON templates under
`biorempp_validation/great_expectations/expectations/`. They are not executed
verbatim: `run_validation.py` injects config-driven values at runtime.

## Suite Inventory

| Suite template | Severity | Purpose |
|----------------|----------|---------|
| `database_critical` | Critical | CSV schema, core null checks, regex checks, uniqueness, non-empty table. |
| `database_warning` | Warning | Vocabulary checks and drift thresholds. |
| `analysis_json_critical` | Critical | Required keys and structural checks for current analysis JSON artifacts. |
| `analysis_json_exact_critical` | Critical template | Cloned at runtime for internal consistency and regression detection. |
| `analysis_json_warning` | Warning | Soft checks on current analysis JSON artifacts. |
| `metadata_kegg_critical` | Critical | Current KEGG metadata checks. |
| `cross_consistency_critical` | Critical | Current CSV vs current `basic_statistics.json`. |

## Runtime Expansion

`analysis_json_exact_critical.json` is cloned into mode-specific suites:

- `analysis_json_internal_consistency_critical`
- `analysis_json_regression_critical`

Both suites use the same expectation structure, but they run on different
DataFrames.

## Runtime Overrides

At runtime the validator injects:

- `database_contract.expected_columns` into ordered-column and composite
  uniqueness expectations
- the configured `referenceAG` vocabulary
- the configured `compoundclass` vocabulary
- `drift_thresholds` into `database_warning`
- the expected column count into `analysis_json_critical`

The template JSON files therefore define the shape of the suites, while the
canonical values come from `validation.yaml`.

## `database_warning`

This suite is the bounded-drift layer. After runtime override, it checks:

| Metric | Shipped range |
|--------|---------------|
| Unique compounds | `360-410` |
| Unique KOs | `1440-1650` |
| Unique gene symbols | `1410-1625` |
| Unique gene names | `1320-1525` |
| Unique enzyme activities | `185-230` |
| Total row count | `118000-130000` |

It also checks that the observed distinct values for `referenceAG` and
`compoundclass` stay inside the configured vocabularies.

## Exact-Match Suites

The exact-match template validates boolean columns produced by
`build_analysis_exact_df()`. Those columns cover:

- basic statistics
- column order
- compound summaries and top compounds
- KO summaries and top KOs
- enzyme summaries and top enzymes
- gene summaries and top genes
- cross-tab summaries
- executive summary
- KEGG metadata parity

All boolean columns must be `true`.

## When to Edit a Suite Template

Edit the JSON templates only when the expectation structure changes, for
example:

- a new expectation type is needed
- a dataset gains a new critical boolean field
- a checkpoint should include a different suite

Do not edit template values just to change column lists, vocabularies, or drift
thresholds. Those come from `validation.yaml`.
