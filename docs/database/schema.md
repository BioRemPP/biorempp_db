# Database Schema

This document provides a formal specification of the BioRemPP Database schema.

---

## Overview

The BioRemPP Database uses a **flat, denormalized schema** optimized for analytical queries and data integration workflows. The schema consists of a single table with **8 columns** representing compound-gene-enzyme-agency relationships.

**Design rationale:**

- **Simplicity** — Single tidy table structure facilitates direct import into R, Python, and spreadsheet tools
- **Analytical optimization** — Denormalized design enables efficient filtering, grouping, and aggregation operations
- **Interoperability** — Standard CSV format ensures compatibility with bioinformatics pipelines
- **FAIR compliance** — Structured schema with controlled vocabularies supports findability and reusability

---

## Schema Definition

### Table: BioRemPP Database v1.0.0

**Primary format:** CSV (Comma-Separated Values)

**Alternative format:** Excel (.xlsx)

**Rows:** 10,869 (as of v1.0.0)

**Columns:** 8

**Character encoding:** UTF-8

**Field delimiter:** Comma (`,`)

**Text qualifier:** Double quote (`"`)

**Header row:** Yes (column names in first row)

---

## Column Specifications

| # | Column Name | Data Type | Nullable | Controlled Vocabulary | Example Value |
|---|-------------|-----------|----------|----------------------|---------------|
| 1 | `cpd` | Character | No | KEGG Compound ID | `C06790` |
| 2 | `compoundclass` | Character | No | Chemical classification | `Aromatic` |
| 3 | `ko` | Character | No | KEGG Orthology ID | `K07408` |
| 4 | `referenceAG` | Character | No | Agency code | `EPA` |
| 5 | `compoundname` | Character | No | KEGG standard name | `Trichloroethene` |
| 6 | `genesymbol` | Character | No | Standard gene symbol | `CYP2E1` |
| 7 | `genename` | Character | No | KEGG gene annotation | `cytochrome P450` |
| 8 | `enzyme_activity` | Character | No | Enzyme activity term | `monooxygenase` |

**Data completeness:** 100% — Zero missing values across all fields

---

## Column 1: `cpd`

**Column name:** `cpd`

**Data type:** Character (string)

**Format:** KEGG Compound identifier

**Pattern:** `C#####` (capital C followed by exactly 5 digits)

**Example:** `C00001`, `C06790`, `C18254`

**Controlled vocabulary:** Yes — Values must exist in KEGG Compound database

**Uniqueness:** Not unique — Compounds may appear in multiple rows (associated with different genes, enzymes, or agencies)

**Purpose:** Uniquely identifies chemical compounds of environmental interest

**Cross-references:**

- KEGG Compound database: `https://www.kegg.jp/entry/C#####`
- KEGG Pathway maps
- PubChem, ChEBI, CAS Registry (via KEGG cross-references)

**Validation rules:**

- ✅ Must match regex: `^C\d{5}$`
- ✅ Must exist in KEGG Compound database
- ✅ Case-sensitive (uppercase C required)

**Cardinality:** 384 unique compounds in v1.0.0

---

## Column 2: `compoundclass`

**Column name:** `compoundclass`

**Data type:** Character (string)

**Format:** Free text (standardized categories)

**Example:** `Aromatic`, `Chlorinated`, `Polyaromatic`

**Controlled vocabulary:** Partially — 12 standardized classes used

**Uniqueness:** Not unique — Multiple compounds share the same class

**Purpose:** Classifies compounds by chemical structural features for filtering and analysis

**Standardized classes:**

| Class | Description | Compounds | Example Compounds |
|-------|-------------|-----------|-------------------|
| `Aromatic` | Benzene ring-containing compounds | 123 | Benzene, Toluene, Phenol |
| `Chlorinated` | Halogenated with chlorine | 117 | Trichloroethene, PCBs, Chloroform |
| `Nitrogen-containing` | Nitrogen functional groups | 115 | Nitrobenzene, Aniline, Ammonia |
| `Polyaromatic` | Multiple fused aromatic rings (PAHs) | 98 | Naphthalene, Anthracene, Benzo[a]pyrene |
| `Aliphatic` | Straight-chain or branched hydrocarbons | 94 | Hexane, Propane, Butane |
| `Metal` | Metal-containing compounds | 29 | Cadmium chloride, Lead compounds |
| `Inorganic` | Inorganic compounds | 26 | Ammonia, Sulfates, Nitrates |
| `Sulfur-containing` | Sulfur functional groups | 20 | Thiols, Sulfides, Sulfoxides |
| `Organophosphorus` | Phosphorus-containing organic compounds | 13 | Parathion, Chlorpyrifos, Malathion |
| `Organometallic` | Metal-carbon bonds | 9 | Methylmercury chloride, Organotins |
| `Halogenated` | Halogenated compounds (general) | 8 | Brominated, Fluorinated compounds |
| `Organosulfur` | Organic sulfur compounds | 1 | Dimethyl sulfoxide |

