# QC Rules

This document describes the quality control rules, input validation gates, and data contracts enforced by the BioRemPP pipeline.

---

## Overview

The BioRemPP pipeline enforces data quality at three levels:

1. **Preflight validation** — Verifies all required inputs exist before processing starts
2. **Shared contracts** — Constants in `io_contracts.R` define required files, expected columns, and KEGG endpoint specifications
3. **In-script validations** — Each generation script validates and normalizes data during transformation

---

## Preflight Validation

### Rule: `preflight_check_inputs`

**Script:** `workflow/scripts/generation/00_check_inputs.R`

**Purpose:** Acts as a gate that blocks all downstream rules until all required inputs are verified.

**Required files checked:**

| # | File | Category |
|---|------|----------|
| 1 | `kegglistcompounds.xlsx` | KEGG Reference |
| 2 | `compostos_todasagencias.xlsx` | Regulatory Data |
| 3 | `missing_compounds_founds_curated.xlsx` | Expert Curation |
| 4 | `confirm_class_CURATED.xlsx` | Expert Curation |
| 5 | `kegglistko.txt` | KEGG Reference |
| 6 | `enzymes_unique.txt` | Enzyme Lexicon |

**Behavior:**

- Iterates over `REQUIRED_INPUT_FILES` from `io_contracts.R`
- Checks `file.exists()` for each path in the configured `input_dir`
- Writes `work/preflight_ok.json` with a validation summary (file paths, existence status, timestamp)
- **Fails the pipeline** if any file is missing — no partial execution is allowed

**Output format (`preflight_ok.json`):**

```json
{
  "status": "ok",
  "input_dir": "/workspace/input_data",
  "present_files": [
    "kegglistcompounds.xlsx",
    "compostos_todasagencias.xlsx",
    "missing_compounds_founds_curated.xlsx",
    "confirm_class_CURATED.xlsx",
    "kegglistko.txt",
    "enzymes_unique.txt"
  ],
  "checked_at_utc": "2026-02-17T22:19:56Z"
}
```

---

## Shared Data Contracts (`io_contracts.R`)

The file `workflow/lib/io_contracts.R` defines three constants that act as contracts across the pipeline:

### `REQUIRED_INPUT_FILES`

A character vector listing the 6 mandatory input filenames. Used by:

- `00_check_inputs.R` — Validates existence
- `01_load_local_data.R` — Loads these specific files

### `EXPECTED_DATABASE_COLUMNS`

A character vector defining the 8 columns of the final database schema:

```r
EXPECTED_DATABASE_COLUMNS <- c(
  "cpd", "compoundclass", "ko", "referenceAG",
  "compoundname", "genesymbol", "genename", "enzyme_activity"
)
```

Used by `07_extract_enzymes_export.R` to select and order final columns, ensuring the output schema matches the documented specification.

### `KEGG_ENDPOINTS`

A structured list specifying the 5 KEGG REST API endpoints:

- URL path (appended to `kegg.base_url`)
- Expected column names for the tab-separated response
- Field separator

Used by `03_fetch_kegg_data.R` to construct API requests and parse responses consistently.

---

## Identifier Validation Rules

### KEGG Compound ID (`cpd`)

**Format:** `C#####` (letter C followed by exactly 5 digits)

**Regex:** `^C\d{5}$`

**Enforced at:**

- `04_merge_relationships.R` — Strips `cpd:` prefix from API responses via `gsub("cpd:", "", cpd)`

!!! note
    The pipeline strips the `cpd:` prefix but does **not** validate the resulting format against `^C\d{5}$`. Format correctness relies on the upstream KEGG API returning well-formed identifiers.

**Invalid entries:** Not explicitly filtered — the pipeline trusts KEGG API data quality.

---

### KEGG Orthology ID (`ko`)

**Format:** `K#####` (letter K followed by exactly 5 digits)

**Regex:** `K\d{5}`

**Enforced at:** `05_add_classifications.R`

**Sanitization steps:**

1. Remove `ko:` prefix (case-insensitive): `ko:K00001` → `K00001`
2. Extract `K\d{5}` pattern via regex (handles mixed formats)
3. Standardize to uppercase: `k00001` → `K00001`
4. Rows with no valid KO pattern → **removed** (`filter(!is.na(ko))`)

