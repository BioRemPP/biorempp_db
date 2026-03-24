# Input Data Files

This document specifies all input data required by the BioRemPP Database generation pipeline, including file formats, schemas, validation rules, and data provenance.

---

## Overview of Input Data Types

The BioRemPP Database pipeline requires **six mandatory input files**. All six are loaded from a single directory configured as `paths.input_dir` in `config/config.yaml` (default: `../input_data`, i.e. the repository root `input_data/`). A convenience copy of all six files also exists inside `biorempp_snakemake_version/input_data/`.

!!! info "Automatic preflight validation"
    The Snakemake `preflight_check_inputs` rule validates that every required file exists before any processing begins. The canonical list of expected files is defined in `workflow/lib/io_contracts.R` (`REQUIRED_INPUT_FILES`).

### Category 1: KEGG Reference Data (Static Snapshots)

Pre-downloaded KEGG data to ensure reproducibility and reduce API dependency:

- `kegglistcompounds.xlsx` — KEGG compound reference list
- `kegglistko.txt` — KEGG Orthology reference list

**Purpose:** Provide stable identifier mappings and nomenclature independent of real-time API availability.

### Category 2: Environmental Regulatory Data (Curated)

Compound lists from international environmental agencies:

- `compostos_todasagencias.xlsx` — Unified agency compound list

**Purpose:** Define the scope of priority environmental pollutants to be included in the database.

### Category 3: Expert Curations (Manually Maintained)

Domain-expert-contributed data to fill gaps and improve coverage:

- `missing_compounds_founds_curated.xlsx` — Manual compound-KO curations
- `confirm_class_CURATED.xlsx` — Chemical compound classifications
- `enzymes_unique.txt` — Standardized enzyme activity lexicon

**Purpose:** Integrate literature-derived knowledge and domain expertise not captured by automated data sources.

---

## Mandatory Input Files

All six files must be present in the configured input directory for pipeline execution. The `preflight_check_inputs` rule verifies this automatically.

### File 1: `kegglistcompounds.xlsx`

**Type:** KEGG Reference Data (automatically retrieved, static snapshot)

**Format:** Excel Workbook (.xlsx)

**Size:** ~425 KB

**Source:** KEGG REST API (`https://rest.kegg.jp/list/compound`)

**Scientific Role:** Provides authoritative KEGG Compound identifiers and standardized nomenclature for all chemical compounds in KEGG database.

#### Schema

