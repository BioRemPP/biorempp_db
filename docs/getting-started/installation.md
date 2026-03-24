# Installation

This guide provides step-by-step instructions for setting up your environment to run the BioRemPP Database generation pipeline.

---

## Overview

The installation process prepares your system to execute the Snakemake-based database generation pipeline, which:

- Validates input data files (preflight checks)
- Loads local input data files (KEGG compounds, environmental agency lists, curations, enzyme terms)
- Fetches data from the KEGG REST API
- Integrates and transforms data through a 7-step generation pipeline
- Produces statistical analysis reports (9 JSON files)
- Generates provenance reports with SHA-256 checksums

**Two installation paths are available:**

| Path | What You Install | Best For |
|------|-----------------|----------|
| **Docker (Recommended)** | Docker + Docker Compose only | Most users, reproducibility |
| **Local** | R, Python, Snakemake, R packages | Development, customization |

**Estimated time:** 10-15 minutes (Docker) or 20-30 minutes (local)

---

## Supported Operating Systems and Environments

### Local Execution

| Platform | Status | Notes |
|----------|--------|-------|
| **Windows** | ✅ Fully Supported | Windows 10/11, PowerShell or Command Prompt |
| **macOS** | ✅ Fully Supported | macOS 10.14+ (Mojave or newer) |
| **Linux** | ✅ Fully Supported | Ubuntu 20.04+, Debian 10+, CentOS 8+, Fedora 34+ |

### Containerized Execution (Recommended)

| Environment | Status | Notes |
|-------------|--------|-------|
| **Docker** | ✅ Supported | Docker Desktop or Docker Engine |
| **Docker Compose** | ✅ Supported | Included with Docker Desktop |
| **HPC (Singularity)** | ✅ Supported | Convert Docker image to Singularity |

---

## Option 1: Docker Installation (Recommended)

Docker bundles R 4.3, Python 3, Snakemake 7.32.4, and all required packages into a single reproducible image based on `rocker/tidyverse:4.3`.

### Step 1: Install Docker

=== "Windows"

    1. Download [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop/)
    2. Run the installer and follow the prompts
    3. Restart your computer when prompted
    4. Verify installation:
       ```powershell
       docker --version
       docker compose version
       ```

