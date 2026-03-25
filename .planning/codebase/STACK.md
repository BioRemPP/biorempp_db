# Technology Stack

**Analysis Date:** 2026-03-24

## Languages

**Primary:**
- **R** 4.3 - Data processing, KEGG API interaction, statistical analysis, database generation and enrichment. All scripts in `biorempp_snakemake_version/workflow/scripts/generation/` and `biorempp_snakemake_version/workflow/scripts/analysis/` are R-based
- **Python** 3.10+ - Workflow orchestration, validation, reporting, and API verification scripts in `biorempp_snakemake_version/workflow/scripts/validation/` and `biorempp_snakemake_version/workflow/scripts/reporting/`

**Secondary:**
- **Makefile/Shell** - Build orchestration and docker-compose setup in `biorempp_snakemake_version/env/`

## Runtime

**Environment:**
- **R** 4.3 (via rocker/tidyverse Docker image)
- **Python** 3 (via system Python packages)
- **Snakemake** 7.32.4 - Workflow orchestration runtime

**Package Manager:**
- **R package manager** - Built into R
- **pip** (Python 3) - For Python package management
- **APT** - System-level package management in Docker
- **Lockfile:** Not explicitly used; requirements specified in `biorempp_snakemake_version/env/python-requirements.txt` and `biorempp_snakemake_version/env/r-packages.txt`

## Frameworks

**Core:**
- **Snakemake** 7.32.4 - Workflow orchestration framework (defined in `biorempp_snakemake_version/Snakefile`)
- **MkDocs** 1.5.0+ - Documentation generation framework
- **MkDocs Material** 9.4.0+ - Material Design theme for documentation

**Testing & Validation:**
- **Great Expectations** 1.12 (< 1.13) - Data quality validation and expectation suites in `biorempp_validation/` module
- **pytest** 8.0 (< 9.0) - Python unit testing framework for validation tests

**Build/Dev:**
- **Docker** - Containerization (Dockerfile at `biorempp_snakemake_version/env/Dockerfile`)
- **Docker Compose** 1.0+ - Multi-service orchestration in `biorempp_snakemake_version/env/docker-compose.yml`
- **Read the Docs** - Documentation hosting and CI/CD pipeline (config: `.readthedocs.yaml`)

## Key Dependencies

**Critical:**

**R Packages:**
- **readxl** - Read Excel input files (agency compound lists, curated data in `input_data/`)
- **dplyr** - Data manipulation, normalization, and relationship building (used in all generation and analysis scripts)
- **tidyr** - Data reshaping and tidying operations
- **stringr** - String manipulation for compound/enzyme/reaction identifier parsing
- **readr** - Reading CSV and delimited text files
- **jsonlite** - JSON reading/writing for analysis outputs
- **writexl** - Writing final database to Excel format

**Python Packages:**
- **pandas** 2.0+ - Data frame operations in validation module (`biorempp_validation/`)
- **PyYAML** 6.0+ - YAML configuration file parsing for validation and workflow config
- **jsonschema** 4.0+ - JSON schema validation for output file integrity
- **urllib** - Built-in Python HTTP client for KEGG REST API calls (in validation scripts)
- **csv** - Built-in CSV parsing in validation scripts
- **json** - Built-in JSON handling across all Python scripts

**Infrastructure:**
- **pulp** 2.7.0 - Linear programming solver (optional, may be used for optimization in workflow)

## Configuration

**Environment:**
- YAML-based configuration: `biorempp_snakemake_version/config/config.yaml`
  - KEGG API endpoints and base URL configuration
  - Input/output path definitions
  - Analysis parameters (top-N cutoffs)
  - Database output naming (v1.0.0)
- Great Expectations validation config: `biorempp_validation/config/validation.yaml`
  - Data quality thresholds and drift limits
  - Expected database columns and reference agencies
  - File requirement specifications

**Build:**
- Docker build: `biorempp_snakemake_version/env/Dockerfile` (Debian-based, rocker/tidyverse)
- Docker Compose: `biorempp_snakemake_version/env/docker-compose.yml`
- Python requirements: `biorempp_snakemake_version/env/python-requirements.txt` (Snakemake + PuLP)
- R packages: `biorempp_snakemake_version/env/r-packages.txt` (tidyverse ecosystem)

## Platform Requirements

**Development:**
- Docker and Docker Compose for containerized execution
- Python 3.10+
- R 4.3 (via Docker)
- Bash shell for Snakemake execution
- Git for version control
- MkDocs for documentation building

**Production:**
- Docker container execution environment
- 2+ CPU cores (default Snakemake config uses `--cores 2`)
- Persistent storage for workflow results (`results/`, `work/`, `logs/` directories)
- Internet access to KEGG REST API at https://rest.kegg.jp
- Read the Docs hosting for documentation (https://biorempp-database.readthedocs.io)

**Deployment Target:**
- Linux container runtime (Docker)
- GitHub repository for source code and CI/CD integration
- Read the Docs platform for automatic documentation builds

---

*Stack analysis: 2026-03-24*
