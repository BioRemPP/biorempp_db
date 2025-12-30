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

---

## Validation and Consistency Checks

### Identifier Format Validation

#### KEGG Compound IDs (`cpd`)

**Validation rule:** Must match regex pattern `^C\d{5}$`

**Implementation:**

```r
# Compound IDs are cleaned during data loading
unique_ko_cpd$cpd <- gsub("cpd:", "", unique_ko_cpd$cpd)
```

**Enforcement:**

- Prefix removal: `cpd:C00001` → `C00001`
- Format verification: Only C##### format retained
- Invalid IDs: Excluded from final database

**Source:** `generate_database.R`, lines 376-377

---

#### KEGG Orthology IDs (`ko`)

**Validation rule:** Must match regex pattern `^K\d{5}$`

**Implementation:**

```r
sanitized_data <- classified_compounds %>%
  mutate(
    # Remove "ko:" prefix
    ko = str_remove(ko, regex("^ko\\s*:\\s*", ignore_case = TRUE)),
    # Extract K##### pattern
    ko_k = str_extract(ko, regex("K\\d{5}", ignore_case = TRUE)),
    # Standardize to K##### format
    ko = if_else(
      !is.na(ko_k),
      str_c("K", str_extract(ko_k, "\\d{5}")),
      NA_character_
    )
  ) %>%
  # Remove rows with NA KO identifiers
  filter(!is.na(ko)) %>%
  select(-ko_k)
```

**Enforcement:**

- Prefix removal: `ko:K00001` → `K00001`
- Case normalization: `k00001` → `K00001`
- Pattern extraction: Only K##### format retained
- Invalid entries: Filtered out (excluded from database)

**Source:** `generate_database.R`, lines 481-498

**Impact:** Entries with malformed KO IDs are excluded, ensuring 100% identifier consistency.

---

### Cross-Reference Validation

#### Compound-KEGG Consistency

**Validation rule:** All compounds in final database must exist in KEGG Compound reference

**Implementation:**

- Agency compounds are merged with KEGG compound list via `cpd` column
- Compounds without KEGG match are implicitly excluded during merge operation

**Source:** `generate_database.R`, lines 420-428

**Limitation:** Compounds classified by agencies but not present in KEGG (as of Dec,25) are excluded.

---

#### KO-Gene Information Consistency

**Validation rule:** All KO entries must have associated gene symbols and names

**Implementation:**

```r
compounds_with_genes <- sanitized_compounds %>%
  filter(!is.na(ko), ko != "") %>%
  mutate(ko = str_trim(str_to_upper(ko))) %>%
  left_join(
    kegg_reference %>%
      filter(!is.na(ko), ko != "") %>%
      mutate(ko = str_trim(str_to_upper(ko))),
    by = "ko"
  ) %>%
  filter(
    !is.na(genesymbol), genesymbol != "",
    !is.na(genename), genename != ""
  )
```

**Enforcement:**

- KO IDs without gene information are filtered out
- Empty gene symbols or names cause exclusion
- Pipeline reports count of excluded entries

**Source:** `generate_database.R`, lines 545-557

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
  na.omit()
```

**Enforcement:**

- Typo correction: `Organometalic` → `Organometallic`
- Removal of annotation artifacts: `(repeated)` removed
- NA values excluded

**Source:** `generate_database.R`, lines 434-443

**Limitation:** No automated validation against controlled vocabulary; relies on manual curation quality.

---

#### Enzyme Activity Terms

**Validation rule:** 210 standardized enzyme terms

**Implementation:**

```r
enzyme_terms <- readLines(file_path, warn = FALSE) %>%
  str_trim() %>%
  unique()

# Remove empty strings
enzyme_terms <- enzyme_terms[enzyme_terms != ""]
```

**Enforcement:**

- Whitespace trimming
- Deduplication
- Empty line removal

**Source:** `generate_database.R`, lines 238-246

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

**Impact:** Reported during pipeline execution:

```
⚠ Entries without gene match: [count]
```

**Source:** `generate_database.R`, lines 553-556

---

### Missing Compound Names

**Issue:** Compounds without names in KEGG Compound list

**Handling strategy:** **Exclusion** (implicit via inner join)

**Implementation:**

```r
compounds_with_names <- merge(compounds, compound_list, by = "cpd")
```

**Rationale:** Compound names are required for human-readable reporting and interpretation.

**Source:** `generate_database.R`, lines 424

---

### Missing Compound Classifications

**Issue:** Compounds without chemical class annotations

**Handling strategy:** **Exclusion** (implicit via inner join)

**Implementation:**

```r
classified_compounds <- merge(tidy_classes, compounds, by = "cpd") %>%
  unique() %>%
  arrange(ko)
