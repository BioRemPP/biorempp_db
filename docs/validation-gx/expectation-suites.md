# Expectation Suites

The validation module uses **7 expectation suites** containing a total of
**71 expectations** — 57 at critical severity and 14 at warning severity.
All suites are defined as JSON files in
`great_expectations/expectations/` and are loaded at runtime.

## Suite Overview

| Suite | Count | Severity | Checkpoint | Validation Target |
|-------|------:|----------|------------|-------------------|
| `database_critical` | 13 | Critical | `critical_gate` | Main CSV database |
| `database_warning` | 8 | Warning | `warning_report` | Main CSV database |
| `analysis_json_critical` | 14 | Critical | `critical_gate` | Analysis JSON payloads |
| `analysis_json_exact_critical` | 16 | Critical | `critical_gate` | Analysis JSON (exact-match regression) |
| `analysis_json_warning` | 6 | Warning | `warning_report` | Analysis JSON payloads |
| `metadata_kegg_critical` | 9 | Critical | `critical_gate` | KEGG metadata |
| `cross_consistency_critical` | 5 | Critical | `critical_gate` | CSV ↔ JSON parity |
| **Total** | **71** | **57C / 14W** | | |

---

## 1. `database_critical` — 13 expectations

Validates the structural integrity and completeness of the main CSV database
(`biorempp_database_v1.0.0.csv`).

| # | Expectation Type | Target | Parameters | What It Checks |
|--:|-----------------|--------|------------|----------------|
| 1 | `expect_table_columns_to_match_ordered_list` | table | 8 columns | Exact column order: `cpd`, `compoundclass`, `ko`, `referenceAG`, `compoundname`, `genesymbol`, `genename`, `enzyme_activity` |
| 2 | `expect_table_row_count_to_be_between` | table | min: 1 | Database is not empty |
| 3 | `expect_compound_columns_to_be_unique` | table | all 8 columns | Composite-key uniqueness across all columns (custom expectation) |
| 4 | `expect_column_values_to_not_be_null` | `cpd` | — | No null values |
| 5 | `expect_column_values_to_not_be_null` | `compoundclass` | — | No null values |
| 6 | `expect_column_values_to_not_be_null` | `ko` | — | No null values |
| 7 | `expect_column_values_to_not_be_null` | `referenceAG` | — | No null values |
| 8 | `expect_column_values_to_not_be_null` | `compoundname` | — | No null values |
| 9 | `expect_column_values_to_not_be_null` | `genesymbol` | — | No null values |
| 10 | `expect_column_values_to_not_be_null` | `genename` | — | No null values |
| 11 | `expect_column_values_to_not_be_null` | `enzyme_activity` | — | No null values |
| 12 | `expect_column_values_to_match_regex` | `cpd` | `^C\d{5}$` | KEGG compound ID format |
| 13 | `expect_column_values_to_match_regex` | `ko` | `^K\d{5}$` | KEGG orthology ID format |

!!! note "Custom expectation"
    `expect_compound_columns_to_be_unique` is a **custom expectation type**
    implemented in the Python source code.  It checks that no two rows share
    the same combination of values across all 8 columns (composite-key
    uniqueness).

---

## 2. `database_warning` — 8 expectations

Validates domain vocabulary conformance and cardinality drift bands for the
main CSV database.

| # | Expectation Type | Target | Parameters | What It Checks |
|--:|-----------------|--------|------------|----------------|
| 1 | `expect_column_distinct_values_to_be_in_set` | `referenceAG` | 9 agencies | All agency codes belong to the known vocabulary |
| 2 | `expect_column_distinct_values_to_be_in_set` | `compoundclass` | 12 classes | All compound classes belong to the known vocabulary |
| 3 | `expect_column_unique_value_count_to_be_between` | `cpd` | 250 – 700 | Unique compound count within drift band |
| 4 | `expect_column_unique_value_count_to_be_between` | `ko` | 900 – 2,500 | Unique KO count within drift band |
| 5 | `expect_column_unique_value_count_to_be_between` | `genesymbol` | 1,000 – 2,200 | Unique gene symbol count within drift band |
| 6 | `expect_column_unique_value_count_to_be_between` | `genename` | 900 – 2,200 | Unique gene name count within drift band |
| 7 | `expect_column_unique_value_count_to_be_between` | `enzyme_activity` | 120 – 400 | Unique enzyme activity count within drift band |
| 8 | `expect_table_row_count_to_be_between` | table | 7,000 – 20,000 | Total row count within drift band |

