# R and Python Integration

This document describes how BioRemPP Database outputs can be consumed and reused in R and Python data science environments.

---

## Purpose of R and Python Interoperability

BioRemPP Database provides **standardized outputs** compatible with both R and Python ecosystems, enabling:

- **Data access** — Load database into R/Python data structures
- **Identifier mapping** — Link to external databases via KEGG IDs
- **Downstream analysis** — Integrate with bioinformatics workflows
- **Cross-tool compatibility** — Use same data in multiple analysis environments

**Key principle:** Interoperability through **standard file formats** and **persistent identifiers**, not custom APIs or software packages.

---

## Supported Output Formats

### CSV Format (Primary)

**File:** `biorempp_database_v1.0.0.csv`

**Characteristics:**

- RFC 4180 compliant
- UTF-8 encoding
- Comma-delimited
- Header row with column names
- No missing values (100% completeness)

**Compatibility:**

- ✅ **R:** `read.csv()`, `readr::read_csv()`, `data.table::fread()`
- ✅ **Python:** `pandas.read_csv()`, `csv.reader()`
- ✅ **Universal:** Excel, LibreOffice, SQLite, PostgreSQL, etc.

---

### Excel Format (Alternative)

**File:** `biorempp_database_v1.0.0.xlsx`

**Characteristics:**

- Office Open XML format (ISO/IEC 29500)
- Single worksheet
- Same schema as CSV

**Compatibility:**

- ✅ **R:** `readxl::read_excel()`, `openxlsx::read.xlsx()`
- ✅ **Python:** `pandas.read_excel()`, `openpyxl`

**Recommendation:** Use CSV for programmatic access; Excel for manual inspection.

---

## Core Identifiers Exposed

BioRemPP outputs expose **persistent, resolvable identifiers** that enable cross-database integration:

### KEGG Compound IDs (`cpd`)

**Format:** `C#####` (e.g., `C06790`)

**Resolvable via:**
- KEGG API: `https://rest.kegg.jp/get/C06790`
- KEGG Web: `https://www.kegg.jp/entry/C06790`

**Cross-references available:**
- PubChem CID
- ChEBI ID
- CAS Registry Number
- InChI, InChIKey, SMILES

**R example:**
```r
library(KEGGREST)
compound_info <- keggGet("C06790")
```

**Python example:**
```python
import requests
url = "https://rest.kegg.jp/get/C06790"
response = requests.get(url)
compound_info = response.text
```

---

### KEGG Orthology IDs (`ko`)

**Format:** `K#####` (e.g., `K07408`)

**Resolvable via:**
- KEGG API: `https://rest.kegg.jp/get/K07408`
- KEGG Web: `https://www.kegg.jp/entry/K07408`

**Cross-references available:**
- EC numbers
- Gene symbols
- UniProt IDs (organism-specific)
- NCBI Gene IDs (organism-specific)

**R example:**
```r
library(KEGGREST)
ko_info <- keggGet("K07408")
```

**Python example:**
```python
import requests
url = "https://rest.kegg.jp/get/K07408"
response = requests.get(url)
ko_info = response.text
```

---

### Environmental Agency Codes (`referenceAG`)

**Format:** Standardized acronyms (e.g., `EPA`, `IARC1`)

**Valid codes:** `ATSDR`, `EPA`, `IARC1`, `IARC2A`, `IARC2B`, `PSL`, `EPC`, `WFD`, `CONAMA`

**Use case:** Filter compounds by regulatory priority

**R example:**
```r
epa_compounds <- db %>% filter(referenceAG == "EPA")
```

**Python example:**
```python
epa_compounds = db[db['referenceAG'] == 'EPA']
```

---

## Typical Reuse Scenarios

### Scenario 1: Load Database into R

```r
# Load database
library(readr)
db <- read_csv("biorempp_database_v1.0.0.csv")

# Inspect structure
str(db)
head(db)

# Summary statistics
summary(db)
```

**Expected output:**
- 10,869 rows × 8 columns
- 384 unique compounds
- 1,541 unique KO entries

---

### Scenario 2: Load Database into Python

```python
# Load database
import pandas as pd
db = pd.read_csv("biorempp_database_v1.0.0.csv")

# Inspect structure
print(db.info())
print(db.head())

# Summary statistics
print(db.describe())
```

**Expected output:**
- 10,869 rows × 8 columns
- 384 unique compounds
- 1,541 unique KO entries

---

### Scenario 3: Map to External Databases (R)

