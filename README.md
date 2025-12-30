# BioRemPP Database Generator v1.0.0

## Overview

This is the production-ready version of the BioRemPP database generation pipeline. It integrates data from KEGG API, environmental agency compound lists, manual curations, compound classifications, and enzyme activity extraction to create a comprehensive biological remediation database.

## Directory Structure

```
./ (project root)
├── generate_database.R        # Main script
├── input_data/                 # Required input files
│   ├── kegglistcompounds.xlsx
│   ├── compostos_todasagencias.xlsx
│   ├── missing_compounds_founds_curated.xlsx
│   ├── confirm_class_CURATED.xlsx
│   ├── kegglistko.txt
│   └── enzymes_unique.txt
├── output_data/                # Generated output files
│   ├── biorempp_database_v1.0.0.csv
│   └── biorempp_database_v1.0.0.xlsx
├── analysis/                   # Analysis scripts and results
└── README.md                   # This file
```

## Requirements

### R Version
- R >= 4.0.0 recommended

### Required R Packages

Install all required packages with:

```r
install.packages(c("readxl", "dplyr", "tidyr", "stringr", "readr", "xlsx"))
```

**Package Descriptions**:
- `readxl` - Reading Excel (.xlsx) files
- `dplyr` - Data manipulation and transformation
- `tidyr` - Data tidying (e.g., separate_rows)
- `stringr` - String manipulation and regex operations
- `readr` - Reading text files
- `xlsx` - Writing Excel files


## Input Data Files

### 1. `kegglistcompounds.xlsx`
- **Source**: KEGG database
- **Content**: Reference list of KEGG compounds
- **Columns**: `cpd` (compound ID), `compoundname`

### 2. `compostos_todasagencias.xlsx`
- **Source**: 9 environmental agencies
- **Content**: Compounds of interest for bioremediation
- **Columns**: `cpd` (compound ID), `referenceAG` (agency reference)

### 3. `missing_compounds_founds_curated.xlsx`
- **Source**: Manual curation
- **Content**: Compounds manually curated to fill gaps
- **Columns**: `cpd` (compound ID), `ko` (KEGG Orthology ID)

### 4. `confirm_class_CURATED.xlsx`
- **Source**: Manual curation
- **Content**: Compound class annotations
- **Columns**: `cpd` (compound ID), `compoundclass` (chemical class)

### 5. `kegglistko.txt`
- **Source**: KEGG database (pre-downloaded)
- **Content**: KO list with gene symbols and names
- **Columns**: `ko`, `genesymbol`, `genename`

### 6. `enzymes_unique.txt`
- **Source**: Manual extraction from enzyme activity data
- **Content**: List of unique enzyme activity terms (one per line)
- **Purpose**: Pattern matching for enzyme activity extraction

## How to Run

### Option 1: RStudio (Recommended)

1. Open RStudio
2. Open `generate_database.R`
3. Click "Source" or press `Ctrl+Shift+S` (Windows/Linux) or `Cmd+Shift+S` (Mac)

The script will automatically set the working directory to its location.

### Option 2: R Console

```r
# Navigate to project root directory
setwd("path/to/project/root")

# Run script
source("generate_database.R")
```

### Option 3: Command Line

```bash
cd "path/to/project/root"
Rscript generate_database.R
```

## Processing Pipeline

The script executes the following steps:

### Step 1: Load Local Data Files
- Loads all Excel files, text files, and enzyme terms
- Validates data integrity

### Step 2: Fetch Data from KEGG API
- **KO Links**: KO-EC and KO-Reaction relationships
- **Compound Links**: Compound-EC and Compound-Reaction relationships
- **Compound List**: Complete compound names
- **KO List**: Gene symbols and names (also loaded from local file)

### Step 3: Merge and Integrate Data
- Combines KO-compound relationships from EC and Reaction pathways
- Integrates agency compounds with KEGG data
- Adds manually curated compounds
- Enriches with compound names

### Step 4: Add Compound Classifications
- Transforms compound class data to tidy format (one row per class)
- Merges classifications with compound data

### Step 5: Sanitize and Enrich with Gene Information
- Cleans KO identifiers to standard K##### format
- Prepares KEGG reference data (deduplication)
- Adds gene symbols and names to compound data
- Filters out entries without valid gene information

### Step 6: Extract Enzyme Activities
- Builds regex pattern from enzyme terms
- Extracts enzyme activity from gene names
- Cleans gene names (removes EC numbers)
- Cleans gene symbols (removes comma-separated alternatives)

