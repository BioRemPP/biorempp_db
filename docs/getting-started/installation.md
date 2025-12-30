# Installation

This guide provides step-by-step instructions for setting up your environment to run the BioRemPP Database generation pipeline.

---

## Overview

The installation process prepares your system to execute the database generation pipeline, which:

- Loads local input data files (KEGG compounds, environmental agency lists, curations, enzyme terms)
- Fetches data from the KEGG REST API
- Integrates and transforms data through a 7-stage R pipeline
- Generates output files (CSV, Excel, JSON statistics)

**What you will install:**

- R (≥4.0.0) programming environment
- 6 required R packages: `readxl`, `dplyr`, `tidyr`, `stringr`, `readr`, `xlsx`
- BioRemPP Database repository and input data files

**Estimated time:** 15-30 minutes (depending on download speeds and R package compilation)

---

## Supported Operating Systems and Environments

### Local Execution (Recommended for First-Time Users)

| Platform | Status | Notes |
|----------|--------|-------|
| **Windows** | ✅ Fully Supported | Windows 10/11, PowerShell or Command Prompt |
| **macOS** | ✅ Fully Supported | macOS 10.14+ (Mojave or newer) |
| **Linux** | ✅ Fully Supported | Ubuntu 20.04+, Debian 10+, CentOS 8+, Fedora 34+ |

**Recommended for:** Interactive exploration, initial testing, development, small-scale runs

### Server/HPC Execution (For Production or Large-Scale Runs)

| Environment | Status | Notes |
|-------------|--------|-------|
| **Linux HPC** | ✅ Supported | SLURM, PBS, SGE job schedulers |
| **Cloud (AWS, GCP, Azure)** | ✅ Supported | R-compatible VMs or containers |
| **Docker/Singularity** | ✅ Supported | Containerized deployment (future releases) |

**Recommended for:** Batch processing, reproducible workflows, institutional compute clusters

---

## Installation Options

### Option 1: Local Installation (Windows, macOS, Linux)

#### Step 1: Install R

**Required version:** R ≥ 4.0.0 (R 4.3.0+ recommended)