**Multi-class compounds:** Some compounds belong to multiple classes (e.g., both `Aromatic` and `Chlorinated`). Each classification appears as a separate row.

**Validation rules:**

- ✅ Must be non-empty string
- ✅ Should match one of 12 standardized classes (enforced during curation)

**Cardinality:** 12 unique classes in v1.0.0

---

## Column 3: `ko`

**Column name:** `ko`

**Data type:** Character (string)

**Format:** KEGG Orthology identifier

**Pattern:** `K#####` (capital K followed by exactly 5 digits)

**Example:** `K00001`, `K07408`, `K18254`

**Controlled vocabulary:** Yes — Values must exist in KEGG Orthology database

**Uniqueness:** Not unique — KO groups may appear in multiple rows (associated with different compounds or agencies)

**Purpose:** Identifies functional gene groups (ortholog clusters) representing enzymatic or functional roles abstracted across organisms

**Cross-references:**

- KEGG Orthology database: `https://www.kegg.jp/entry/K#####`
- KEGG Pathway maps
- KEGG Module definitions
- UniProt, NCBI Gene (organism-specific mappings)

**Validation rules:**

- ✅ Must match regex: `^K\d{5}$`
- ✅ Must exist in KEGG Orthology database
- ✅ Case-sensitive (uppercase K required)

**Cardinality:** 1,541 unique KO entries in v1.0.0

---

## Column 4: `referenceAG`

**Column name:** `referenceAG`

**Data type:** Character (string)

**Format:** Agency code (uppercase)

**Example:** `EPA`, `IARC1`, `ATSDR`

**Controlled vocabulary:** Yes — Exactly 9 valid agency codes

**Uniqueness:** Not unique — Multiple compounds are listed by the same agency

**Purpose:** Indicates which environmental regulatory authority has classified the compound as a priority pollutant or contaminant of concern

**Valid agency codes:**

| Code | Full Name | Jurisdiction | Focus |
|------|-----------|--------------|-------|
| `ATSDR` | Agency for Toxic Substances and Disease Registry | USA | Public health hazards |
| `EPA` | U.S. Environmental Protection Agency | USA | Priority pollutants |
| `IARC1` | IARC Group 1 | International | Carcinogenic to humans |
| `IARC2A` | IARC Group 2A | International | Probably carcinogenic |
| `IARC2B` | IARC Group 2B | International | Possibly carcinogenic |
| `PSL` | Priority Substances List | Canada | Canadian priority chemicals |
| `EPC` | Environmental Priority Chemicals | Europe | EU priority substances |
| `WFD` | Water Framework Directive | EU | Water quality standards |
| `CONAMA` | Conselho Nacional do Meio Ambiente | Brazil | Brazilian environmental regulations |

**Validation rules:**

- ✅ Must be non-empty string
- ✅ Must match one of 9 valid agency codes exactly (case-sensitive)

**Cardinality:** 9 unique agencies in v1.0.0

---

## Column 5: `compoundname`

**Column name:** `compoundname`

**Data type:** Character (string)

**Format:** Free text (KEGG standard nomenclature)

**Example:** `Trichloroethene`, `Benzene`, `Naphthalene`

**Controlled vocabulary:** No — Free text, but sourced from KEGG

**Uniqueness:** Quasi-unique — 384 unique names corresponding to 384 unique compounds (one name per compound)

**Purpose:** Provides human-readable common name or IUPAC name for the compound

**Naming conventions:**

- Primary KEGG compound name only (synonyms removed)
- May contain special characters (Greek letters, numbers, parentheses)
- IUPAC names preferred when available
- Common names used when IUPAC is excessively long

**Validation rules:**

- ✅ Must be non-empty string
- ✅ Should correspond to Compound ID via KEGG database

**Cardinality:** 384 unique names in v1.0.0

---

## Column 6: `genesymbol`

**Column name:** `genesymbol`

**Data type:** Character (string)

**Format:** Standard gene nomenclature (free text)

**Example:** `CYP2E1`, `dmpN`, `nahAc`

**Controlled vocabulary:** No — Free text, but sourced from KEGG KO annotations

**Uniqueness:** Not unique — Multiple KO groups may share the same gene symbol (isoforms/variants)

**Purpose:** Provides short, standardized gene abbreviation for the associated KO group

**Naming conventions:**

- HUGO nomenclature for human genes (e.g., `CYP2E1`)
- Organism-specific symbols for microbial genes (e.g., `dmpN`)
- May contain commas for KO groups with multiple gene symbols

