# Data Quality

This document specifies the quality control strategies, validation procedures, and known limitations of the BioRemPP Database v1.0.0.

---

## Data Quality Objectives

The BioRemPP Database generation pipeline implements quality control measures to ensure:

1. **Identifier consistency** — All KEGG Compound and Orthology IDs conform to standard formats
2. **Data completeness** — Zero missing values in final database (100% field completeness)
3. **Relationship validity** — All compound-gene relationships are supported by KEGG data or manual curation
4. **Controlled vocabularies** — Standardized enzyme activity terms and agency codes
5. **Deduplication** — Removal of redundant compound-KO relationships
6. **Normalization** — Consistent formatting of gene symbols and names

**Quality philosophy:** Prioritize data integrity and reproducibility over maximizing database size. Entries failing validation checks are excluded rather than retained with incomplete or inconsistent data.

### Snakemake Workflow Infrastructure

As of v1.0.0 the pipeline runs under **Snakemake 7.32.4**. In addition to the per-step quality controls described below, the workflow provides three cross-cutting integrity mechanisms:

- **Preflight validation** — The `preflight_check_inputs` rule verifies that every required input file exists before any processing rule is executed.
- **Shared contracts** — `workflow/lib/io_contracts.R` defines `REQUIRED_INPUT_FILES`, `EXPECTED_DATABASE_COLUMNS`, and `KEGG_ENDPOINTS` constants that are imported by every script, ensuring consistent validation across all pipeline steps.
- **Output checksums** — SHA-256 hashes for every output artefact are recorded in `workflow_summary.json`, enabling downstream integrity verification.

---

## Validation and Consistency Checks

### Identifier Format Validation

#### KEGG Compound IDs (`cpd`)

**Validation rule:** Must match regex pattern `^C\d{5}$`

**Implementation:**

```r
# Compound IDs are cleaned during the merge step
combined %>%
  dplyr::distinct() %>%
  dplyr::mutate(cpd = gsub("cpd:", "", cpd))
```

**Enforcement:**

- Deduplication via `distinct()` before prefix removal
- Prefix removal: `cpd:C00001` → `C00001`
- Format correctness relies on upstream KEGG API data quality (no explicit `^C\d{5}$` validation in code)

**Source:** `workflow/scripts/generation/04_merge_relationships.R`

---

#### KEGG Orthology IDs (`ko`)

**Validation rule:** Must match regex pattern `^K\d{5}$`

**Implementation:**

```r
sanitized <- classified %>%
  dplyr::mutate(
    # Trim whitespace and coerce to character
    ko = stringr::str_trim(as.character(ko)),
    # Remove "ko:" prefix
    ko = stringr::str_remove(ko, stringr::regex("^ko\\s*:\\s*", ignore_case = TRUE)),
    # Extract K##### pattern
    ko_extracted = stringr::str_extract(ko, stringr::regex("K\\d{5}", ignore_case = TRUE)),
    # Standardize to K##### format
    ko = dplyr::if_else(
      !is.na(ko_extracted),
      paste0("K", stringr::str_extract(ko_extracted, "\\d{5}")),
      NA_character_
    )
  ) %>%
  # Remove rows with NA KO identifiers
  dplyr::filter(!is.na(ko)) %>%
  dplyr::select(-ko_extracted)
```

**Enforcement:**

- Prefix removal: `ko:K00001` → `K00001`
- Case normalization: `k00001` → `K00001`
- Pattern extraction: Only K##### format retained
- Invalid entries: Filtered out (excluded from database)

**Source:** `workflow/scripts/generation/05_add_classifications.R`

**Impact:** Entries with malformed KO IDs are excluded, ensuring 100% identifier consistency.

---

### Cross-Reference Validation

#### Compound-KEGG Consistency

**Validation rule:** All compounds in final database must exist in KEGG Compound reference

**Implementation:**

- Agency compounds are merged with KEGG compound list via `cpd` column
- Compounds without KEGG match are implicitly excluded during merge operation

**Source:** `workflow/scripts/generation/04_merge_relationships.R`