### Step 7: Save Results
- Saves final database to CSV format
- Saves final database to Excel format (optional)
- Displays summary statistics

## Output

### Files Generated

1. **`biorempp_database_v1.0.0.csv`** - Main output in CSV format
2. **`biorempp_database_v1.0.0.xlsx`** - Main output in Excel format (optional)

### Output Columns

- `cpd` - KEGG compound ID
- `compoundclass` - Chemical class of compound
- `ko` - KEGG Orthology ID (standardized to K##### format)
- `referenceAG` - Reference environmental agency
- `compoundname` - Compound name
- `genesymbol` - Gene symbol
- `genename` - Gene name (cleaned, without EC numbers)
- `enzyme_activity` - Extracted enzyme activity term

### Example Output Row

```csv
cpd,compoundclass,ko,referenceAG,compoundname,genesymbol,genename,enzyme_activity
C00001,Inorganic,K00001,EPA,Water,ADH1,alcohol dehydrogenase,dehydrogenase
```

## Script Architecture

### Modular Functions (30+)

**Environment Setup (2)**:
- `set_working_directory_to_script()` - Auto-detect and set working directory
- `load_required_packages()` - Load and validate R packages

**Utility Functions (1)**:
- `get_script_directory()` - Get script location

**Data Loading Functions (6)**:
- `load_kegg_compounds_local()` - Load local KEGG compounds
- `load_agency_compounds()` - Load agency compound data
- `load_curated_compounds()` - Load manual curations
- `load_compound_classifications()` - Load compound classifications
- `load_kegg_ko_list()` - Load KO list from local file
- `load_enzyme_terms()` - Load enzyme terminology

**API Functions (6)**:
- `fetch_kegg_api()` - Generic KEGG API caller
- `fetch_ko_ec_links()` - Fetch KO-EC links
- `fetch_ko_reaction_links()` - Fetch KO-Reaction links
- `fetch_compound_ec_links()` - Fetch Compound-EC links
- `fetch_compound_reaction_links()` - Fetch Compound-Reaction links
- `fetch_compound_list()` - Fetch compound list with names

**Transformation Functions (11)**:
- `merge_ko_compound_relationships()` - Combine KO-compound relationships
- `integrate_compound_sources()` - Integrate agency and curated data
- `add_compound_names()` - Enrich with compound names
- `tidy_compound_classifications()` - Transform to tidy format
- `add_compound_classifications()` - Add compound classifications
- `sanitize_ko_identifiers()` - Clean and standardize KO IDs
- `prepare_kegg_reference()` - Clean and deduplicate KO list
- `add_gene_information()` - Enrich with gene data
- `build_enzyme_pattern()` - Create regex pattern
- `extract_enzyme_activities()` - Extract enzyme terms
- `clean_gene_annotations()` - Clean gene names and symbols

**Main Pipeline (1)**:
- `main_pipeline()` - Orchestrates entire process

## Error Handling

### Input Validation
- Checks enzyme terms file exists
- Validates package installation

### API Error Handling
- Uses `try()` for API calls
- Provides warnings if API calls fail
- Continues processing with available data

### Package Validation
- Checks all required packages are installed
- Provides installation command if packages are missing

## Troubleshooting

### Problem: "Missing required packages"
**Solution**: Install missing packages with:
```r
install.packages(c("readxl", "dplyr", "tidyr", "stringr", "readr", "xlsx"))
```

### Problem: "Enzyme terms file not found"
**Solution**: Ensure `enzymes_unique.txt` is in `output_data/` directory

### Problem: "Failed to fetch data from KEGG API"
**Solutions**:
- Check internet connection
- KEGG API may be temporarily unavailable - try again later
- Check if firewall is blocking API access

### Problem: "Entries without gene match"
**Note**: This is normal. The script reports how many entries couldn't be matched with gene information. These are filtered out from the final database.

## Performance

**Typical Execution Time**: 1-2 minutes (depends on internet speed and KEGG API response time)

**Memory Usage**: ~200 (for typical dataset sizes)

## Version History

- **v1.0.0 (2024-12-15)**: Production release with modular design, comprehensive documentation, and enzyme activity extraction

## License

This script is part of the BioRemPP project.

---

**Version**: 1.0.0  
**Author**: BioRemPP Development Team  
**Last Updated**: 2024-12-15