=== "Windows"

    1. Download R installer from [CRAN Windows](https://cran.r-project.org/bin/windows/base/)
    2. Run the `.exe` installer (e.g., `R-4.3.2-win.exe`)
    3. Follow installation wizard (default options are suitable)
    4. Verify installation:
       ```powershell
       R --version
       ```
       Expected output: `R version 4.3.2 (2023-10-31) -- "Eye Holes"`

=== "macOS"

    1. Download R installer from [CRAN macOS](https://cran.r-project.org/bin/macosx/)
    2. Open the `.pkg` file (e.g., `R-4.3.2-arm64.pkg` for Apple Silicon or `R-4.3.2-x86_64.pkg` for Intel)
    3. Follow installation wizard
    4. Verify installation:
       ```bash
       R --version
       ```

=== "Linux (Ubuntu/Debian)"

    ```bash
    # Add CRAN repository for latest R version
    sudo apt update
    sudo apt install -y software-properties-common
    sudo add-apt-repository 'deb https://cloud.r-project.org/bin/linux/ubuntu $(lsb_release -cs)-cran40/'
    
    # Import CRAN GPG key
    wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | sudo tee -a /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc
    
    # Install R
    sudo apt update
    sudo apt install -y r-base r-base-dev
    
    # Verify installation
    R --version
    ```

=== "Linux (CentOS/RHEL)"

    ```bash
    # Install EPEL repository
    sudo yum install -y epel-release
    
    # Install R
    sudo yum install -y R
    
    # Verify installation
    R --version
    ```

#### Step 2: Install System Dependencies (Linux Only)

R packages may require system libraries for compilation:

=== "Ubuntu/Debian"

    ```bash
    sudo apt install -y \
      libcurl4-openssl-dev \
      libssl-dev \
      libxml2-dev \
      libfontconfig1-dev \
      libharfbuzz-dev \
      libfribidi-dev \
      libfreetype6-dev \
      libpng-dev \
      libtiff5-dev \
      libjpeg-dev
    ```

=== "CentOS/RHEL"

    ```bash
    sudo yum install -y \
      libcurl-devel \
      openssl-devel \
      libxml2-devel \
      fontconfig-devel \
      harfbuzz-devel \
      fribidi-devel \
      freetype-devel \
      libpng-devel \
      libtiff-devel \
      libjpeg-turbo-devel
    ```

#### Step 3: Clone the Repository

```bash
# Clone from GitHub
git clone https://github.com/BioRemPP/biorempp_db.git

# Navigate to database directory
cd biorempp_db
```

**Alternative (without Git):**

1. Download ZIP from [GitHub Releases](https://github.com/BioRemPP/biorempp_db/releases)
2. Extract archive
3. Navigate to `biorempp_db/` directory

#### Step 4: Install R Package Dependencies

Open R console or RStudio and run:

```r
# Install required packages from CRAN
install.packages(c(
  "readxl",      # Read Excel files
  "dplyr",       # Data manipulation
  "tidyr",       # Data tidying
  "stringr",     # String operations
  "readr",       # Fast CSV reading
  "xlsx"         # Write Excel files
))
```

**Expected installation time:** 5-15 minutes (first-time installation with compilation)

**Verify installation:**

```r
# Check all packages load successfully
packages <- c("readxl", "dplyr", "tidyr", "stringr", "readr", "xlsx")
sapply(packages, require, character.only = TRUE)
```

Expected output: All values should be `TRUE`

---

### Option 2: Server/HPC Installation

For institutional compute clusters or cloud servers:

#### Prerequisites

- SSH access to server
- R ≥ 4.0.0 installed (contact system administrator if not available)
- Write permissions to home directory or project space

#### Installation Steps

```bash
# 1. SSH into server
ssh username@hpc.institution.edu

# 2. Load R module (if using module system)
module load R/4.3.2

# 3. Clone repository
git clone https://github.com/BioRemPP/biorempp_db.git
cd biorempp_db

# 4. Install R packages (non-interactive)
Rscript -e 'install.packages(c("readxl", "dplyr", "tidyr", "stringr", "readr", "xlsx"), repos="https://cloud.r-project.org")'

# 5. Verify installation
Rscript -e 'sapply(c("readxl", "dplyr", "tidyr", "stringr", "readr", "xlsx"), require, character.only=TRUE)'
```

#### HPC Job Submission Example (SLURM)

Create `install_packages.sh`:

```bash
#!/bin/bash
#SBATCH --job-name=biorempp_install
#SBATCH --time=01:00:00
#SBATCH --mem=4G
#SBATCH --cpus-per-task=1

module load R/4.3.2

Rscript -e '
  install.packages(
    c("readxl", "dplyr", "tidyr", "stringr", "readr", "xlsx"),
    repos = "https://cloud.r-project.org",
    lib = "~/R/library"
  )
'
```

Submit job:

```bash
sbatch install_packages.sh
```

---

## Expected Directory Structure

After successful installation, verify the following structure:

```
biorempp_db/
├── generate_database.R          # Main pipeline script
├── README.md                     # Pipeline documentation
├── database_info.md              # Database metadata
├── input_data/                   # Input files (6 files)
│   ├── kegglistcompounds.xlsx
│   ├── compostos_todasagencias.xlsx
│   ├── missing_compounds_founds_curated.xlsx
│   ├── confirm_class_CURATED.xlsx
│   ├── kegglistko.txt
│   └── enzymes_unique.txt
├── output_data/                  # Generated by pipeline (initially empty)
├── analysis/                     # Analysis scripts
│   ├── analyze_database.R
│   ├── README.md
│   └── output/                   # Analysis outputs (generated)
└── docs/                         # Documentation (MkDocs)
    ├── index.md
    └── ...
```

**Verify input data files:**

```bash
# Check that all input files exist
ls -lh input_data/
```

Expected: 6 files totaling ~2.2 MB

---

## Post-Installation Validation Checklist

Run these checks to confirm successful installation:

### ✅ Checklist

- [ ] **R installed and accessible**  
      ```bash
      R --version  # Should show R ≥ 4.0.0
      ```

- [ ] **All 6 R packages installed**  
      ```r
      sapply(c("readxl", "dplyr", "tidyr", "stringr", "readr", "xlsx"), 
             packageVersion)
      ```

- [ ] **Repository cloned successfully**  
      ```bash
      ls biorempp_db/generate_database.R  # Should exist
      ```

- [ ] **All 6 input data files present**  
      ```bash
      ls biorempp_db/input_data/*.xlsx
      ls biorempp_db/input_data/*.txt
      ```

- [ ] **Write permissions to output directory**  
      ```bash
      touch biorempp_db/output_data/test.txt
      rm biorempp_db/output_data/test.txt
      ```

- [ ] **Internet connectivity for KEGG API**  
      ```bash
      curl -I https://rest.kegg.jp/list/pathway
      # Should return HTTP/1.1 200 OK
      ```

### Quick Test Run

Verify the pipeline can execute:

```r
# Open R in biorempp_db/ directory
setwd("biorempp_db")

# Load first few lines of main script (without running full pipeline)
source("generate_database.R", echo = TRUE, max.deparse.length = 100)
```

If successful, you should see package loading messages and function definitions without errors.

---

## Common Installation Issues and Solutions

### Issue 1: R Package Compilation Fails

**Symptom:**
```
ERROR: compilation failed for package 'dplyr'
```

**Cause:** Missing system development libraries (Linux)

**Solution:**

=== "Ubuntu/Debian"
    ```bash
    sudo apt install -y r-base-dev build-essential
    ```

=== "CentOS/RHEL"
    ```bash
    sudo yum install -y R-devel gcc gcc-c++ make
    ```

---

### Issue 2: `xlsx` Package Installation Fails (Java Dependency)

**Symptom:**
```
Error: Java not found
```

**Cause:** `xlsx` package requires Java Runtime Environment (JRE)

**Solutions:**

**Option A: Install Java**

=== "Windows"
    1. Download Java from [java.com](https://www.java.com/download/)
    2. Install and restart R
    3. Reinstall `xlsx`: `install.packages("xlsx")`

=== "macOS"
    ```bash
    brew install openjdk
    sudo R CMD javareconf
    ```
    Then in R: `install.packages("xlsx")`

=== "Linux"
    ```bash
    # Ubuntu/Debian
    sudo apt install -y default-jre default-jdk
    sudo R CMD javareconf
    
    # CentOS/RHEL
    sudo yum install -y java-11-openjdk java-11-openjdk-devel
    sudo R CMD javareconf
    ```

**Option B: Use Alternative Package (No Java Required)**

Replace `xlsx` with `writexl`:

```r
install.packages("writexl")
```

Then modify `generate_database.R` line 730:

```r
# Replace:
library(xlsx)
write.xlsx(final_database, output_xlsx, row.names = FALSE)

# With:
library(writexl)
write_xlsx(final_database, output_xlsx)
```

---

### Issue 3: KEGG API Connection Timeout

**Symptom:**
```
Error in fetch_kegg_api: Failed to fetch data from KEGG API
```

**Cause:** Firewall blocking HTTPS requests or temporary KEGG server issues

**Solutions:**

1. **Check internet connectivity:**
   ```bash
   curl https://rest.kegg.jp/list/pathway
   ```

2. **If behind corporate firewall:** Configure proxy in R
   ```r
   Sys.setenv(http_proxy = "http://proxy.company.com:8080")
   Sys.setenv(https_proxy = "https://proxy.company.com:8080")
   ```

3. **Retry with increased timeout:**
   Edit `generate_database.R`, add at top:
   ```r
   options(timeout = 300)  # Increase timeout to 5 minutes
   ```

---

### Issue 4: Permission Denied When Creating Output Files

**Symptom:**
```
Error: cannot open file 'output_data/biorempp_database_v1.0.0.csv'
```

**Cause:** No write permissions to output directory

**Solutions:**

=== "Windows"
    1. Right-click `biorempp_db` folder
    2. Properties → Security → Edit
    3. Grant "Full Control" to your user account

=== "macOS/Linux"
    ```bash
    # Make output directory writable
    chmod -R u+w biorempp_db/output_data/
    
    # Or change ownership
    sudo chown -R $USER:$USER biorempp_db/
    ```

---

### Issue 5: Out of Memory Error (Large Datasets)

**Symptom:**
```
Error: cannot allocate vector of size X GB
```

**Cause:** Insufficient RAM for data processing

**Solutions:**

1. **Close other applications** to free memory

2. **Increase R memory limit (Windows only):**
   ```r
   memory.limit(size = 16000)  # Set to 16 GB
   ```

3. **Process data in chunks** (modify pipeline to handle larger datasets)

4. **Use HPC/server** with more RAM (recommended for production)

---

### Issue 6: RStudio Not Finding R Installation

**Symptom:** RStudio shows "R version not found"

**Solution:**

=== "Windows"
    1. Tools → Global Options → General
    2. R version → Change
    3. Browse to R installation (e.g., `C:\Program Files\R\R-4.3.2`)

=== "macOS"
    ```bash
    # Verify R location
    which R
    
    # If not in PATH, add to ~/.zshrc or ~/.bash_profile:
    export PATH="/usr/local/bin:$PATH"
    ```

---



## Need Help?

**GitHub Issues:** [https://github.com/BioRemPP/biorempp_db/issues](https://github.com/BioRemPP/biorempp_db/issues)  
**Email:** biorempp@gmail.com

When reporting installation issues, please include:

- Operating system and version
- R version (`R.version.string`)
- Error messages (full text)
- Output of `sessionInfo()`
