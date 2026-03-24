# Data Contracts

Data contracts define the expected shape, content, and semantics of every
artifact the validation module checks.  They are the formal specification
against which the Snakemake pipeline outputs are validated.

---

## Database Schema Contract

The main CSV database (`biorempp_database_v1.0.0.csv`) must conform to the
following schema, defined in `validation.yaml` → `database_contract`:

### Column Schema

| # | Column | Format | Null Allowed | Severity |
|--:|--------|--------|:------------:|----------|
| 1 | `cpd` | `^C\d{5}$` (KEGG compound ID) | No | Critical |
| 2 | `compoundclass` | Free text (vocabulary enforced) | No | Critical |
| 3 | `ko` | `^K\d{5}$` (KEGG orthology ID) | No | Critical |
| 4 | `referenceAG` | Free text (vocabulary enforced) | No | Critical |
| 5 | `compoundname` | Free text | No | Critical |
| 6 | `genesymbol` | Free text | No | Critical |
| 7 | `genename` | Free text | No | Critical |
| 8 | `enzyme_activity` | Free text | No | Critical |

**Enforcement:**

- **Column order** — enforced via `expect_table_columns_to_match_ordered_list`.
  The order shown above is the required order.
- **No nulls** — 8 × `expect_column_values_to_not_be_null` (one per column).
- **Composite uniqueness** — `expect_compound_columns_to_be_unique` across all
  8 columns (custom expectation).  No two rows may share the same combination
  of values.
- **Non-empty** — `expect_table_row_count_to_be_between` with `min_value: 1`.

---

## Identifier Format Contracts

Two columns have strict regex-based format requirements:

| Column | Regex | Example | Severity |
|--------|-------|---------|----------|
| `cpd` | `^C\d{5}$` | `C00022` | Critical |
| `ko` | `^K\d{5}$` | `K00001` | Critical |

Every value in these columns must match the corresponding KEGG identifier
pattern.  Invalid identifiers (e.g., `C0022`, `K1234567`, or empty strings)
cause an immediate critical failure.

---

## Domain Vocabulary Contracts

Two columns have closed vocabularies enforced at **warning** severity:

### Reference Agencies (9 values)

| Code | Full Name |
|------|-----------|
| `ATSDR` | Agency for Toxic Substances and Disease Registry |
| `CONAMA` | Conselho Nacional do Meio Ambiente |
| `EPA` | United States Environmental Protection Agency |
| `EPC` | Environment and Climate Change Canada |
| `IARC1` | IARC Group 1 — Carcinogenic to humans |
| `IARC2A` | IARC Group 2A — Probably carcinogenic |
| `IARC2B` | IARC Group 2B — Possibly carcinogenic |
| `PSL` | Priority Substances List (Canada) |
| `WFD` | Water Framework Directive (EU) |

Enforced via `expect_column_distinct_values_to_be_in_set` on the `referenceAG`
column.

### Compound Classes (12 values)

| Class |
|-------|
| Aliphatic |
| Aromatic |
| Chlorinated |
| Halogenated |
| Inorganic |
| Metal |
| Nitrogen-containing |
| Organometallic |
| Organophosphorus |
| Organosulfur |
| Polyaromatic |
| Sulfur-containing |

Enforced via `expect_column_distinct_values_to_be_in_set` on the
`compoundclass` column.

!!! info "Warning-level enforcement"
    Domain vocabulary checks are **warning-level**, not critical.  A new agency
    or compound class appearing in the data will not block the pipeline when
    `fail_on_warning: false` — but it will be flagged in the validation
    summary for review.

---

## KEGG Metadata Contract

The file `metadata/kegg_release.json` must contain a single object with the
following fields:

| Field | Constraint | Severity | Example (v1.0.0) |
|-------|-----------|----------|-------------------|
| `release_text` | Not null | Critical | `"kegg  Release 117.0+/02-18, Feb 26"` |
| `parsed_version` | Regex: `^\d+\.\d+\+?$` | Critical | `"117.0+"` |
| `retrieved_at_utc` | Regex: `^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$` | Critical | `"2026-02-17T22:19:58Z"` |
| `source_url` | Must equal `https://rest.kegg.jp/info/kegg` | Critical | `"https://rest.kegg.jp/info/kegg"` |
| `raw_response` | Length ≥ 1 (`raw_response_len`) | Critical | array of 19 strings |