```r
# Actual implementation pattern
mutate(
  ko = str_trim(as.character(ko)),
  ko = str_remove(ko, regex("^ko\\s*:\\s*", ignore_case = TRUE)),
  ko_extracted = str_extract(ko, regex("K\\d{5}", ignore_case = TRUE)),
  ko = if_else(!is.na(ko_extracted), str_c("K", str_extract(ko_extracted, "\\d{5}")), NA_character_)
) %>%
select(-ko_extracted) %>%
filter(!is.na(ko))
```

---

### Agency Codes (`referenceAG`)

**Controlled vocabulary:** 9 valid codes

`ATSDR`, `EPA`, `IARC1`, `IARC2A`, `IARC2B`, `PSL`, `EPC`, `WFD`, `CONAMA`

**Enforced at:** Input file curation (manual QC). The pipeline trusts the curated input file and does not perform runtime validation against this vocabulary.

---

## Data Normalization Rules

### Compound Class Normalization

**Enforced at:** `05_add_classifications.R`

| Rule | Example |
|------|---------|
| Split comma-separated classes into rows | `"Aromatic, Chlorinated"` → 2 rows |
| Trim whitespace | `" Aromatic "` → `"Aromatic"` |
| Fix spelling errors | `"Organometalic"` → `"Organometallic"` |
| Remove annotation artifacts | `"Aromatic (repeated)"` → `"Aromatic"` |
| Remove NA values | `NA` rows excluded |

```r
separate_rows(compoundclass, sep = ",") %>%
mutate(
  compoundclass = str_trim(compoundclass),
  compoundclass = str_replace_all(compoundclass, " \\(repeated\\)", ""),
  compoundclass = str_replace_all(compoundclass, "Organometalic", "Organometallic")
) %>%
filter(!is.na(compoundclass), compoundclass != "")
```

---

### Gene Symbol Normalization

**Enforced at:** `07_extract_enzymes_export.R`

- Gene symbols are trimmed to the **first alias** (content before the first comma)
- Example: `"CYP1A1, CYP1A2"` → `"CYP1A1"`

---

### Gene Name Cleaning

**Enforced at:** `07_extract_enzymes_export.R`

- EC numbers in brackets are stripped: `"alcohol dehydrogenase [EC:1.1.1.1]"` → `"alcohol dehydrogenase"`

---

### Compound Name Cleaning

**Enforced at:** `03_fetch_kegg_data.R`

- Synonyms after semicolons are removed: `"Water; H2O"` → `"Water"`

---

## Enzyme Activity Extraction

**Enforced at:** `07_extract_enzymes_export.R`

**Lexicon:** 218 standardized enzyme activity terms from `enzymes_unique.txt`

**Method:**

1. All 218 terms are combined into a single word-boundary regex pattern
2. The regex is applied to the `genename` column
3. First match is extracted as `enzyme_activity`
4. If no match, `enzyme_activity` retains the full `genename`

**Examples:**

| Gene Name | Extracted Activity |
|-----------|--------------------|
| `cytochrome P450 family 2 subfamily E polypeptide 1` | `cytochrome P450` |
| `naphthalene 1,2-dioxygenase` | `dioxygenase` |
| `glutathione S-transferase` | `transferase` |

---

## Gene Information Completeness Gate

**Enforced at:** `06_enrich_gene_info.R`

After left-joining gene information from the KO reference:

- Rows where `genesymbol` is `NA` or empty → **removed**
- Rows where `genename` is `NA` or empty → **removed**

This ensures 100% field completeness in the final database.

---

## Deduplication

**Enforced at:** Multiple steps

- `04_merge_relationships.R` — Deduplicates compound-KO pairs after merging EC-based and reaction-based links
- `06_enrich_gene_info.R` — Deduplicates KO reference entries before joining

---

## KEGG API Retry Logic

**Enforced at:** `03_fetch_kegg_data.R`

- **Attempts:** 3 per endpoint
- **Backoff:** Linear — `Sys.sleep(attempt)` (1 s, 2 s, 3 s)
- **On failure:** Pipeline fails with descriptive error after 3 attempts

---

## Output Schema Enforcement

**Enforced at:** `07_extract_enzymes_export.R`

The final `select()` call uses `EXPECTED_DATABASE_COLUMNS` from `io_contracts.R` to ensure:

- Exactly 8 columns in the output
- Correct column order
- No extra or missing columns

---

## SHA-256 Checksums

**Enforced at:** `build_run_report.py` (Layer 3 — Reporting)

All final artifacts receive SHA-256 checksums recorded in `workflow_summary.json`, enabling:

- Post-hoc integrity verification
- Detection of accidental file modifications
- Provenance chain for audit trails