| Column | Position | Type | Required | Description | Example |
|--------|----------|------|----------|-------------|---------|
| Compound ID | A | Character | ✅ Yes | KEGG Compound identifier (C#####) | `C00001` |
| Compound Name | B | Character | ✅ Yes | Primary compound name (semicolon-separated synonyms removed) | `Water` |

**Total rows:** ~18,600 (as of KEGG Release Dec,23)

**Header row:** None (pipeline assigns column names programmatically)

#### Validation Rules

- ✅ Column A must contain valid KEGG Compound IDs matching regex `^C\d{5}$`
- ✅ Column B must contain non-empty compound names
- ✅ No duplicate Compound IDs
- ⚠️ Compound names may contain special characters (Greek letters, subscripts, parentheses)

#### Update Protocol

**Frequency:** Manually, when updating to new KEGG releases

**Method:**
```r
# Download from KEGG API
compound_list <- read.csv("https://rest.kegg.jp/list/compound", 
                          header = FALSE, sep = "\t")
compound_list$V2 <- sub(";.*$", "", compound_list$V2)  # Remove synonyms

# Save to Excel
library(writexl)
write_xlsx(compound_list, "kegglistcompounds.xlsx")
```

---

### File 2: `kegglistko.txt`

**Type:** KEGG Reference Data (automatically retrieved, static snapshot)

**Format:** Tab-separated values (.txt)

**Size:** ~1.6 MB

**Source:** KEGG REST API (`https://rest.kegg.jp/list/ko`)

**Scientific Role:** Maps KEGG Orthology identifiers to gene symbols and functional descriptions for all KO groups.

#### Schema

| Column | Delimiter | Type | Required | Description | Example |
|--------|-----------|------|----------|-------------|---------|
| `ko` | Tab | Character | ✅ Yes | KEGG Orthology identifier (K#####) | `K00001` |
| `genesymbol` | Tab | Character | ✅ Yes | Standard gene symbol | `ADH1` |
| `genename` | Tab | Character | ✅ Yes | Full gene functional description | `alcohol dehydrogenase [EC:1.1.1.1]` |

**Total rows:** ~47,400 (as of KEGG Release 116.0+/12-16, Dec 25)

**Header row:** Yes (column names: `ko`, `genesymbol`, `genename`)

#### Validation Rules

- ✅ Column 1 (`ko`) must match regex `^K\d{5}$` or `^ko:K\d{5}$`
- ✅ Column 2 (`genesymbol`) must be non-empty
- ✅ Column 3 (`genename`) must be non-empty
- ⚠️ Gene symbols may contain commas (isoforms/variants)
- ⚠️ Gene names may contain EC numbers in brackets `[EC:X.X.X.X]`

#### Update Protocol

**Frequency:** Manually, when updating to new KEGG releases

**Method:**
```bash
# Download from KEGG API
curl "https://rest.kegg.jp/list/ko" > kegglistko.txt

# Add header manually or via script
echo -e "ko\tgenesymbol\tgenename" | cat - kegglistko.txt > kegglistko_with_header.txt
mv kegglistko_with_header.txt kegglistko.txt
```

---

### File 3: `compostos_todasagencias.xlsx`

**Type:** Environmental Regulatory Data (manually curated)

**Format:** Excel Workbook (.xlsx)

**Size:** ~30 KB

**Source:** Manual compilation from 9 international environmental agency databases

**Scientific Role:** Defines the scope of compounds to be included in the BioRemPP Database by specifying which KEGG compounds are classified as priority pollutants by regulatory authorities.

#### Schema

| Column | Position | Type | Required | Description | Example |
|--------|----------|------|----------|-------------|---------|
| Compound ID | A | Character | ✅ Yes | KEGG Compound identifier | `C06790` |
| Reference Agency | B | Character | ✅ Yes | Agency code | `EPA` |

**Total rows:** ~800

**Header row:** None (pipeline assigns column names: `cpd`, `referenceAG`)

#### Reference Agencies

| Code | Full Name | Jurisdiction | Description |
|------|-----------|--------------|-------------|
| `ATSDR` | Agency for Toxic Substances and Disease Registry | USA | Public health hazards |
| `EPA` | Environmental Protection Agency | USA | Priority pollutants |
| `IARC1` | IARC Group 1 | International | Carcinogenic to humans |
| `IARC2A` | IARC Group 2A | International | Probably carcinogenic |
| `IARC2B` | IARC Group 2B | International | Possibly carcinogenic |
| `PSL` | Priority Substances List | Canada | Canadian priority chemicals |
| `EPC` | Environmental Priority Chemicals | Europe | EU priority substances |
| `WFD` | Water Framework Directive | EU | Water quality standards |
| `CONAMA` | Conselho Nacional do Meio Ambiente | Brazil | Brazilian environmental law |

#### Validation Rules

- ✅ Column A must contain valid KEGG Compound IDs (C#####)
- ✅ Column B must contain one of the 9 valid agency codes
- ✅ Compound-agency pairs may be duplicated (same compound in multiple agencies)
- ⚠️ Compounds not present in `kegglistcompounds.xlsx` will be filtered out during pipeline execution

#### Update Protocol

**Frequency:** Annually, or when agency lists are updated

**Method:**

1. Consult official agency databases
2. Map compound names to KEGG Compound IDs via [KEGG Search](https://www.kegg.jp/kegg/compound/)
3. Manually update Excel file
4. Document changes in version control commit message

---

### File 4: `missing_compounds_founds_curated.xlsx`

**Type:** Expert Curation (manually curated)

**Format:** Excel Workbook (.xlsx)

**Size:** ~38 KB

**Source:** Literature review and manual curation by BioRemPP team

**Scientific Role:** Fills gaps in KEGG API-derived compound-KO relationships by adding literature-supported associations not yet available in KEGG.

#### Schema

| Column | Position | Type | Required | Description | Example |
|--------|----------|------|----------|-------------|---------|
| Compound ID | A | Character | ✅ Yes | KEGG Compound identifier | `C02737` |
| KO ID | B | Character | ✅ Yes | KEGG Orthology identifier | `K00799` |

**Total rows:** ~60

**Header row:** Yes (pipeline reads with default `col_names = TRUE`; columns: `cpd`, `ko`)

#### Validation Rules

- ✅ Column A must contain valid KEGG Compound IDs (C#####)
- ✅ Column B must contain valid KEGG Orthology IDs (K##### or ko:K#####)
- ✅ Each row represents one compound-KO relationship
- ✅ Relationships must be supported by peer-reviewed literature (documented externally)
- ⚠️ Duplicate compound-KO pairs are automatically removed during pipeline execution

#### Curation Guidelines

**When to add entries:**

- Newly published biodegradation pathways not yet in KEGG
- Experimentally validated gene-compound relationships from literature
- Domain-specific knowledge from specialized biodegradation databases (e.g., UM-BBD/EAWAG-BBD)

**Required documentation (external):**

- PubMed ID (PMID) or DOI of supporting publication
- Brief description of experimental evidence
- Curator name and date

**Example curation record (external log):**

```
cpd: C02737 (4-Nitrophenol)
ko: K00799 (glutathione S-transferase)
source: PMID:12345678
evidence: In vitro enzymatic assay demonstrated GST-mediated conjugation
curator: D. Felipe
date: 2024-11-15
```

#### Update Protocol

**Frequency:** Ongoing, as new literature is published

**Method:**

1. Identify new compound-gene relationship from literature
2. Map compound name to KEGG Compound ID
3. Map gene/enzyme to KEGG Orthology ID via [KEGG Search](https://www.kegg.jp/kegg/ko.html)
4. Add row to Excel file
5. Document provenance in external curation log
6. Commit to version control with descriptive message

---

### File 5: `confirm_class_CURATED.xlsx`

**Type:** Expert Curation (manually curated)

**Format:** Excel Workbook (.xlsx)

**Size:** ~17 KB

**Source:** Manual classification by chemical domain experts

**Scientific Role:** Assigns standardized chemical classifications to compounds to enable filtering and analysis by chemical class.

#### Schema

| Column | Position | Type | Required | Description | Example |
|--------|----------|------|----------|-------------|---------|
| Compound ID | A | Character | ✅ Yes | KEGG Compound identifier | `C06790` |
| Compound Class | B | Character | ✅ Yes | Chemical classification (comma-separated if multiple) | `Aromatic, Chlorinated` |

**Total rows:** ~380

**Header row:** Yes (column names: `cpd`, `compoundclass`)

#### Standardized Compound Classes

| Class | Description | Example Compounds |
|-------|-------------|-------------------|
| `Aliphatic` | Straight-chain or branched hydrocarbons | Hexane, Propane |
| `Aromatic` | Benzene ring-containing compounds | Benzene, Toluene |
| `Polyaromatic` | Multiple fused aromatic rings (PAHs) | Naphthalene, Anthracene |
| `Chlorinated` | Halogenated with chlorine | Trichloroethene, PCBs |
| `Nitrogen-containing` | Nitrogen functional groups | Nitrobenzene, Amines |
| `Heterocyclic` | Rings containing non-carbon atoms | Pyridine, Furan |
| `Organometallic` | Metal-carbon bonds | Methylmercury |
| `Sulfur-containing` | Sulfur functional groups | Thiols, Sulfides |
| `Oxygen-containing` | Oxygen functional groups (alcohols, ethers, ketones) | Phenol, MTBE |
| `Pharmaceutical` | Drug compounds | Antibiotics, Hormones |
| `Pesticide` | Agricultural chemicals | Atrazine, DDT |
| `Industrial` | Industrial chemicals | Solvents, Plasticizers |

#### Validation Rules

- ✅ Column A must contain valid KEGG Compound IDs
- ✅ Column B must contain one or more valid compound class names (comma-separated)
- ✅ Multiple classes allowed per compound (e.g., "Aromatic, Chlorinated")
- ✅ Class names are case-insensitive (pipeline normalizes)
- ⚠️ Typos in class names (e.g., "Organometalic") are auto-corrected by pipeline

#### Update Protocol

**Frequency:** As new compounds are added to `compostos_todasagencias.xlsx`

**Method:**

1. Identify new compound requiring classification
2. Review chemical structure via [KEGG Compound page](https://www.kegg.jp/entry/C#####)
3. Assign appropriate class(es) based on functional groups
4. Add row to Excel file
5. Validate classification with chemical expert if uncertain

---

### File 6: `enzymes_unique.txt`

**Type:** Expert Curation (manually curated)

**Format:** Plain text (.txt), one enzyme term per line

**Size:** ~3 KB

**Source:** Systematic extraction from KEGG gene annotations + literature review

**Scientific Role:** Provides a controlled vocabulary of enzyme activity terms for pattern-based extraction from KEGG gene names.

#### Schema

**Format:** Newline-separated plain text file

**Example content:**

```
cytochrome P450
dioxygenase
monooxygenase
dehydrogenase
reductase
hydroxylase
oxidase
hydrolase
transferase
nitrogenase
```

**Total entries:** 218 unique enzyme terms

**No header row**

#### Validation Rules

- ✅ Each line contains one enzyme activity term
- ✅ Terms are case-insensitive (pipeline uses regex matching)
- ✅ No duplicate terms
- ✅ Lines with only whitespace are ignored
- ⚠️ Avoid overly generic terms (e.g., "enzyme") that cause false positives

#### Common Enzyme Terms

| Enzyme Type | Biodegradation Role | Examples |
|-------------|---------------------|----------|
| **Cytochrome P450** | Oxidative metabolism of xenobiotics | `cytochrome P450` |
| **Dioxygenase** | Aromatic ring cleavage | `dioxygenase`, `catechol dioxygenase` |
| **Monooxygenase** | Ring hydroxylation | `monooxygenase`, `methane monooxygenase` |
| **Dehydrogenase** | Oxidation reactions | `dehydrogenase`, `alcohol dehydrogenase` |
| **Reductase** | Reduction of functional groups | `reductase`, `nitrate reductase` |
| **Hydrolase** | Bond cleavage via water | `hydrolase`, `esterase`, `amidase` |
| **Transferase** | Functional group transfer | `transferase`, `glutathione S-transferase` |
| **Nitrogenase** | Nitrogen fixation | `nitrogenase` |

#### Update Protocol

**Frequency:** As new enzyme families are encountered in literature

**Method:**

1. Identify new enzyme term from KEGG gene annotations or literature
2. Verify term is specific enough (not overly generic)
3. Add term on new line in file
4. Remove duplicates and sort alphabetically (optional)
5. Commit to version control

---

## File Format and Schema Expectations

### Excel File Requirements

All Excel files (`.xlsx`) must conform to:

- **Format:** Microsoft Excel 2007+ (.xlsx, not .xls)
- **Encoding:** UTF-8 (default for Excel)
- **Sheets:** Only the first sheet is read by the pipeline
- **Header rows:** Specified per file (some files have headers, others do not)
- **Empty cells:** Not allowed in required columns
- **Formulas:** Evaluated to values before reading (no formula preservation)

### Text File Requirements

All text files (`.txt`) must conform to:

- **Encoding:** UTF-8
- **Line endings:** LF (Unix) or CRLF (Windows) — both supported
- **Delimiter:** Tab (`\t`) for tabular data, newline for lists
- **BOM:** Not required (pipeline handles with/without BOM)

---

## Data Consistency and Validation Rules

### Cross-File Validation

The pipeline enforces the following consistency rules across files:

!!! tip "Snakemake workflow"
    In the Snakemake pipeline, the `preflight_check_inputs` rule validates that all required input files exist before any processing begins. It does **not** perform cross-file content validation. The manual verification snippets below are provided for ad-hoc inspection outside the pipeline.

#### Rule 1: Compound ID Consistency

✅ **All Compound IDs** in `compostos_todasagencias.xlsx`, `missing_compounds_founds_curated.xlsx`, and `confirm_class_CURATED.xlsx` **should exist** in `kegglistcompounds.xlsx`.

**Enforcement:** Compounds not in `kegglistcompounds.xlsx` are automatically excluded from final database.

**Verification:**
```r
# Check for unmapped compounds
library(readxl)
kegg_cpds <- read_excel("input_data/kegglistcompounds.xlsx", col_names = FALSE)$...1
agency_cpds <- read_excel("input_data/compostos_todasagencias.xlsx", col_names = FALSE)$...1
unmapped <- setdiff(agency_cpds, kegg_cpds)
if (length(unmapped) > 0) {
  warning("Unmapped compounds: ", paste(unmapped, collapse = ", "))
}
```

---

#### Rule 2: KO ID Consistency

✅ **All KO IDs** in `missing_compounds_founds_curated.xlsx` **should exist** in `kegglistko.txt`.

**Enforcement:** KO IDs without gene information are excluded during gene enrichment step.

**Verification:**
```r
# Check for unknown KO IDs
ko_list <- read.delim("input_data/kegglistko.txt")$ko
curated_ko <- read_excel("input_data/missing_compounds_founds_curated.xlsx")$ko
unknown_ko <- setdiff(curated_ko, ko_list)
if (length(unknown_ko) > 0) {
  warning("Unknown KO IDs: ", paste(unknown_ko, collapse = ", "))
}
```

---

#### Rule 3: Compound Classification Coverage

⚠️ **Not all compounds** in `compostos_todasagencias.xlsx` are required to have classifications in `confirm_class_CURATED.xlsx`.

**Behavior:** Unclassified compounds are **excluded** from final database.

**Recommendation:** Ensure all priority compounds have classifications.

---

### Identifier Format Validation

#### KEGG Compound IDs

**Valid formats:**

- `C#####` (e.g., `C00001`)
- Case-insensitive: `c00001` accepted (normalized to uppercase)

**Invalid formats:**

- `cpd:C00001` (prefix not required in input files)
- `C1`, `C00` (must be exactly 5 digits)

---

#### KEGG Orthology IDs

**Valid formats:**

- `K#####` (e.g., `K00001`)
- `ko:K#####` (prefix accepted, will be removed)
- Case-insensitive: `k00001` accepted (normalized to uppercase)

**Invalid formats:**

- `KO00001` (wrong prefix)
- `K1`, `K00` (must be exactly 5 digits)

---

## Common Input Issues and How to Avoid Them

### Issue 1: Excel File Corruption

**Symptom:** Pipeline crashes with "Error in read_excel: Cannot open file"

**Causes:**

- File opened in Excel during pipeline execution
- File corrupted due to improper save
- File in old Excel format (.xls instead of .xlsx)

**Solutions:**

- ✅ Close Excel before running pipeline
- ✅ Re-save file in Excel 2007+ format (.xlsx)
- ✅ Use "Save As" instead of "Save" if file shows corruption warnings

---

### Issue 2: Invisible Characters in Text Files

**Symptom:** KO IDs or enzyme terms not recognized despite appearing correct

**Causes:**

- Non-breaking spaces (U+00A0) instead of regular spaces
- Zero-width characters (U+200B, U+FEFF)
- Copy-paste from PDF introducing formatting artifacts

**Solutions:**

- ✅ Edit files in plain text editor (Notepad++, VS Code) not Word
- ✅ Use "Paste as Plain Text" when copying data
- ✅ Run cleanup script:

```r
# Remove invisible characters
clean_text <- function(x) {
  gsub("\\s+", " ", x)  # Normalize whitespace
  gsub("[\\u200B\\uFEFF]", "", x)  # Remove zero-width chars
}
```

---

### Issue 3: Missing Header Row

**Symptom:** First data row is treated as header, causing incorrect column interpretation

**Affected files:**

- `kegglistko.txt` **requires** header row
- `kegglistcompounds.xlsx` **does NOT** have header row
- `compostos_todasagencias.xlsx` **does NOT** have header row
- `missing_compounds_founds_curated.xlsx` **has** header row

**Solution:** Verify header presence matches file specification above

---

### Issue 4: Encoding Problems

**Symptom:** Compound names with special characters (Greek letters, subscripts) display as garbled text

**Cause:** File saved in wrong encoding (e.g., Windows-1252 instead of UTF-8)

**Solution:**

=== "Windows (Notepad++)"
    1. Open file in Notepad++
    2. Encoding → Convert to UTF-8
    3. Save file

=== "macOS (TextEdit)"
    1. Open file in TextEdit
    2. Format → Make Plain Text
    3. Save As → Plain Text Encoding: Unicode (UTF-8)

=== "Linux (iconv)"
    ```bash
    iconv -f WINDOWS-1252 -t UTF-8 input.txt > output.txt
    ```

---

### Issue 5: Extra Columns in Excel Files

**Symptom:** Pipeline reads invalid data from columns beyond expected schema

**Cause:** Extra columns (notes, metadata) added to Excel files for documentation

**Solution:**

- ✅ Remove extra columns before running pipeline
- ✅ Use separate "documentation" sheet in Excel workbook
- ✅ Ensure only required columns (A, B) contain data

---

### Issue 6: Inconsistent Agency Codes

**Symptom:** Compounds excluded from database despite being in agency list

**Cause:** Typo in agency code (e.g., "EAP" instead of "EPA")

**Solution:**

- ✅ Use standardized agency codes exactly as specified
- ✅ Validate agency codes before saving:

```r
valid_agencies <- c("ATSDR", "EPA", "IARC1", "IARC2A", "IARC2B", 
                    "PSL", "EPC", "WFD", "CONAMA")
agency_data <- read_excel("input_data/compostos_todasagencias.xlsx", col_names = FALSE)
invalid <- agency_data$...2[!agency_data$...2 %in% valid_agencies]
if (length(invalid) > 0) {
  stop("Invalid agency codes: ", paste(unique(invalid), collapse = ", "))
}
```

---

## Best Practices for Input Data Management

### Version Control

- ✅ **Track all input files** in Git/version control
- ✅ **Document changes** in commit messages
- ✅ **Tag releases** when input data is updated (e.g., `v1.1.0-data`)

### Data Provenance

- ✅ **Maintain external curation log** for `missing_compounds_founds_curated.xlsx`
- ✅ **Document agency database versions** (e.g., "EPA Priority Pollutant List, updated 2024-06-01")
- ✅ **Record KEGG release** used for `kegglistcompounds.xlsx` and `kegglistko.txt`

### Pipeline Configuration

- ✅ **Input directory paths** are defined in `config/config.yaml` (`paths.input_dir`) — update this if your directory layout differs from the default
- ✅ **Expected file list** is maintained in `workflow/lib/io_contracts.R` (`REQUIRED_INPUT_FILES`) — keep it in sync if you add or rename input files
- ✅ **Output** is written to `results/database/` by the Snakemake workflow

### Quality Assurance

- ✅ **Validate files** before committing changes
- ✅ **Run test pipeline** after modifying input data
- ✅ **Compare outputs** to previous versions to detect unexpected changes

---

## Questions?

**GitHub Issues:** [https://github.com/BioRemPP/biorempp_db/issues](https://github.com/BioRemPP/biorempp_db/issues)  
**Email:** biorempp@gmail.com