!!! info "strict_exact mode"
    When `strict_exact: true` (the default), these drift bands are **overridden
    at runtime** with pinned values from the analysis JSON payloads — e.g.,
    `min == max == 384` for unique compounds.  The ranges shown above serve as
    fallback when `strict_exact: false`.

**Known agency vocabulary:**
ATSDR, CONAMA, EPA, EPC, IARC1, IARC2A, IARC2B, PSL, WFD

**Known compound class vocabulary:**
Aliphatic, Aromatic, Chlorinated, Halogenated, Inorganic, Metal,
Nitrogen-containing, Organometallic, Organophosphorus, Organosulfur,
Polyaromatic, Sulfur-containing

---

## 3. `analysis_json_critical` — 14 expectations

Validates the structure and key presence of the 9 analysis JSON files.
The suite operates on a **single-row DataFrame** built by
`build_analysis_critical_df()`.

| # | Expectation Type | Target Column | Parameters | What It Checks |
|--:|-----------------|---------------|------------|----------------|
| 1 | `expect_table_row_count_to_be_between` | table | min: 1, max: 1 | Exactly one summary row |
| 2 | `expect_column_values_to_be_in_set` | `basic_required_keys_present` | `[true]` | `basic_statistics.json` has all required keys |
| 3 | `expect_column_values_to_be_in_set` | `compound_required_keys_present` | `[true]` | `compound_statistics.json` has all required keys |
| 4 | `expect_column_values_to_be_in_set` | `ko_required_keys_present` | `[true]` | `ko_statistics.json` has all required keys |
| 5 | `expect_column_values_to_be_in_set` | `enzyme_required_keys_present` | `[true]` | `enzyme_statistics.json` has all required keys |
| 6 | `expect_column_values_to_be_in_set` | `gene_required_keys_present` | `[true]` | `gene_statistics.json` has all required keys |
| 7 | `expect_column_values_to_be_in_set` | `crosstab_required_keys_present` | `[true]` | `crosstab_statistics.json` has all required keys |
| 8 | `expect_column_values_to_be_in_set` | `metadata_required_keys_present` | `[true]` | `database_metadata.json` has all required keys |
| 9 | `expect_column_values_to_be_in_set` | `executive_required_keys_present` | `[true]` | `executive_summary.json` has all required keys |
| 10 | `expect_column_values_to_be_in_set` | `complete_required_keys_present` | `[true]` | `complete_analysis.json` has all required keys |
| 11 | `expect_column_values_to_be_between` | `basic_total_entries` | min: 1 | At least 1 database entry reported |
| 12 | `expect_column_values_to_be_between` | `basic_total_columns` | min: 8, max: 8 | Exactly 8 columns reported |
| 13 | `expect_column_values_to_be_in_set` | `basic_expected_columns_match` | `[true]` | Column list matches expected schema |
| 14 | `expect_column_values_to_be_in_set` | `basic_all_missing_values_zero` | `[true]` | Zero missing values across all columns |

---

## 4. `analysis_json_exact_critical` — 16 expectations

**Deterministic reproducibility check.**  Recomputes every analysis statistic
from the raw CSV database and verifies bit-for-bit parity with the JSON
payloads.  The suite operates on a single-row DataFrame built by
`build_analysis_exact_df()`, where each column is a boolean indicating whether
the recomputed value matches the JSON.