```

**Rationale:** Chemical classification enables filtering and analysis by structural features; unclassified compounds are excluded to maintain data quality.

**Impact:** Only compounds with manual expert classification are included in final database.

**Source:** `generate_database.R`, lines 465-467

---

### Ambiguous Enzyme Activities

**Issue:** Gene names not matching any standardized enzyme term

**Handling strategy:** **Fallback to full gene name**

**Implementation:**

```r
compounds_with_enzymes <- compounds_with_genes %>%
  mutate(
    enzyme_activity = str_extract(genename, regex(enzyme_pattern, ignore_case = TRUE)),
    # Fallback to genename if no enzyme term found
    enzyme_activity = if_else(is.na(enzyme_activity), genename, enzyme_activity)
  )
```

**Rationale:** Preserves full functional annotation when standardized term is unavailable.

**Impact:** Some `enzyme_activity` values are long descriptive names rather than concise terms.

**Source:** `generate_database.R`, lines 600-605

---

## Deduplication and Normalization Strategies

### Deduplication of KO-Compound Relationships

**Issue:** Multiple pathways may link the same KO to the same compound (via different EC numbers or reactions)

**Strategy:** Remove duplicate KO-compound pairs

**Implementation:**

```r
# Combine both datasets
combined_ko_cpd <- rbind(
  ko_ec_cpd[, c("ko", "cpd")],
  ko_reaction_cpd[, c("ko", "cpd")]
)

# Remove duplicates
unique_ko_cpd <- unique(combined_ko_cpd)
```

**Source:** `generate_database.R`, lines 369-376

**Impact:** Each unique KO-compound relationship appears only once, regardless of how many EC numbers or reactions link them.

---

### Deduplication of KEGG Reference Data

**Issue:** KEGG KO list may contain duplicate KO IDs with different gene annotations

**Strategy:** Keep first occurrence per KO ID

**Implementation:**

```r
kegg_reference <- ko_list %>%
  transmute(
    ko = str_trim(str_to_upper(ko)),
    genesymbol = str_trim(genesymbol),
    genename = str_trim(genename)
  ) %>%
  group_by(ko) %>%
  summarise(
    genesymbol = first(genesymbol),
    genename = first(genename),
    .groups = "drop"
  )
```

**Source:** `generate_database.R`, lines 514-524

**Impact:** One gene symbol and name per KO ID; isoforms/variants are collapsed.

---

### Normalization of Gene Symbols

**Issue:** Gene symbols may contain comma-separated isoforms (e.g., `CYP1A1,CYP1A2`)

**Strategy:** Keep only first symbol before comma

**Implementation:**

```r
cleaned_data <- compounds_with_enzymes %>%
  mutate(
    # Remove everything after comma in gene symbols
    genesymbol = str_remove(genesymbol, ",.*$")
  )
```

**Source:** `generate_database.R`, lines 623-627

**Impact:** Simplifies gene symbols to single canonical identifier.

---

### Normalization of Gene Names

**Issue:** Gene names contain EC numbers in brackets (e.g., `alcohol dehydrogenase [EC:1.1.1.1]`)

**Strategy:** Remove EC number annotations

**Implementation:**

```r
cleaned_data <- compounds_with_enzymes %>%
  mutate(
    # Remove EC numbers from gene names
    genename = str_remove(genename, regex("\\s*\\[EC.*$", ignore_case = TRUE))
  )
```

**Source:** `generate_database.R`, lines 623-626

**Impact:** Gene names are cleaner and more consistent; EC information is not retained in final database.

---

### Normalization of Compound Names

**Issue:** KEGG compound names contain semicolon-separated synonyms

**Strategy:** Keep only primary name (before first semicolon)

**Implementation:**

```r
compound_list <- fetch_kegg_api("list/cpd/", c("cpd", "compoundname"))

# Remove synonyms (everything after semicolon)
if ("compoundname" %in% colnames(compound_list)) {
  compound_list$compoundname <- sub(";.*$", "", compound_list$compoundname)
}
```

**Source:** `generate_database.R`, lines 322-328

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

- Row count (10,869) exceeds unique compound count (384)
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

1. **Verify row count:** Expect 10,869 rows for v1.0.0
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
4. Re-run pipeline: `source("generate_database.R")`
5. Validate output against expected statistics
6. Document changes in version control

**Version control:** Use semantic versioning (v1.x.x for minor updates, v2.0.0 for schema changes)

---

## Questions?

**GitHub Issues:** [https://github.com/BioRemPP/biorempp_db/issues](https://github.com/BioRemPP/biorempp_db/issues)  
**Email:** biorempp@gmail.com
