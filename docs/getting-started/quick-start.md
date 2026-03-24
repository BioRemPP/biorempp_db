# Quick Start Guide

Get started with BioRemPP Database in under 10 minutes.

---

## Objective

This guide demonstrates a complete end-to-end execution of the BioRemPP Database
generation pipeline using the Snakemake workflow, from cloning the repository to
examining the output files. By the end of this quick start, you will have:

- Cloned the BioRemPP Database repository
- Executed the Snakemake pipeline (via Docker or locally)
- Generated the complete database (10,871 entries)
- Validated the output with a dry-run and output checks
- Explored basic database statistics

**Estimated time:** ~10 minutes (first run, including Docker image build)

---

## Prerequisites

=== "Docker (Recommended)"

    - ✅ **Docker** ≥ 20.10 and **Docker Compose** v2 installed
    - ✅ **Internet connection** for KEGG API access and image build
    - ✅ **Git** installed (optional, needed only for cloning)

=== "Local (Snakemake + R)"

    - ✅ **R** ≥ 4.3 installed ([verify](requirements.md#check-r-version))
    - ✅ **Python** ≥ 3.8 with `snakemake==7.32.4` and `pulp==2.7.0`
    - ✅ **R packages** installed: `readxl`, `dplyr`, `tidyr`, `stringr`, `readr`, `writexl`, `jsonlite`
    - ✅ **Internet connection** for KEGG API access
    - ✅ **Git** installed (optional, needed only for cloning)

If prerequisites are not met, see [Installation Guide](installation.md).

---

## Step-by-Step Execution

### Step 1: Clone the Repository

Open a terminal (macOS/Linux) or PowerShell/Command Prompt (Windows):

=== "Git"

    ```bash
    git clone https://github.com/BioRemPP/biorempp_db.git
    cd biorempp_db/biorempp_snakemake_version
    ```

=== "Manual Download"

    1. Visit [GitHub Repository](https://github.com/BioRemPP/biorempp_db)
    2. Click **Code** → **Download ZIP**
    3. Extract the ZIP and navigate to the Snakemake directory:
       ```bash
       cd path/to/biorempp_db/biorempp_snakemake_version
       ```

**Expected result:** You are now inside `biorempp_snakemake_version/`, which
contains the `Snakefile`, `config/`, and `workflow/` directories.

---

### Step 2: Verify Input Data

Confirm that the required input files are present:

```bash
ls -lh input_data/
```

**Expected output (6 files + `.gitkeep`):**

```
compostos_todasagencias.xlsx
confirm_class_CURATED.xlsx
enzymes_unique.txt
kegglistcompounds.xlsx
kegglistko.txt
missing_compounds_founds_curated.xlsx
```

!!! note
    All six mandatory input files are present inside
    `biorempp_snakemake_version/input_data/`. Copies also exist in the
    repository root `input_data/` (configured via `paths.input_dir` in
    `config/config.yaml`, default: `../input_data`).

✅ **Checkpoint:** The two core input files should be present.

---

### Step 3: Dry-Run (Validate DAG)

Before executing anything, verify the workflow graph resolves correctly:

=== "Docker"

    ```bash
    docker compose -f env/docker-compose.yml run --rm snakemake \
        snakemake --snakefile Snakefile --configfile config/config.yaml --dry-run
    ```

=== "Local"

    ```bash
    snakemake --dry-run
    ```

You should see a list of 19 jobs (18 concrete rules + the `all` target) that Snakemake plans to execute.
If the dry-run prints errors, see [Troubleshooting](#troubleshooting) below.

✅ **Checkpoint:** Dry-run completes with no errors and lists all planned jobs.

---

### Step 4: Run the Pipeline

=== "Docker (Recommended)"

    ```bash
    # Build the image (first time only, ~2 min)
    docker compose -f env/docker-compose.yml build

    # Execute the full pipeline
    docker compose -f env/docker-compose.yml run --rm snakemake
    ```

=== "Local (Snakemake)"

    ```bash
    snakemake --cores 2
    ```

=== "Windows (Helper Script)"

    ```powershell
    .\scripts\run_snakemake.bat
    ```

**What happens during execution:**

Snakemake executes 18 concrete rules (plus the `all` target = 19 jobs) in four layers:

| Layer | Rules | Description |
|-------|-------|-------------|
| **Preflight** | `preflight_check_inputs` | Validates input files and config |
| **Generation** | 7 rules | Loads local data, fetches KEGG API, merges, classifies, enriches |
| **Analysis** | 9 rules | Produces JSON statistics (6 independent + 3 downstream) |
| **Reporting** | `build_run_report` | Generates `workflow_summary.json` with SHA-256 checksums |

```
Building DAG of jobs...
Job stats:
    job                         count
    ------------------------  -------
    all                             1
    build_run_report                1
    preflight_check_inputs          1
    ...
    19

[... rule execution logs ...]

19 of 19 steps (100%) done
Complete log: .snakemake/log/2025-01-15T120000.snakemake.log
```

**Estimated runtime:** ~5 minutes (depends on KEGG API response time)

---

### Step 5: Verify Output Files

Check that the pipeline produced all expected artefacts:

```bash
ls -lh results/database/
ls -lh results/analysis/
ls results/metadata/
ls results/reports/
```

**Expected structure:**

```
results/
├── database/
│   ├── biorempp_database_v1.0.0.csv   (~1.3 MB)
│   └── biorempp_database_v1.0.0.xlsx  (~460 KB)
├── analysis/
│   ├── basic_statistics.json
│   ├── complete_analysis.json
│   ├── compound_statistics.json
│   ├── crosstab_statistics.json
│   ├── database_metadata.json
│   ├── enzyme_statistics.json
│   ├── executive_summary.json
│   ├── gene_statistics.json
│   └── ko_statistics.json
├── metadata/
│   └── kegg_release.json
└── reports/
    └── workflow_summary.json
```

✅ **Checkpoint:** Both database files, 9 analysis JSONs, KEGG release metadata,
and the workflow summary should all be present.

---

### Step 6: Explore the Database

Load the database into R for quick exploration:

```r
# Load database
db <- read.csv("results/database/biorempp_database_v1.0.0.csv")

# Quick inspection
dim(db)
# Expected: [1] 10871     8

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
[1] 10871     8

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
| **Main Database (CSV)** | `results/database/biorempp_database_v1.0.0.csv` | ~1.3 MB | 10,871 | 8 |
| **Main Database (Excel)** | `results/database/biorempp_database_v1.0.0.xlsx` | ~460 KB | 10,871 | 8 |
| **Analysis JSONs** (×9) | `results/analysis/*.json` | ~200 KB total | — | — |
| **KEGG Release** | `results/metadata/kegg_release.json` | <1 KB | — | — |
| **Workflow Summary** | `results/reports/workflow_summary.json` | ~2 KB | — | — |

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
# Expected: 10871
```

✅ **Pass:** Exactly 10,871 rows

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
#              384            12          1542             9 
#     compoundname    genesymbol      genename enzyme_activity 
#              384          1516          1542           205
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
   db[db$compoundname == "Trichloroethene", ]
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

The Snakemake pipeline **automatically** generates 9 JSON analysis files in
`results/analysis/` as part of the Analysis layer. No separate command is needed.

To view the executive summary:

```bash
cat results/analysis/executive_summary.json | python -m json.tool
```

See: [Understanding Output](../user-guide/understanding-output.md)

---


## Troubleshooting

### Dry-run fails with missing input files

**Solution:** Ensure you are running from the `biorempp_snakemake_version/`
directory and that `input_data/` contains the required files.
See [Installation Guide](installation.md#post-installation-validation-checklist).

---

### Docker build fails

**Solution:** Ensure Docker is running and you have internet access. Retry with:

```bash
docker compose -f env/docker-compose.yml build --no-cache
```

See [Installation — Docker Troubleshooting](installation.md#common-installation-issues-and-solutions).

---

### KEGG API timeout during pipeline execution

**Solution:** KEGG API can be slow or rate-limited. Snakemake will only re-run
the failed rule on retry. Simply re-execute the same command:

```bash
# Docker
docker compose -f env/docker-compose.yml run --rm snakemake

# Local
snakemake --cores 2
```

Already-completed rules are skipped automatically.

---

### Different row count than expected

**Possible causes:**

- Updated KEGG data (the database evolves over time)
- Modified input files
- Incomplete API responses

**Solution:** Re-run the pipeline or consult [Known Limitations](../validation/limitations.md).

---

## Post-Pipeline Validation

After the Snakemake pipeline completes you can run the **biorempp-validation**
module to verify all outputs automatically:

```bash
cd biorempp_validation
pip install -e .
python -m biorempp_validation.run_validation --config config/validation.yaml
```

See [Data Validation (GX) — Architecture](../validation-gx/architecture.md)
for an overview and [Configuration Reference](../validation-gx/configuration.md)
for customising paths and policy flags.

---

## Questions?

**GitHub Issues:** [https://github.com/BioRemPP/biorempp_db/issues](https://github.com/BioRemPP/biorempp_db/issues)  
**Email:** biorempp@gmail.com
