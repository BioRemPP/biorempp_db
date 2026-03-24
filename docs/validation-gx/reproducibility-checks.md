# Reproducibility Checks

The validation module performs two independent reproducibility verifications
that guarantee the Snakemake analysis pipeline produced correct, internally
consistent results.

---

## Cross-Consistency Validation

**Module:** `consistency_checks.py` → `build_cross_consistency_df()`  
**Suite:** `cross_consistency_critical` (5 expectations)

### Purpose

The CSV database and `basic_statistics.json` are produced by **different
Snakemake rules**.  Cross-consistency validation independently aggregates the
CSV and compares the results against the JSON, ensuring both artifacts agree.

### How It Works

1. `build_cross_consistency_df()` receives the raw CSV DataFrame and the parsed
   `basic_statistics.json` dict.
2. It computes 12 metrics from the CSV using pandas and reads the corresponding
   values from the JSON.
3. The result is a 12-row DataFrame with columns `metric`, `csv_value`, and
   `stats_value`.
4. The GX suite then asserts `csv_value == stats_value` for every row.

### The 12 Metrics

| # | Metric | CSV Computation | JSON Source |
|--:|--------|----------------|-------------|
| 1 | `total_entries` | `len(df)` | `basic_statistics.total_entries` |
| 2 | `total_columns` | `df.shape[1]` | `basic_statistics.total_columns` |
| 3 | `unique_compounds` | `df["cpd"].nunique()` | `basic_statistics.unique_compounds` |
| 4 | `unique_ko_entries` | `df["ko"].nunique()` | `basic_statistics.unique_ko_entries` |
| 5 | `unique_compound_classes` | `df["compoundclass"].nunique()` | `basic_statistics.unique_compound_classes` |
| 6 | `unique_reference_agencies` | `df["referenceAG"].nunique()` | `basic_statistics.unique_reference_agencies` |
| 7 | `unique_gene_symbols` | `df["genesymbol"].nunique()` | `basic_statistics.unique_gene_symbols` |
| 8 | `unique_gene_names` | `df["genename"].nunique()` | `basic_statistics.unique_gene_names` |
| 9 | `unique_enzyme_activities` | `df["enzyme_activity"].nunique()` | `basic_statistics.unique_enzyme_activities` |
| 10 | `max_compoundnames_per_cpd` | `groupby("cpd")["compoundname"].nunique().max()` | expected: **1** |
| 11 | `max_genesymbols_per_ko` | `groupby("ko")["genesymbol"].nunique().max()` | expected: **1** |
| 12 | `max_genenames_per_ko` | `groupby("ko")["genename"].nunique().max()` | expected: **1** |

### Functional Dependency Invariants

Metrics 10–12 do **not** come from the JSON.  Their expected value is
hard-coded to `1`, enforcing three implicit structural rules in the data:

- Each compound ID (`cpd`) maps to **exactly one** compound name.
- Each KO ID (`ko`) maps to **exactly one** gene symbol.
- Each KO ID (`ko`) maps to **exactly one** gene name.

A value greater than 1 indicates conflicting mappings — e.g., the same `cpd`
code assigned to two different compound names.

### GX Expectations

The `cross_consistency_critical` suite contains 5 expectations:

1. Exactly 12 rows.
2. All metric names belong to the known set of 12.
3. `csv_value == stats_value` for every row (`expect_column_pair_values_to_be_equal`).
4. `csv_value ≥ 0`.
5. `stats_value ≥ 0`.

### Failure Interpretation

| Symptom | Likely Cause |
|---------|-------------|
| A metric has `csv_value ≠ stats_value` | The analysis rule produced incorrect statistics, or the CSV was modified after analysis ran. |
| `max_compoundnames_per_cpd > 1` | A compound ID is associated with more than one name in the database — data quality issue in the merge step. |
| Row count ≠ 12 | A column was removed from the schema, causing `_safe_nunique` to return `-1`. |

---

## Exact-Match Regression

**Module:** `json_to_dataframe.py` → `build_analysis_exact_df()`  
**Suite:** `analysis_json_exact_critical` (16 expectations)

### Purpose

Goes beyond cross-consistency: **recomputes every analysis statistic** from the
raw CSV database and verifies bit-for-bit parity with all 9 analysis JSON
payloads.  This is a deterministic reproducibility check — any deviation, even
a single different top-20 ranking, is a critical failure.

### How It Works

1. `build_analysis_exact_df()` receives the raw CSV DataFrame, all 9 analysis
   JSON payloads, the KEGG release metadata, and the expected column list.