=== "macOS"

    1. Download [Docker Desktop for macOS](https://www.docker.com/products/docker-desktop/)
    2. Open the `.dmg` file and drag Docker to Applications
    3. Launch Docker Desktop
    4. Verify installation:
       ```bash
       docker --version
       docker compose version
       ```

=== "Linux (Ubuntu/Debian)"

    ```bash
    # Install Docker
    sudo apt update
    sudo apt install -y docker.io docker-compose-plugin
    
    # Add user to docker group (avoids sudo)
    sudo usermod -aG docker $USER
    newgrp docker
    
    # Verify installation
    docker --version
    docker compose version
    ```

### Step 2: Clone the Repository

```bash
git clone https://github.com/BioRemPP/biorempp_db.git
cd biorempp_db
```

### Step 3: Build the Docker Image

```bash
cd biorempp_snakemake_version
docker compose -f env/docker-compose.yml build
```

**Expected build time:** 5-10 minutes (downloads base image, installs R and Python packages)

### Step 4: Verify Installation

Run a dry-run to validate the pipeline DAG without executing:

```bash
docker compose -f env/docker-compose.yml run --rm snakemake snakemake -n --snakefile Snakefile --configfile config/config.yaml
```

**Expected output:** List of rules that would be executed, with no errors.

### Step 5: Run the Pipeline

```bash
docker compose -f env/docker-compose.yml run --rm snakemake
```

This executes the command defined in `docker-compose.yml` (which overrides the Dockerfile `CMD`):

```
snakemake --snakefile Snakefile --configfile config/config.yaml --cores 2 --printshellcmds
```

**Results** are written to `biorempp_snakemake_version/results/`.

---

## Option 2: Local Installation (Without Docker)

### Step 1: Install R

**Required version:** R ≥ 4.0.0 (R 4.3.0+ recommended)

=== "Windows"

    1. Download R installer from [CRAN Windows](https://cran.r-project.org/bin/windows/base/)
    2. Run the `.exe` installer (default options are suitable)
    3. Verify:
       ```powershell
       R --version
       ```

=== "macOS"

    1. Download R installer from [CRAN macOS](https://cran.r-project.org/bin/macosx/)
    2. Open the `.pkg` file and follow the installation wizard
    3. Verify:
       ```bash
       R --version
       ```

=== "Linux (Ubuntu/Debian)"

    ```bash
    sudo apt update
    sudo apt install -y software-properties-common
    sudo add-apt-repository 'deb https://cloud.r-project.org/bin/linux/ubuntu $(lsb_release -cs)-cran40/'
    wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | sudo tee -a /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc
    sudo apt update
    sudo apt install -y r-base r-base-dev
    R --version
    ```

### Step 2: Install Python and Snakemake

=== "Windows"

    1. Download Python from [python.org](https://www.python.org/downloads/)
    2. During installation, check **"Add Python to PATH"**
    3. Install Snakemake:
       ```powershell
       pip install snakemake==7.32.4 pulp==2.7.0
       ```

=== "macOS/Linux"

    ```bash
    # Using pip (or conda)
    pip install snakemake==7.32.4 pulp==2.7.0
    
    # Verify
    snakemake --version
    ```

### Step 3: Install System Dependencies (Linux Only)

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

### Step 4: Clone the Repository

```bash
git clone https://github.com/BioRemPP/biorempp_db.git
cd biorempp_db
```

### Step 5: Install R Package Dependencies

```r
# Install required packages from CRAN
install.packages(c(
  "readxl",      # Read Excel files
  "dplyr",       # Data manipulation
  "tidyr",       # Data tidying
  "stringr",     # String operations
  "readr",       # Fast CSV reading
  "jsonlite",    # JSON I/O
  "writexl"      # Write Excel files (no Java required)
))
```

**Verify installation:**

```r
packages <- c("readxl", "dplyr", "tidyr", "stringr", "readr", "jsonlite", "writexl")
sapply(packages, require, character.only = TRUE)
```

### Step 6: Run the Pipeline

```bash
cd biorempp_snakemake_version
snakemake --snakefile Snakefile --configfile config/config.yaml --cores 2 --printshellcmds
```

---

## Expected Directory Structure After Installation

```
biorempp_db/
├── biorempp_snakemake_version/
│   ├── Snakefile
│   ├── config/
│   │   └── config.yaml
│   ├── env/
│   │   ├── Dockerfile
│   │   ├── docker-compose.yml
│   │   ├── python-requirements.txt
│   │   └── r-packages.txt
│   ├── workflow/
│   │   ├── lib/
│   │   ├── rules/
│   │   └── scripts/
│   ├── work/                         # Created during execution
│   └── results/                      # Created during execution
├── input_data/                       # 6 mandatory input files
├── docs/                             # MkDocs documentation
└── mkdocs.yml
```

**Verify input data files:**

```bash
ls -lh input_data/
```

Expected: 6 files totaling ~2.2 MB

---

## Post-Installation Validation Checklist

### Docker Installation

- [ ] **Docker running:** `docker --version`
- [ ] **Image built:** `docker compose -f env/docker-compose.yml build` completes without errors
- [ ] **Dry run passes:** `docker compose -f env/docker-compose.yml run --rm snakemake snakemake -n` shows no errors
- [ ] **Input files present:** 6 files in `input_data/`

### Local Installation

- [ ] **R installed:** `R --version` shows R ≥ 4.0.0
- [ ] **Python installed:** `python --version` shows Python ≥ 3.8
- [ ] **Snakemake installed:** `snakemake --version` shows 7.32.4
- [ ] **R packages installed:** All 7 packages load in R
- [ ] **Input files present:** 6 files in `input_data/`
- [ ] **Dry run passes:** `snakemake -n --snakefile Snakefile --configfile config/config.yaml`
- [ ] **KEGG API accessible:** `curl -I https://rest.kegg.jp/list/pathway` returns HTTP 200

---

## Common Installation Issues and Solutions

### Issue 1: Docker Build Fails with Network Error

**Symptom:** `ERROR: failed to fetch...` during Docker build

**Solution:**

- Check internet connectivity
- If behind a proxy, configure Docker proxy settings in `~/.docker/config.json`
- Retry the build: `docker compose -f env/docker-compose.yml build --no-cache`

---

### Issue 2: R Package Compilation Fails (Local Install)

**Symptom:** `ERROR: compilation failed for package 'dplyr'`

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

### Issue 3: Snakemake Not Found

**Symptom:** `snakemake: command not found`

**Solution:**

```bash
pip install snakemake==7.32.4 pulp==2.7.0

# If installed but not on PATH
python -m snakemake --version
```

---

### Issue 4: Permission Denied When Creating Output Files

**Symptom:** `PermissionError` or `Error: cannot open file`

**Solutions:**

=== "Windows"
    Right-click the project folder → Properties → Security → Grant "Full Control" to your user

=== "macOS/Linux"
    ```bash
    chmod -R u+w biorempp_snakemake_version/results/
    chmod -R u+w biorempp_snakemake_version/work/
    ```

---

### Issue 5: Docker Compose Volume Mount Errors

**Symptom:** Files not visible inside the container

**Solution:**

- Ensure Docker Desktop has file sharing enabled for your project drive
- On Windows, the project must be inside a shared directory (usually `C:\Users\`)
- Verify the volume mount in `docker-compose.yml` points to the correct relative path

---

## Need Help?

**GitHub Issues:** [https://github.com/BioRemPP/biorempp_db/issues](https://github.com/BioRemPP/biorempp_db/issues)  
**Email:** biorempp@gmail.com

When reporting installation issues, please include:

- Operating system and version
- Installation method (Docker or local)
- Docker version or R/Python/Snakemake versions
- Complete error messages
- Output of `docker compose version` or `snakemake --version`