**Validation rules:**

- ✅ Must be non-empty string
- ✅ Should be extracted from KEGG KO annotation

**Cardinality:** 1,515 unique gene symbols in v1.0.0

---

## Column 7: `genename`

**Column name:** `genename`

**Data type:** Character (string)

**Format:** Free text (KEGG functional description)

**Example:** `cytochrome P450 family 2 subfamily E polypeptide 1`, `dioxygenase`

**Controlled vocabulary:** No — Free text, sourced from KEGG

**Uniqueness:** Quasi-unique — 1,541 unique gene names (one per KO group)

**Purpose:** Provides expanded functional description of the gene, including enzyme class or biochemical role

**Content:**

- Full protein/enzyme name
- May include EC numbers in brackets: `[EC:X.X.X.X]`
- Variable length (from single words to full protein names)

**Validation rules:**

- ✅ Must be non-empty string
- ✅ Should correspond to KO ID via KEGG database

**Cardinality:** 1,541 unique gene names in v1.0.0

---

## Column 8: `enzyme_activity`

**Column name:** `enzyme_activity`

**Data type:** Character (string)

**Format:** Controlled vocabulary (standardized enzyme terms)

**Example:** `cytochrome P450`, `dioxygenase`, `monooxygenase`

**Controlled vocabulary:** Yes — 210+ standardized enzyme activity terms

**Uniqueness:** Not unique — Multiple genes share the same enzyme activity type

**Purpose:** Provides simplified, standardized enzyme classification extracted from `genename` via pattern matching

**Extraction method:** Pattern matching against curated enzyme lexicon (`enzymes_unique.txt`)

**Top enzyme families:**

| Enzyme Family | Entries | Example Genes |
|--------------|---------|---------------|
| `cytochrome P450` | 2,166 | CYP2E1, CYP1A1 |
| `dioxygenase` | 1,093 | catechol dioxygenase |
| `monooxygenase` | 872 | methane monooxygenase |
| `dehydrogenase` | 822 | alcohol dehydrogenase |
| `reductase` | 438 | nitrate reductase |

**Validation rules:**

- ✅ Must be non-empty string
- ✅ Should match one of 210 standardized terms (verified during pipeline execution)
- ✅ Fallback to `genename` if no enzyme term matches

**Cardinality:** 205 unique enzyme activities in v1.0.0

---

## Schema Constraints and Relationships

### Primary Key

**None defined** — Database uses a flat structure without explicit primary key

**Conceptual primary key:** Combination of (`cpd`, `ko`, `referenceAG`) approximates uniqueness, but is not enforced

**Duplicate rows:** Minimal — Same compound-KO pair may appear under multiple agencies

---

### Foreign Key Relationships

**Conceptual foreign keys (not enforced):**

- `cpd` → KEGG Compound database
- `ko` → KEGG Orthology database

**Cross-table joins:**

Users can join BioRemPP Database with external resources:

- **KEGG Compound** — via `cpd` column
- **KEGG Orthology** — via `ko` column
- **KEGG Pathway** — via `cpd` or `ko` (requires additional mapping)
- **UniProt** — via `genesymbol` or `ko` (organism-specific)

---

### Cardinality Relationships

#### Compound-to-KO

**Many-to-Many** — One compound can be degraded by multiple genes (KO groups), and one KO group can act on multiple compounds

**Example:**

- Trichloroethene (C06790) → 37 unique KO groups
- Cytochrome P450 KO → 35 unique compounds

#### Compound-to-Agency

**Many-to-Many** — One compound can be listed by multiple agencies, and one agency lists multiple compounds

**Example:**

- Benzene (C00180) → 5 agencies (EPA, IARC1, ATSDR, PSL, WFD)
- EPA → 83 unique compounds

#### KO-to-Enzyme

**Many-to-One** — Multiple KO groups may share the same enzyme activity classification

**Example:**

- 43 unique KO groups → `cytochrome P450` enzyme activity

---

## Data Quality Specifications

### Completeness

**100% field completeness** — Zero missing values (`NA`, `NULL`, empty strings) across all 8 columns

**Verification:**

```r
db <- read.csv("biorempp_database_v1.0.0.csv")
colSums(is.na(db))  # Should return all zeros
```

---

### Consistency

**Identifier format consistency:**

- All `cpd` values match `^C\d{5}$`
- All `ko` values match `^K\d{5}$`
- All `referenceAG` values match one of 9 valid codes

**Verification:**