| # | Expectation Type | Target Column | What It Verifies |
|--:|-----------------|---------------|------------------|
| 1 | `expect_table_row_count_to_be_between` | table (min: 1, max: 1) | Exactly one summary row |
| 2 | `expect_column_values_to_be_in_set` | `basic_stats_exact_match` | Basic statistics (totals, unique counts) |
| 3 | `expect_column_values_to_be_in_set` | `basic_expected_columns_exact_match` | Column list order and names |
| 4 | `expect_column_values_to_be_in_set` | `compound_total_exact_match` | Unique compound count |
| 5 | `expect_column_values_to_be_in_set` | `compound_class_distribution_exact_match` | Compounds-per-class distribution |
| 6 | `expect_column_values_to_be_in_set` | `compound_agency_distribution_exact_match` | Compounds-per-agency distribution |
| 7 | `expect_column_values_to_be_in_set` | `compound_top20_exact_match` | Top-20 compounds by frequency |
| 8 | `expect_column_values_to_be_in_set` | `ko_total_exact_match` | Unique KO count |
| 9 | `expect_column_values_to_be_in_set` | `ko_top20_exact_match` | Top-20 KOs by frequency |
| 10 | `expect_column_values_to_be_in_set` | `enzyme_total_exact_match` | Unique enzyme activity count |
| 11 | `expect_column_values_to_be_in_set` | `enzyme_top30_exact_match` | Top-30 enzymes by frequency |
| 12 | `expect_column_values_to_be_in_set` | `gene_totals_exact_match` | Unique gene symbols + gene names counts |
| 13 | `expect_column_values_to_be_in_set` | `gene_top20_exact_match` | Top-20 gene symbols and gene names |
| 14 | `expect_column_values_to_be_in_set` | `crosstab_exact_match` | Cross-tabulation combinations (class × agency, enzyme × class, KO diversity) |
| 15 | `expect_column_values_to_be_in_set` | `executive_summary_exact_match` | Executive summary content |
| 16 | `expect_column_values_to_be_in_set` | `metadata_kegg_exact_match` | KEGG metadata section |

All boolean columns must equal `true`.  A single `false` means the analysis
pipeline produced a result that does not match the independent recomputation
from the raw CSV — indicating a reproducibility failure.

---

## 5. `analysis_json_warning` — 6 expectations

Soft structural checks on the analysis JSON payloads.
Operates on a single-row DataFrame built by `build_analysis_warning_df()`.

| # | Expectation Type | Target Column | Parameters | What It Checks |
|--:|-----------------|---------------|------------|----------------|
| 1 | `expect_table_row_count_to_be_between` | table | min: 1, max: 1 | Exactly one summary row |
| 2 | `expect_column_values_to_be_between` | `compound_top_n` | min: 1 | At least 1 top compound listed |
| 3 | `expect_column_values_to_be_between` | `ko_top_n` | min: 1 | At least 1 top KO listed |
| 4 | `expect_column_values_to_be_between` | `enzyme_top_n` | min: 1 | At least 1 top enzyme listed |
| 5 | `expect_column_values_to_be_in_set` | `executive_text_fields_non_empty` | `[true]` | Executive summary text fields are non-empty |
| 6 | `expect_column_values_to_be_in_set` | `crosstab_required_sections_present` | `[true]` | Cross-tabulation sections exist |

---

## 6. `metadata_kegg_critical` — 9 expectations

Validates the KEGG release metadata file (`metadata/kegg_release.json`).
Operates on a single-row DataFrame built by `build_kegg_metadata_df()`.

| # | Expectation Type | Target Column | Parameters | What It Checks |
|--:|-----------------|---------------|------------|----------------|
| 1 | `expect_table_row_count_to_be_between` | table | min: 1, max: 1 | Exactly one metadata row |
| 2 | `expect_column_values_to_not_be_null` | `release_text` | — | Release text present |
| 3 | `expect_column_values_to_not_be_null` | `parsed_version` | — | Parsed version present |
| 4 | `expect_column_values_to_not_be_null` | `retrieved_at_utc` | — | Retrieval timestamp present |
| 5 | `expect_column_values_to_not_be_null` | `source_url` | — | Source URL present |
| 6 | `expect_column_values_to_be_in_set` | `source_url` | `["https://rest.kegg.jp/info/kegg"]` | Source must be the official KEGG REST API |
| 7 | `expect_column_values_to_match_regex` | `parsed_version` | `^\d+\.\d+\+?$` | Version format (e.g., `114.0+`) |
| 8 | `expect_column_values_to_match_regex` | `retrieved_at_utc` | `^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$` | ISO 8601 UTC timestamp |
| 9 | `expect_column_values_to_be_between` | `raw_response_len` | min: 1 | KEGG API response is non-empty |