2. Private helper functions replicate the Snakemake pipeline's R analysis
   logic in Python:

    | Helper | Recomputes |
    |--------|-----------|
    | `_top_compounds_exact(df, 20)` | Top-20 compounds by frequency |
    | `_top_ko_exact(df, 20)` | Top-20 KOs by frequency |
    | `_top_enzymes_exact(df, 30)` | Top-30 enzyme activities by frequency |
    | `_top_genes_exact(df, 20)` | Top-20 gene symbols and gene names by frequency |
    | `_crosstab_exact(df)` | Class × agency (top-20), enzyme × class (top-20), classes by KO diversity (top-10) |

3. Each helper sorts by **frequency descending, then alphabetical ascending** —
   matching the Snakemake R script's sort order.
4. Dictionary key ordering is enforced with `OrderedDict` for deterministic
   comparison.
5. The result is a single-row DataFrame with 15 boolean columns (+ 1 row-count
   check), each `True` if the recomputed value matches the JSON exactly.

### The 15 Boolean Checks

| # | Column | What Is Compared |
|--:|--------|-----------------|
| 1 | `basic_stats_exact_match` | Full basic-statistics dict (totals, uniques, missing values) |
| 2 | `basic_expected_columns_exact_match` | Column list order and names |
| 3 | `compound_total_exact_match` | Unique compound count |
| 4 | `compound_class_distribution_exact_match` | Compounds-per-class ordered dict |
| 5 | `compound_agency_distribution_exact_match` | Compounds-per-agency ordered dict |
| 6 | `compound_top20_exact_match` | Top-20 compounds (names + frequencies) |
| 7 | `ko_total_exact_match` | Unique KO count |
| 8 | `ko_top20_exact_match` | Top-20 KOs (IDs + frequencies) |
| 9 | `enzyme_total_exact_match` | Unique enzyme activity count |
| 10 | `enzyme_top30_exact_match` | Top-30 enzymes (names + frequencies) |
| 11 | `gene_totals_exact_match` | Unique gene symbol + gene name counts |
| 12 | `gene_top20_exact_match` | Top-20 gene symbols and gene names |
| 13 | `crosstab_exact_match` | All three cross-tabulation sections |
| 14 | `executive_summary_exact_match` | Overview, highlights, and coverage sections |
| 15 | `metadata_kegg_exact_match` | KEGG release metadata in `database_metadata.json` |

All 15 must be `True`.  The GX suite uses
`expect_column_values_to_be_in_set(value_set=[true])` for each column.

### Executive Summary Recomputation

The exact-match check for `executive_summary.json` is particularly thorough.
It recomputes three sections entirely from the CSV:

- **`overview`** — total entries, unique compounds, unique KOs, unique enzyme
  activities, unique compound classes.
- **`highlights`** — most represented class (name + count), most frequent
  enzyme (name + frequency), total classes.
- **`coverage`** — environmental agencies, compound classes covered, enzyme
  types identified, gene symbols mapped.

### Sort Order Convention

All top-N rankings use a two-level sort:

1. **Primary:** frequency (descending)
2. **Secondary:** name/ID alphabetical (ascending)

This ensures deterministic ordering when multiple items share the same
frequency.  The Python helpers replicate this via:

```python
.sort_values(["frequency", "name"], ascending=[False, True])
.head(top_n)
```

### Failure Interpretation

| Symptom | Likely Cause |
|---------|-------------|
| `basic_stats_exact_match: False` | `basic_statistics.json` was not regenerated after a CSV change. |
| `compound_top20_exact_match: False` | Sort order mismatch or the R script uses a different tie-breaking rule. |
| `crosstab_exact_match: False` | A cross-tabulation rule changed without updating the analysis script. |
| `executive_summary_exact_match: False` | Highlights or coverage values are stale. |
| `metadata_kegg_exact_match: False` | `database_metadata.json` references a different KEGG release than `kegg_release.json`. |
| All checks `False` at once | Required columns are missing — the function returns all-False early. |

---

## `strict_exact` Mode

The `strict_exact` setting in `validation.yaml` affects **warning-level drift
checks** (not the reproducibility checks above, which are always critical).

| Mode | Behaviour |
|------|-----------|
| `strict_exact: true` (default) | Drift thresholds are pinned to the actual values from the analysis JSONs (`min == max == observed`). Any cardinality change triggers a warning failure. |
| `strict_exact: false` | The wider `drift_thresholds` ranges from the config are used (e.g., unique compounds: 250–700). Minor fluctuations are tolerated. |

!!! tip "When to use each mode"
    **Release validation** → `strict_exact: true`.  Ensures the database is
    identical to the expected baseline.  
    **Development** → `strict_exact: false`.  Allows iterating with evolving
    KEGG data without warning noise.

---

## Relationship to Pipeline Reproducibility

These checks complement the Snakemake-side reproducibility measures
(Docker images, pinned R packages, seed values) documented in
[Reproducibility](../validation/reproducibility.md).  While the pipeline
focuses on *environment* reproducibility, these GX checks verify *output*
reproducibility — that the artifacts are internally consistent and match
independent recomputation.