```r
library(dplyr)
library(KEGGREST)

# Get unique compounds
compounds <- unique(db$cpd)

# Fetch PubChem IDs via KEGG
pubchem_mapping <- lapply(compounds, function(cpd) {
  info <- keggGet(cpd)
  pubchem_id <- info[[1]]$DBLINKS$PubChem
  data.frame(cpd = cpd, pubchem_cid = pubchem_id)
})

pubchem_mapping <- bind_rows(pubchem_mapping)

# Merge with BioRemPP database
db_with_pubchem <- left_join(db, pubchem_mapping, by = "cpd")
```

---

### Scenario 4: Map to External Databases (Python)

```python
import pandas as pd
import requests

# Get unique compounds
compounds = db['cpd'].unique()

# Fetch PubChem IDs via KEGG
pubchem_mapping = []
for cpd in compounds:
    url = f"https://rest.kegg.jp/get/{cpd}"
    response = requests.get(url)
    # Parse response to extract PubChem ID (simplified)
    # Full implementation requires parsing KEGG entry format
    pubchem_mapping.append({'cpd': cpd, 'pubchem_cid': None})

pubchem_df = pd.DataFrame(pubchem_mapping)

# Merge with BioRemPP database
db_with_pubchem = db.merge(pubchem_df, on='cpd', how='left')
```

---

### Scenario 5: Filter by Compound Class (R)

```r
library(dplyr)

# Filter aromatic compounds
aromatic <- db %>% filter(compoundclass == "Aromatic")

# Count compounds per class
class_counts <- db %>%
  group_by(compoundclass) %>%
  summarise(
    n_entries = n(),
    n_compounds = n_distinct(cpd),
    n_ko = n_distinct(ko)
  )
```

---

### Scenario 6: Filter by Compound Class (Python)

```python
import pandas as pd

# Filter aromatic compounds
aromatic = db[db['compoundclass'] == 'Aromatic']

# Count compounds per class
class_counts = db.groupby('compoundclass').agg({
    'cpd': ['count', 'nunique'],
    'ko': 'nunique'
}).reset_index()

class_counts.columns = ['compoundclass', 'n_entries', 'n_compounds', 'n_ko']
```

---

### Scenario 7: Annotate Metagenomic Data (R)

```r
library(dplyr)

# Load metagenomic KO abundance table
metagenome <- read.csv("ko_abundance.csv")  # Columns: ko, abundance

# Annotate with BioRemPP data
annotated_metagenome <- metagenome %>%
  left_join(db, by = "ko") %>%
  filter(!is.na(cpd))  # Keep only KOs with bioremediation potential

# Summarize by compound class
class_abundance <- annotated_metagenome %>%
  group_by(compoundclass) %>%
  summarise(total_abundance = sum(abundance))
```

---

### Scenario 8: Annotate Metagenomic Data (Python)

```python
import pandas as pd

# Load metagenomic KO abundance table
metagenome = pd.read_csv("ko_abundance.csv")  # Columns: ko, abundance

# Annotate with BioRemPP data
annotated_metagenome = metagenome.merge(db, on='ko', how='left')
annotated_metagenome = annotated_metagenome.dropna(subset=['cpd'])

# Summarize by compound class
class_abundance = annotated_metagenome.groupby('compoundclass')['abundance'].sum()
```

---

## Data Integrity and Consistency Considerations

### Multi-Class Compound Representation

**Issue:** Compounds with multiple chemical classes appear in multiple rows.

**Impact:**
- Row count (10,869) ≠ unique compound count (384)
- Naive aggregation may double-count compounds

**Correct approach (R):**
```r
# INCORRECT: Count rows
nrow(db)  # 10,869 (inflated)

# CORRECT: Count unique compounds
length(unique(db$cpd))  # 384 (accurate)

# CORRECT: Unique compounds per class
db %>%
  group_by(compoundclass) %>%
  summarise(n_compounds = n_distinct(cpd))
```

**Correct approach (Python):**
```python
# INCORRECT: Count rows
len(db)  # 10,869 (inflated)

# CORRECT: Count unique compounds
db['cpd'].nunique()  # 384 (accurate)

# CORRECT: Unique compounds per class
db.groupby('compoundclass')['cpd'].nunique()
```

---

### Identifier Format Validation

**Best practice:** Validate KEGG IDs before external API queries.

**R validation:**
```r
library(stringr)

# Validate compound IDs
valid_cpd <- str_detect(db$cpd, "^C\\d{5}$")
all(valid_cpd)  # Should be TRUE

# Validate KO IDs
valid_ko <- str_detect(db$ko, "^K\\d{5}$")
all(valid_ko)  # Should be TRUE
```