**Limitation:** Compounds classified by agencies but not present in KEGG (as of Dec,25) are excluded.

---

#### KO-Gene Information Consistency

**Validation rule:** All KO entries must have associated gene symbols and names

**Implementation:**

```r
enriched <- classified_data %>%
  dplyr::filter(!is.na(ko), ko != "") %>%
  dplyr::mutate(ko = stringr::str_trim(stringr::str_to_upper(ko))) %>%
  dplyr::left_join(
    kegg_reference %>%
      dplyr::filter(!is.na(ko), ko != "") %>%
      dplyr::mutate(ko = stringr::str_trim(stringr::str_to_upper(ko))),
    by = "ko"
  ) %>%
  dplyr::filter(
    !is.na(genesymbol), genesymbol != "",
    !is.na(genename), genename != ""
  )
```

**Enforcement:**

- KO IDs without gene information are filtered out
- Empty gene symbols or names cause exclusion

**Source:** `workflow/scripts/generation/06_enrich_gene_info.R`

**Impact:** KO entries not present in KEGG KO reference (as of Dec,25) are excluded.

---

### Controlled Vocabulary Validation

#### Environmental Agency Codes

**Validation rule:** Only 9 valid agency codes permitted

**Valid codes:** `ATSDR`, `EPA`, `IARC1`, `IARC2A`, `IARC2B`, `PSL`, `EPC`, `WFD`, `CONAMA`

**Implementation:** Enforced during manual curation of `compostos_todasagencias.xlsx`

**Verification:** Post-hoc analysis confirms only valid codes present

**Source:** Input file validation (manual QC)

---

#### Compound Classes

**Validation rule:** 12 standardized chemical classes

**Valid classes:** `Aromatic`, `Chlorinated`, `Nitrogen-containing`, `Polyaromatic`, `Aliphatic`, `Metal`, `Inorganic`, `Sulfur-containing`, `Organophosphorus`, `Organometallic`, `Halogenated`, `Organosulfur`

**Implementation:**

```r
tidy_classes <- compound_classes %>%
  separate_rows(compoundclass, sep = ",") %>%
  mutate(
    compoundclass = str_trim(compoundclass),
    compoundclass = str_replace_all(compoundclass, " \\(repeated\\)", ""),
    compoundclass = str_replace_all(compoundclass, "Organometalic", "Organometallic")
  ) %>%
  filter(!is.na(compoundclass), compoundclass != "")
```

**Enforcement:**

- Typo correction: `Organometalic` → `Organometallic`
- Removal of annotation artifacts: `(repeated)` removed
- NA and empty-string values excluded

**Source:** `workflow/scripts/generation/05_add_classifications.R`

**Limitation:** No automated validation against controlled vocabulary; relies on manual curation quality.

---

#### Enzyme Activity Terms

**Validation rule:** 218 standardized enzyme terms

**Implementation:**

```r
terms <- readLines(file_path, warn = FALSE)
terms <- trimws(terms)
enzyme_terms <- unique(terms[terms != ""])
```

**Enforcement:**

- Whitespace trimming (base R `trimws()`)
- Deduplication
- Empty line removal

**Source:** `workflow/scripts/generation/01_load_local_data.R`

**Fallback behavior:** If no enzyme term matches, full `genename` is used as `enzyme_activity`

---

## Handling of Missing or Ambiguous Entries

### Missing Gene Information

**Issue:** KO IDs without corresponding gene symbols or names in KEGG reference

**Handling strategy:** **Exclusion**

**Implementation:**

```r
filter(
  !is.na(genesymbol), genesymbol != "",
  !is.na(genename), genename != ""
)
```

**Rationale:** Gene information is essential for functional interpretation; entries without this data provide limited value.

**Impact:** Rows without gene match are silently filtered — no explicit log message is emitted.

**Source:** `workflow/scripts/generation/06_enrich_gene_info.R`

---

### Missing Compound Names

**Issue:** Compounds without names in KEGG Compound list

**Handling strategy:** **Exclusion** (implicit via inner join)

**Implementation:**