---

## 7. `cross_consistency_critical` — 5 expectations

Validates that statistics independently computed from the CSV database match
the values reported in `basic_statistics.json`.  Operates on a 12-row
DataFrame built by `build_cross_consistency_df()`.

| # | Expectation Type | Target | Parameters | What It Checks |
|--:|-----------------|--------|------------|----------------|
| 1 | `expect_table_row_count_to_be_between` | table | min: 12, max: 12 | Exactly 12 metric rows |
| 2 | `expect_column_values_to_be_in_set` | `metric` | 12 known metric names | All metrics are from the expected set |
| 3 | `expect_column_pair_values_to_be_equal` | `csv_value` ↔ `stats_value` | — | CSV-derived value equals JSON-reported value |
| 4 | `expect_column_values_to_be_between` | `csv_value` | min: 0 | Non-negative |
| 5 | `expect_column_values_to_be_between` | `stats_value` | min: 0 | Non-negative |

**The 12 metrics validated:**

| Metric | CSV Computation | JSON Key |
|--------|----------------|----------|
| `total_entries` | `len(df)` | `basic_statistics.total_entries` |
| `total_columns` | `df.shape[1]` | `basic_statistics.total_columns` |
| `unique_compounds` | `df["cpd"].nunique()` | `basic_statistics.unique_compounds` |
| `unique_ko_entries` | `df["ko"].nunique()` | `basic_statistics.unique_ko_entries` |
| `unique_compound_classes` | `df["compoundclass"].nunique()` | `basic_statistics.unique_compound_classes` |
| `unique_reference_agencies` | `df["referenceAG"].nunique()` | `basic_statistics.unique_reference_agencies` |
| `unique_gene_symbols` | `df["genesymbol"].nunique()` | `basic_statistics.unique_gene_symbols` |
| `unique_gene_names` | `df["genename"].nunique()` | `basic_statistics.unique_gene_names` |
| `unique_enzyme_activities` | `df["enzyme_activity"].nunique()` | `basic_statistics.unique_enzyme_activities` |
| `max_compoundnames_per_cpd` | `groupby("cpd")["compoundname"].nunique().max()` | expected: 1 |
| `max_genesymbols_per_ko` | `groupby("ko")["genesymbol"].nunique().max()` | expected: 1 |
| `max_genenames_per_ko` | `groupby("ko")["genename"].nunique().max()` | expected: 1 |

The last three metrics enforce **functional-dependency invariants**: each
compound ID maps to exactly one compound name, and each KO maps to exactly one
gene symbol and one gene name.

---

## Runtime Suite Override

Expectation-suite JSON files are **not used as-is**.  At runtime, the function
`_apply_config_overrides_to_suite_payloads()` mutates them in-place:

- **Column lists** and **value sets** (agencies, compound classes) are injected
  from `validation.yaml` → `database_contract`.
- **Drift thresholds** are injected from `drift_thresholds` config.
- When **`strict_exact: true`**, drift thresholds are replaced with exact
  observed values from the analysis JSONs (`min == max == actual`), converting
  drift bands into exact-match assertions.

This means the JSON files define the *structure* of each suite, while the
*values* are supplied by configuration at runtime.

---

## How to Modify Suites

**Add an expectation to an existing suite:**

1. Edit the corresponding JSON file in `great_expectations/expectations/`.
2. Add a new object to the `"expectations"` array with `type`, `kwargs`,
   `severity`, and `meta` fields.
3. Run the test suite to verify: `pytest biorempp_validation/tests -q`.

**Add a new suite:**

1. Create a new JSON file in `great_expectations/expectations/`.
2. Register it in the appropriate checkpoint YAML
   (`critical_gate.yml` or `warning_report.yml`).
3. Ensure the `run_validation.py` orchestrator loads the suite and maps it to
   the correct DataFrame dataset.
4. Add corresponding tests.
