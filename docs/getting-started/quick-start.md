# Quick Start Guide

Get started with BioRemPP Database in under 5 minutes.

---

## Objective

This guide demonstrates a complete end-to-end execution of the BioRemPP Database generation pipeline, from cloning the repository to examining the output files. By the end of this quick start, you will have:

- Cloned the BioRemPP Database repository
- Executed the database generation pipeline
- Generated the complete database (10,869 entries)
- Validated the output files
- Explored basic database statistics

**Estimated time:** 5 minutes

---

## Prerequisites

Before starting, ensure you have:

- ✅ **R** ≥ 4.0.0 installed ([verify](requirements.md#check-r-version))
- ✅ **6 R packages** installed: `readxl`, `dplyr`, `tidyr`, `stringr`, `readr`, `xlsx` ([install](installation.md#step-4-install-r-package-dependencies))
- ✅ **Internet connection** for KEGG API access
- ✅ **Git** installed (optional, needed only for cloning)

If prerequisites are not met, see [Installation Guide](installation.md).

---

## Step-by-Step Execution

### Step 1: Clone the Repository

Open a terminal (macOS/Linux) or PowerShell/Command Prompt (Windows):

=== "Command Line (Git)"

    ```bash
    # Clone repository
    git clone https://github.com/BioRemPP/biorempp_db.git
    
    # Navigate to project root directory
    cd biorempp_db
    ```

=== "Manual Download (No Git)"

    1. Visit [GitHub Repository](https://github.com/BioRemPP/biorempp_db)
    2. Click **Code** → **Download ZIP**
    3. Extract ZIP file
    4. Open terminal and navigate to extracted folder:
       ```bash
       cd path/to/biorempp_db
       ```

**Expected result:** You are now in the project root directory.

---

### Step 2: Verify Input Data

Confirm that all required input files are present:

```bash
ls -lh input_data/
```

**Expected output:**

```
-rw-r--r-- 1 user group  17K  Dec 16 12:00 confirm_class_CURATED.xlsx
-rw-r--r-- 1 user group  30K  Dec 16 12:00 compostos_todasagencias.xlsx
-rw-r--r-- 1 user group 3.3K  Dec 16 12:00 enzymes_unique.txt
-rw-r--r-- 1 user group 425K  Dec 16 12:00 kegglistcompounds.xlsx
-rw-r--r-- 1 user group 1.6M  Dec 16 12:00 kegglistko.txt
-rw-r--r-- 1 user group  38K  Dec 16 12:00 missing_compounds_founds_curated.xlsx
```

✅ **Checkpoint:** All 6 files should be present (~2.2 MB total)

---

### Step 3: Run the Database Generation Pipeline

=== "Option A: RStudio (Recommended)"

    1. **Open RStudio**
    2. **File** → **Open File...** → Select `generate_database.R`
    3. **Click "Source"** (or press `Ctrl+Shift+S` / `Cmd+Shift+S`)
    4. **Wait 5 minutes** while pipeline executes

=== "Option B: R Console"

    ```r
    # Launch R from terminal
    R
    
    # Set working directory to project root
    setwd("path/to/project/root")
    
    # Run pipeline
    source("generate_database.R")
    
    # Wait for completion
    ```

=== "Option C: Command Line (Non-interactive)"

    ```bash
    # Execute pipeline directly
    Rscript generate_database.R
    ```

**What happens during execution:**

```
================================================================================
  BioRemPP Database Generator v1.0.0
================================================================================

=== STEP 1: Loading Local Data Files ===
✓ Loaded 18639 KEGG compounds from local file
✓ Loaded 806 compounds from environmental agencies
✓ Loaded 62 manually curated compounds
✓ Loaded compound classifications for 384 compounds
✓ Loaded 47421 KO entries from local file
✓ Loaded 210 unique enzyme terms

=== STEP 2: Fetching Data from KEGG API ===
✓ Fetched data from KEGG API: link/ko/ec
✓ Fetched data from KEGG API: link/ko/reaction
✓ Fetched data from KEGG API: link/compound/ec
✓ Fetched data from KEGG API: link/cpd/reaction
✓ Fetched data from KEGG API: list/cpd/

=== STEP 3: Merging and Integrating Data ===
✓ Created 120543 unique KO-compound relationships
✓ Integrated 868 compound-KO relationships

=== STEP 4: Adding Compound Classifications ===
✓ Created 868 compound-class relationships
✓ Classified 868 compound entries

=== STEP 5: Sanitizing KO IDs and Adding Gene Information ===
✓ Sanitized 868 KO identifiers
✓ Prepared 22615 unique KO entries
✓ Added gene information to 10869 entries
⚠ Entries without gene match: 0

=== STEP 6: Extracting Enzyme Activities ===
✓ Built pattern with 210 enzyme terms
✓ Extracted enzyme activities for 10869 entries
✓ Cleaned gene annotations

=== STEP 7: Saving Results ===
✓ Saved database to: output_data/biorempp_database_v1.0.0.csv
✓ Saved database to: output_data/biorempp_database_v1.0.0.xlsx

================================================================================
  Database Generation Complete!
================================================================================

Summary Statistics:
  - Total entries: 10869
  - Unique compounds: 384
  - Unique KO entries: 1541
  - Unique compound classes: 12
  - Unique gene symbols: 1515
  - Unique enzyme activities: 205

Output files:
  - output_data/biorempp_database_v1.0.0.csv
  - output_data/biorempp_database_v1.0.0.xlsx
```

**Estimated runtime:** 5 minutes

---

### Step 4: Verify Output Files

Check that database files were generated successfully:

```bash
ls -lh output_data/
```

**Expected output:**

```
-rw-r--r-- 1 user group 1.3M  Dec 16 12:05 biorempp_database_v1.0.0.csv
-rw-r--r-- 1 user group 460K  Dec 16 12:05 biorempp_database_v1.0.0.xlsx
```

✅ **Checkpoint:** Both files should exist with sizes matching above

---

### Step 5: Explore the Database

Load the database into R for quick exploration:

```r
# Load database
db <- read.csv("output_data/biorempp_database_v1.0.0.csv")

# Quick inspection
dim(db)
# Expected: [1] 10869     8

colnames(db)
# Expected: [1] "cpd" "compoundclass" "ko" "referenceAG" "compoundname" 
#           [6] "genesymbol" "genename" "enzyme_activity"

# View first 10 entries
head(db, 10)

# Summary statistics
summary(db)
```

**Example output:**

```r
> dim(db)
[1] 10869     8

> head(db, 3)
     cpd compoundclass      ko referenceAG       compoundname genesymbol
1 C00014    Aliphatic K00261          EPA           Ammonia      nifH
2 C00014    Aliphatic K00262          EPA           Ammonia      nifD
3 C00014    Aliphatic K00263          EPA           Ammonia      nifK

                        genename enzyme_activity
1 nitrogenase molybdenum-iron     nitrogenase
2 nitrogenase molybdenum-iron     nitrogenase
3 nitrogenase molybdenum-iron     nitrogenase
```

---

## Expected Outputs

### Generated Files

| File | Location | Size | Rows | Columns |
|------|----------|------|------|---------|
| **Main Database (CSV)** | `output_data/biorempp_database_v1.0.0.csv` | ~1.3 MB | 10,869 | 8 |
| **Main Database (Excel)** | `output_data/biorempp_database_v1.0.0.xlsx` | ~460 KB | 10,869 | 8 |

### Database Schema

| Column | Type | Example | Description |
|--------|------|---------|-------------|
| `cpd` | Character | `C00014` | KEGG compound identifier |
| `compoundclass` | Character | `Aliphatic` | Chemical classification |
| `ko` | Character | `K00261` | KEGG Orthology identifier |
| `referenceAG` | Character | `EPA` | Environmental agency code |
| `compoundname` | Character | `Ammonia` | Common compound name |
| `genesymbol` | Character | `nifH` | Standard gene symbol |
| `genename` | Character | `nitrogenase molybdenum-iron` | Full gene name |
| `enzyme_activity` | Character | `nitrogenase` | Extracted enzyme activity |

---

## Basic Sanity Checks

Verify the database integrity:

### Check 1: Row Count

```r
nrow(db)
# Expected: 10869
```

✅ **Pass:** Exactly 10,869 rows

---

### Check 2: Data Completeness

```r
# Check for missing values
colSums(is.na(db))
# Expected: All zeros (100% completeness)
```

✅ **Pass:** Zero missing values across all columns

---

### Check 3: Unique Counts

```r
# Count unique values
sapply(db, function(x) length(unique(x)))

# Expected:
#              cpd compoundclass            ko   referenceAG 
#              384            12          1541             9 
#     compoundname    genesymbol      genename enzyme_activity 
#              384          1515          1541           205
```

✅ **Pass:** Counts match expected database statistics

---

### Check 4: KEGG Identifier Format

```r
# Verify compound IDs follow C##### format
all(grepl("^C\\d{5}$", db$cpd))
# Expected: TRUE

# Verify KO IDs follow K##### format
all(grepl("^K\\d{5}$", db$ko))
# Expected: TRUE
```

✅ **Pass:** All identifiers conform to KEGG standards

---

### Check 5: Top Enzymes

```r
# Most frequent enzyme activities
head(table(db$enzyme_activity), 10)

# Expected:
# cytochrome P450  dioxygenase  monooxygenase  dehydrogenase
#           2166         1093            872            822
```

✅ **Pass:** Top enzyme families match expected distribution

---

## Next Steps

### Explore the Data

Now that you have generated the database, you can:

1. **Analyze specific compounds**
   ```r
   # Find all entries for trichloroethene
   db[db$compound name == "Trichloroethene", ]
   ```

2. **Filter by enzyme type**
   ```r
   # Find all dioxygenases
   db[db$enzyme_activity == "dioxygenase", ]
   ```

3. **Cross-reference regulatory agencies**
   ```r
   # Compounds in EPA list
   db[db$referenceAG == "EPA", ]
   ```

### Run Statistical Analysis

Generate comprehensive statistics (optional):

```bash
cd analysis
Rscript analyze_database.R
```

This creates 9 JSON files in `analysis/output/` with detailed statistics.

See: [Understanding Output](../user-guide/understanding-output.md)

---


## Troubleshooting

### Pipeline fails at KEGG API step

**Solution:** Check internet connectivity and retry. See [Common Installation Issues](installation.md#issue-3-kegg-api-connection-timeout).

---

### Output files not created

**Solution:** Verify write permissions for `output_data/` directory. See [Permission Issues](installation.md#issue-4-permission-denied-when-creating-output-files).

---

### Different row count than expected

**Possible causes:**

- Updated KEGG data (database evolves over time)
- Modified input files
- Incomplete API responses

**Solution:** Re-run pipeline or consult [Known Limitations](../validation/limitations.md).

---

## Questions?

**GitHub Issues:** [https://github.com/BioRemPP/biorempp_db/issues](https://github.com/BioRemPP/biorempp_db/issues)  
**Email:** biorempp@gmail.com