```r
merged_compounds <- add_compound_names(integrated, kegg_data$compound_list)
# where add_compound_names simply calls:
# merge(compounds, compound_list, by = "cpd")
```

**Rationale:** Compound names are required for human-readable reporting and interpretation.

**Source:** `workflow/scripts/generation/04_merge_relationships.R`

---

### Missing Compound Classifications

**Issue:** Compounds without chemical class annotations

**Handling strategy:** **Exclusion** (implicit via inner join)

**Implementation:**

```r
classified <- merge(tidy_classes, merged_compounds, by = "cpd") %>%
  dplyr::distinct() %>%
  dplyr::arrange(ko)
```

**Rationale:** Chemical classification enables filtering and analysis by structural features; unclassified compounds are excluded to maintain data quality.

**Impact:** Only compounds with manual expert classification are included in final database.

**Source:** `workflow/scripts/generation/05_add_classifications.R`

---

### Ambiguous Enzyme Activities

**Issue:** Gene names not matching any standardized enzyme term

**Handling strategy:** **Fallback to full gene name**

**Implementation:**

```r
final_database <- enriched_data %>%
  dplyr::mutate(
    enzyme_activity = stringr::str_extract(genename, stringr::regex(enzyme_pattern, ignore_case = TRUE)),
    # Fallback to genename if no enzyme term found
    enzyme_activity = dplyr::if_else(is.na(enzyme_activity), genename, enzyme_activity)
  )
```

**Rationale:** Preserves full functional annotation when standardized term is unavailable.

**Impact:** Some `enzyme_activity` values are long descriptive names rather than concise terms.

**Source:** `workflow/scripts/generation/07_extract_enzymes_export.R`

---

## Deduplication and Normalization Strategies

### Deduplication of KO-Compound Relationships

**Issue:** Multiple pathways may link the same KO to the same compound (via different EC numbers or reactions)

**Strategy:** Remove duplicate KO-compound pairs

**Implementation:**

```r
# Combine both datasets
combined <- rbind(
  ko_ec_cpd[, c("ko", "cpd")],
  ko_reaction_cpd[, c("ko", "cpd")]
)

# Remove duplicates
combined %>%
  dplyr::distinct() %>%
  dplyr::mutate(cpd = gsub("cpd:", "", cpd))
```

**Source:** `workflow/scripts/generation/04_merge_relationships.R`

**Impact:** Each unique KO-compound relationship appears only once, regardless of how many EC numbers or reactions link them.

---

### Deduplication of KEGG Reference Data

**Issue:** KEGG KO list may contain duplicate KO IDs with different gene annotations

**Strategy:** Keep first occurrence per KO ID

**Implementation:**

```r
kegg_reference <- local_data$ko_list %>%
  dplyr::transmute(
    ko = stringr::str_trim(stringr::str_to_upper(ko)),
    genesymbol = stringr::str_trim(genesymbol),
    genename = stringr::str_trim(genename)
  ) %>%
  dplyr::group_by(ko) %>%
  dplyr::summarise(
    genesymbol = dplyr::first(genesymbol),
    genename = dplyr::first(genename),
    .groups = "drop"
  )
```

**Source:** `workflow/scripts/generation/06_enrich_gene_info.R`

**Impact:** One gene symbol and name per KO ID; isoforms/variants are collapsed.

---

### Normalization of Gene Symbols

**Issue:** Gene symbols may contain comma-separated isoforms (e.g., `CYP1A1,CYP1A2`)

**Strategy:** Keep only first symbol before comma

**Implementation:**

```r
final_database <- enriched_data %>%
  dplyr::mutate(
    # Remove everything after comma in gene symbols
    genesymbol = stringr::str_remove(genesymbol, ",.*$")
  )
```

**Source:** `workflow/scripts/generation/07_extract_enzymes_export.R`

**Impact:** Simplifies gene symbols to single canonical identifier.

---

### Normalization of Gene Names

**Issue:** Gene names contain EC numbers in brackets (e.g., `alcohol dehydrogenase [EC:1.1.1.1]`)

**Strategy:** Remove EC number annotations