The metadata is validated as a single-row DataFrame built by
`build_kegg_metadata_df()`.  The `raw_response_len` field is derived from
`len(raw_response)` during DataFrame construction.

!!! warning "Locked source URL"
    The KEGG source URL is hard-coded to `https://rest.kegg.jp/info/kegg`.
    If the KEGG API endpoint ever changes, the expectation suite
    (`metadata_kegg_critical.json`) must be updated.

---

## Analysis JSON Contract

### Required Files

The validation preflight checks for the existence of **11 required files**
under the Snakemake results directory:

| # | Relative Path | Type |
|--:|---------------|------|
| 1 | `database/biorempp_database_v1.0.0.csv` | CSV |
| 2 | `analysis/basic_statistics.json` | JSON |
| 3 | `analysis/compound_statistics.json` | JSON |
| 4 | `analysis/ko_statistics.json` | JSON |
| 5 | `analysis/enzyme_statistics.json` | JSON |
| 6 | `analysis/gene_statistics.json` | JSON |
| 7 | `analysis/crosstab_statistics.json` | JSON |
| 8 | `analysis/database_metadata.json` | JSON |
| 9 | `analysis/executive_summary.json` | JSON |
| 10 | `analysis/complete_analysis.json` | JSON |
| 11 | `metadata/kegg_release.json` | JSON |

If **any** file is missing, the module exits immediately with code `1` and
writes a synthetic critical-failure payload — GX never runs.

### Structural Contract

Each of the 9 analysis JSON files must contain its **required keys**.  This is
validated by the `analysis_json_critical` suite, which checks boolean columns
like `basic_required_keys_present`, `compound_required_keys_present`, etc.

Additionally:

- `basic_statistics.json` must report `total_entries` ≥ 1
- `basic_statistics.json` must report `total_columns` = 8
- The column list must match the expected schema
- All `missing_values` must be zero

### Exact-Match Contract

The `analysis_json_exact_critical` suite goes further: it **recomputes** every
statistic from the raw CSV and verifies bit-for-bit parity with the JSON
payloads.  This covers basic stats, compound/KO/enzyme/gene distributions,
top-N rankings, cross-tabulations, and executive summary text. See
[Reproducibility Checks](reproducibility-checks.md) for details.

---

## Functional Dependency Invariants

Three implicit contracts enforce **1:1 mappings** in the data:

| Invariant | Meaning | Expected Value |
|-----------|---------|:--------------:|
| `max_compoundnames_per_cpd` | Each compound ID maps to exactly one name | 1 |
| `max_genesymbols_per_ko` | Each KO maps to exactly one gene symbol | 1 |
| `max_genenames_per_ko` | Each KO maps to exactly one gene name | 1 |

These are checked by the `cross_consistency_critical` suite.  A value &gt; 1
means the data contains conflicting mappings — e.g., the same `cpd` code
associated with two different compound names.

---

## How to Update Contracts

### Adding a new reference agency

1. Add the agency code to `validation.yaml` →
   `database_contract.expected_reference_agencies`.
2. The runtime override mechanism injects the updated list into the
   `database_warning` suite automatically — no JSON edit needed.
3. Run validation to confirm: `biorempp-validate --config biorempp_validation/config/validation.yaml`.

### Adding a new compound class

1. Add the class name to `validation.yaml` →
   `database_contract.expected_compound_classes`.
2. Same automatic injection applies.

### Changing the column schema

1. Update `validation.yaml` → `database_contract.expected_columns` (order
   matters).
2. Update the `database_critical.json` suite:
    - Update `expect_table_columns_to_match_ordered_list` → `column_list`.
    - Add or remove `expect_column_values_to_not_be_null` entries.
    - Update `expect_compound_columns_to_be_unique` → `column_list`.
3. Update `analysis_json_critical.json` → `basic_total_columns` bounds.
4. Run tests: `pytest biorempp_validation/tests -q`.

### Updating drift thresholds

1. Edit `validation.yaml` → `drift_thresholds` with new `min`/`max` ranges.
2. Only effective when `strict_exact: false`.
3. When `strict_exact: true`, thresholds are derived from analysis JSONs at
   runtime.