**Python validation:**
```python
import re

# Validate compound IDs
valid_cpd = db['cpd'].str.match(r'^C\d{5}$')
valid_cpd.all()  # Should be True

# Validate KO IDs
valid_ko = db['ko'].str.match(r'^K\d{5}$')
valid_ko.all()  # Should be True
```

---

### Character Encoding

**Encoding:** UTF-8 (guaranteed)

**R best practice:**
```r
# Explicitly specify UTF-8
db <- read.csv("biorempp_database_v1.0.0.csv", encoding = "UTF-8")
```

**Python best practice:**
```python
# Explicitly specify UTF-8
db = pd.read_csv("biorempp_database_v1.0.0.csv", encoding='utf-8')
```

---

## Recommendations for Downstream Processing

### 1. Use Tidy Data Principles

**R (tidyverse):**
```r
library(dplyr)
library(tidyr)

# One row per compound-KO-class combination (already tidy)
# For analysis, may want to pivot or aggregate
```

**Python (pandas):**
```python
import pandas as pd

# Database is already in tidy format
# Use groupby, pivot_table, or melt as needed
```

---

### 2. Cache External API Queries

**Rationale:** KEGG API has rate limits; avoid redundant queries.

**R example:**
```r
library(memoise)

# Cache KEGG queries
keggGet_cached <- memoise(KEGGREST::keggGet)

# Use cached version
compound_info <- keggGet_cached("C06790")
```

**Python example:**
```python
import functools
import requests

@functools.lru_cache(maxsize=1000)
def kegg_get_cached(entry_id):
    url = f"https://rest.kegg.jp/get/{entry_id}"
    return requests.get(url).text

# Use cached version
compound_info = kegg_get_cached("C06790")
```

---

### 3. Use Relational Database for Large-Scale Integration

**Recommendation:** Load into SQLite, PostgreSQL, or MySQL for complex queries.

**R example (SQLite):**
```r
library(DBI)
library(RSQLite)

# Create SQLite database
con <- dbConnect(SQLite(), "biorempp.db")
dbWriteTable(con, "biorempp", db, overwrite = TRUE)

# Query with SQL
result <- dbGetQuery(con, "
  SELECT compoundclass, COUNT(DISTINCT cpd) as n_compounds
  FROM biorempp
  GROUP BY compoundclass
")

dbDisconnect(con)
```

**Python example (SQLite):**
```python
import sqlite3
import pandas as pd

# Create SQLite database
con = sqlite3.connect("biorempp.db")
db.to_sql("biorempp", con, if_exists='replace', index=False)

# Query with SQL
result = pd.read_sql_query("""
  SELECT compoundclass, COUNT(DISTINCT cpd) as n_compounds
  FROM biorempp
  GROUP BY compoundclass
""", con)

con.close()
```

---

### 4. Document Provenance in Derived Datasets

**Best practice:** Include BioRemPP version and KEGG release in metadata.

**R example:**
```r
# Add metadata to derived dataset
metadata <- list(
  source = "BioRemPP Database",
  version = "v1.0.0",
  kegg_release = "Dec,25",
  doi = "https://doi.org/10.5281/zenodo.[PLACEHOLDER]",
  date_accessed = Sys.Date()
)

# Save with metadata
saveRDS(list(data = derived_data, metadata = metadata), "derived_data.rds")
```

**Python example:**
```python
import json
from datetime import date

# Add metadata to derived dataset
metadata = {
    'source': 'BioRemPP Database',
    'version': 'v1.0.0',
    'kegg_release': 'Dec,25',
    'doi': 'https://doi.org/10.5281/zenodo.[PLACEHOLDER]',
    'date_accessed': str(date.today())
}

# Save with metadata
with open('metadata.json', 'w') as f:
    json.dump(metadata, f, indent=2)
```

---

## What BioRemPP Interoperability is NOT

❌ **Not a software package** — No installable R/Python libraries  
❌ **Not an API service** — No web service or REST endpoints  
❌ **Not a multi-omics pipeline** — No automated cross-omics integration  
❌ **Not organism-specific** — KO IDs are organism-independent  

**What it IS:**

✅ **Standardized data outputs** — CSV/Excel with persistent identifiers  
✅ **Identifier-based integration** — KEGG IDs enable cross-database mapping  
✅ **Ecosystem-agnostic** — Compatible with R, Python, SQL, Excel, etc.  

---

## Questions?

**GitHub Repository:** [https://github.com/BioRemPP/biorempp_db](https://github.com/BioRemPP/biorempp_db)  
**Email:** biorempp@gmail.com