**Implementation:**

```r
final_database <- enriched_data %>%
  dplyr::mutate(
    # Remove EC numbers from gene names
    genename = stringr::str_remove(genename, stringr::regex("\\s*\\[EC.*$", ignore_case = TRUE))
  )
```

**Source:** `workflow/scripts/generation/07_extract_enzymes_export.R`

**Impact:** Gene names are cleaner and more consistent; EC information is not retained in final database.

---

### Normalization of Compound Names

**Issue:** KEGG compound names contain semicolon-separated synonyms

**Strategy:** Keep only primary name (before first semicolon)

**Implementation:**

```r
kegg_data$compound_list <- fetch_endpoint(
  KEGG_ENDPOINTS$compound_list$endpoint,
  KEGG_ENDPOINTS$compound_list$columns,
  KEGG_ENDPOINTS$compound_list$sep
)

# Remove synonyms (everything after semicolon)
kegg_data$compound_list$compoundname <- sub(";.*$", "", kegg_data$compound_list$compoundname)
```

**Source:** `workflow/scripts/generation/03_fetch_kegg_data.R`

**Impact:** One canonical name per compound; synonyms are not retained.

---

## Known Limitations and Residual Issues

### Temporal Dependency on KEGG

**Limitation:** Database content depends on KEGG release version

**Impact:**

- Different KEGG releases yield different database sizes
- Compounds/KO entries added to KEGG after Dec,25 are not included
- Deprecated KEGG entries may cause validation failures

**Mitigation:** Document KEGG release version (Dec,25) for reproducibility

**Recommendation:** Re-generate database when updating to new KEGG releases

---

### Incomplete Coverage of Environmental Compounds

**Limitation:** Only compounds with KEGG Compound IDs are included

**Impact:**

- Emerging contaminants without KEGG entries are excluded
- Novel pollutants not yet in KEGG database are missing
- Some agency-listed compounds may lack KEGG representation

**Mitigation:** Manual curation file (`missing_compounds_founds_curated.xlsx`) allows addition of literature-derived relationships

**Estimated coverage:** ~2.1% of KEGG Compound database (384/18,600)

---

### Enzyme Activity Extraction Limitations

**Limitation:** Pattern matching may miss or misclassify enzyme activities

**Issues:**

- **False negatives:** Novel enzyme terms not in lexicon are missed
- **False positives:** Rare; regex word boundaries prevent most cases
- **Ambiguity:** Some gene names match multiple enzyme terms (first match used)

**Mitigation:** Fallback to full gene name preserves information

**Impact:** ~205 unique enzyme activities extracted; long-tail distribution with many single-occurrence terms

---

### Multi-Class Compound Representation

**Limitation:** Compounds with multiple chemical classes appear in multiple rows

**Impact:**

- Row count (10,871) exceeds unique compound count (384)
- Aggregation required to count unique compounds per class
- Potential for double-counting in naive analyses

**Mitigation:** Documented in schema and statistics; users advised to use `distinct(cpd)` for unique compound counts

---

### Gene Symbol Simplification

**Limitation:** Comma-separated isoforms are collapsed to first symbol

**Impact:**

- Loss of isoform information (e.g., `CYP1A1,CYP1A2` → `CYP1A1`)
- May obscure functional diversity within KO groups

**Rationale:** Simplifies schema and prevents ambiguity in gene symbol field

**Alternative:** Users can consult KEGG KO database for full isoform lists

---

### No Organism-Specific Annotations

**Limitation:** KO groups are organism-independent; no species-level gene information

**Impact:**

- Cannot distinguish human vs. microbial genes within same KO
- Unsuitable for organism-specific pathway reconstruction without additional mapping

**Rationale:** Database focuses on functional potential, not taxonomic distribution

**Recommendation:** Users should map KO IDs to organism-specific genes via KEGG Organism database

---

### Manual Curation Quality Dependency

**Limitation:** Quality of curated data (`missing_compounds_founds_curated.xlsx`, `confirm_class_CURATED.xlsx`) depends on expert judgment

**Risks:**