```r
# Verify compound ID format
all(grepl("^C\\d{5}$", db$cpd))  # Should return TRUE

# Verify KO ID format
all(grepl("^K\\d{5}$", db$ko))  # Should return TRUE

# Verify agency codes
valid_agencies <- c("ATSDR", "EPA", "IARC1", "IARC2A", "IARC2B", 
                    "PSL", "EPC", "WFD", "CONAMA")
all(db$referenceAG %in% valid_agencies)  # Should return TRUE
```

---

### Accuracy

**Data provenance:**

- `cpd`, `compoundname` — Sourced from KEGG Compound database
- `ko`, `genesymbol`, `genename` — Sourced from KEGG Orthology database
- `compoundclass` — Manual expert curation
- `referenceAG` — Manual compilation from agency databases
- `enzyme_activity` — Automated extraction with manual validation

**Validation against KEGG:** All KEGG identifiers are valid as of KEGG Release Dec,23

---

## Schema Evolution

### Version History

| Version | Release Date | Total Rows | Changes |
|---------|--------------|------------|---------|
| **v1.0.0** | December 2025 | 10,869 | Initial release |

**Future versions** may include:

- Additional environmental agencies
- Expanded compound coverage
- New enzyme activity terms
- Organism-specific annotations

---

### Backward Compatibility

**Schema stability:** Column names and data types are **stable** and will not change in minor version updates (v1.x.x)

**Breaking changes** (requiring major version update, v2.0.0):

- Adding or removing columns
- Changing column data types
- Modifying controlled vocabulary codes

**Non-breaking changes** (allowed in minor updates, v1.x.x):

- Adding new rows (compounds, KO groups)
- Expanding controlled vocabulary (new enzyme terms)
- Updating KEGG references

---

## Usage Examples

### Loading the Database

=== "R"

    ```r
    # Load database
    library(readr)
    db <- read_csv("biorempp_database_v1.0.0.csv")
    
    # Inspect schema
    str(db)
    # tibble [10,869 × 8] (S3: spec_tbl_df/tbl_df/tbl/data.frame)
    #  $ cpd            : chr  "C00014" "C00014" "C00014" ...
    #  $ compoundclass  : chr  "Aliphatic" "Aliphatic" "Aliphatic" ...
    #  $ ko             : chr  "K00261" "K00262" "K00263" ...
    #  $ referenceAG    : chr  "EPA" "EPA" "EPA" ...
    #  $ compoundname   : chr  "Ammonia" "Ammonia" "Ammonia" ...
    #  $ genesymbol     : chr  "nifH" "nifD" "nifK" ...
    #  $ genename       : chr  "nitrogenase ..." "nitrogenase ..." ...
    #  $ enzyme_activity: chr  "nitrogenase" "nitrogenase" ...
    ```

=== "Python"

    ```python
    import pandas as pd
    
    # Load database
    db = pd.read_csv("biorempp_database_v1.0.0.csv")
   
    # Inspect schema
    db.info()
    # <class 'pandas.core.frame.DataFrame'>
    # RangeIndex: 10869 entries, 0 to 10868
    # Data columns (total 8 columns):
    #  #   Column           Non-Null Count  Dtype 
    # ---  ------           --------------  ----- 
    #  0   cpd              10869 non-null  object
    #  1   compoundclass    10869 non-null  object
    #  2   ko               10869 non-null  object
    #  3   referenceAG      10869 non-null  object
    #  4   compoundname     10869 non-null  object
    #  5   genesymbol       10869 non-null  object
    #  6   genename         10869 non-null  object
    #  7   enzyme_activity  10869 non-null  object
    ```

---

### Schema Validation

```r
# Function to validate database schema
validate_schema <- function(db) {
  checks <- list(
    "8 columns" = ncol(db) == 8,
    "10,869 rows" = nrow(db) == 10869,
    "No missing values" = sum(is.na(db)) == 0,
    "Valid cpd format" = all(grepl("^C\\d{5}$", db$cpd)),
    "Valid ko format" = all(grepl("^K\\d{5}$", db$ko)),
    "Valid agencies" = all(db$referenceAG %in% 
      c("ATSDR", "EPA", "IARC1", "IARC2A", "IARC2B", 
        "PSL", "EPC", "WFD", "CONAMA"))
  )
  
  passed <- sum(unlist(checks))
  total <- length(checks)
  
  cat(sprintf("Schema validation: %d/%d checks passed\n", passed, total))
  
  for (name in names(checks)) {
    status <- ifelse(checks[[name]], "✓", "✗")
    cat(sprintf("  %s %s\n", status, name))
  }
  
  return(all(unlist(checks)))
}

# Run validation
validate_schema(db)
```

---

## Questions?

**GitHub Issues:** [https://github.com/BioRemPP/biorempp_db/issues](https://github.com/BioRemPP/biorempp_db/issues)  
**Email:** biorempp@gmail.com