- Potential for human error in compound-KO assignments
- Subjective chemical classification decisions
- Incomplete literature coverage

**Mitigation:**

- Curation provenance documented externally (not in database)
- Peer review of curated entries recommended
- Version control tracks curation changes

**Impact:** ~62 manually curated compound-KO relationships; ~384 compound classifications

---

### No Pathway Completeness Validation

**Limitation:** Database does not verify completeness of biodegradation pathways

**Impact:**

- Presence of gene does not guarantee functional pathway
- Missing pathway intermediates not detected
- Incomplete enzyme cascades may be represented

**Rationale:** Database provides functional potential, not pathway validation

**Recommendation:** Users should consult KEGG Pathway maps for pathway context

---

## Implications for Downstream Reuse

### Data Integrity Guarantees

**Users can rely on:**

- ✅ **100% field completeness** — No missing values in any column
- ✅ **Identifier format consistency** — All KEGG IDs conform to standards
- ✅ **Controlled vocabularies** — Agency codes and compound classes are standardized
- ✅ **Deduplication** — No redundant KO-compound pairs

**Users should be aware of:**

- ⚠️ **Temporal dependency** — Database reflects KEGG Dec,25; updates may change content
- ⚠️ **Incomplete coverage** — Not all environmental compounds are represented
- ⚠️ **Multi-class rows** — Compounds with multiple classes appear multiple times
- ⚠️ **Simplified gene symbols** — Isoform information is collapsed

---

### Recommended Quality Checks for Users

Before using BioRemPP Database, users should:

1. **Verify row count:** Expect 10,871 rows for v1.0.0
2. **Check for missing values:** Run `colSums(is.na(db))` → all zeros
3. **Validate identifier formats:** Verify `cpd` and `ko` match regex patterns
4. **Understand multi-class representation:** Use `distinct(cpd)` for unique compound counts
5. **Review enzyme activity distribution:** Be aware of long-tail distribution (top 5 enzymes = 50% of entries)

---

### Appropriate Use Cases

**BioRemPP Database is suitable for:**

- ✅ Annotating metagenomic functional profiles with bioremediation potential
- ✅ Identifying genes associated with priority environmental pollutants
- ✅ Comparative analysis of enzyme diversity across compound classes
- ✅ Regulatory compliance reporting (agency-specific compound lists)

**BioRemPP Database is NOT suitable for:**

- ❌ Organism-specific pathway reconstruction (use KEGG Organism database)
- ❌ Quantitative pathway flux analysis (no stoichiometry or kinetics)
- ❌ Comprehensive coverage of all xenobiotics (limited to KEGG + curated compounds)
- ❌ Real-time KEGG data (static snapshot from Dec,25)

---

### Data Update and Maintenance

**Recommended update frequency:** Annually, or when major KEGG releases occur

**Update procedure:**

1. Download latest KEGG reference files (`kegglistcompounds.xlsx`, `kegglistko.txt`)
2. Review and update agency compound lists
3. Add new manual curations from recent literature
4. Re-run pipeline: `snakemake --cores all`
5. Validate output against expected statistics
6. Document changes in version control

**Version control:** Use semantic versioning (v1.x.x for minor updates, v2.0.0 for schema changes)

---

## Automated Validation with Great Expectations

Beyond the pipeline-level quality controls described above, the
**biorempp-validation** module provides 71 automated expectations that verify
schema integrity, domain-value contracts, cross-consistency, and exact-match
reproducibility after every pipeline run.

See the [Data Validation (GX)](../validation-gx/architecture.md) section,
particularly:

- [Data Contracts](../validation-gx/data-contracts.md) — column schema,
  identifier formats, and closed vocabularies.
- [Severity Policy](../validation-gx/severity-policy.md) — how critical vs.
  warning failures are handled.
- [Test Suite](../validation-gx/testing.md) — mutation-based tests that
  verify each fault is detected.

---

## Questions?

**GitHub Issues:** [https://github.com/BioRemPP/biorempp_db/issues](https://github.com/BioRemPP/biorempp_db/issues)  
**Email:** biorempp@gmail.com
