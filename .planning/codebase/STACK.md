# STACK — BioRemPP DB 1.0.0

> Last mapped: 2026-05-31

## Summary

BioRemPP DB 1.0.0 is a bioinformatics pipeline that builds a curated bioremediation database by combining locally curated spreadsheet inputs with live data fetched from the KEGG REST API. The pipeline is orchestrated by Snakemake 8, executed inside a Docker container based on `rocker/tidyverse:4.4` (R 4.4), with Python 3.12 running validation scripts alongside the R data-processing scripts. A separate Python package (`biorempp-validation`) implements a Great Expectations validation layer over the pipeline outputs. Documentation is built with MkDocs Material and published to Read the Docs.

---

## Languages

| Language | Version | Where used |
|----------|---------|------------|
| R | 4.4 (via `rocker/tidyverse:4.4`) | All data-generation and analysis scripts under `biorempp_snakemake_version/workflow/scripts/generation/` and `workflow/scripts/analysis/` |
| Python | 3.12 (runtime in Docker); 3.11 (docs CI / Read the Docs); >=3.10 (validation package) | KEGG API caching, validation scripts (`workflow/scripts/validation/`), reporting (`workflow/scripts/reporting/build_run_report.py`), GX validation package (`biorempp_validation/`) |
| Bash | POSIX | `scripts/build-docs.sh` (docs tooling only) |
| YAML / JSON | — | Configuration, pipeline outputs, GX expectation suites |

---

## Runtime & Containerization

**Primary execution environment:**
- Docker image: `rocker/tidyverse:4.4` (SHA-pinned: `sha256:7b6ad006…`)
- Defined in: `biorempp_snakemake_version/env/Dockerfile`
- Orchestrated by: `biorempp_snakemake_version/env/docker-compose.yml`
- Container working directory: `/workspace/biorempp_snakemake_version`

**Local development (docs only):**
- Python `venv` at `venv/` (Windows-native, `venv/Scripts/python.exe`)
- Python version: 3.x (detected at runtime by `scripts/build-docs.sh`)

---

## Package Managers & Dependency Files

| File | Manager | Purpose |
|------|---------|---------|
| `biorempp_snakemake_version/env/python-requirements.txt` | pip (inside Docker) | Snakemake + PuLP for pipeline |
| `biorempp_snakemake_version/env/r-packages.txt` | R `remotes::install_version` (inside Docker) | Pinned R package manifest |
| `biorempp_snakemake_version/env/Dockerfile` | Docker | Full environment definition |
| `biorempp_validation/pyproject.toml` | pip / setuptools | `biorempp-validation` Python package |
| `requirements.txt` (root) | pip | Docs-only: MkDocs + Material |
| `.readthedocs.yaml` | Read the Docs | RTD build configuration |

No conda environment files (`environment.yml`) are present. No `renv.lock` is used; R packages are version-pinned via `remotes::install_version` in the Dockerfile.

---

## Frameworks & Core Libraries

### Pipeline — Snakemake (Python)

| Package | Version | Purpose |
|---------|---------|---------|
| `snakemake` | `==8.30.0` | Workflow orchestration; DAG-based rule execution |
| `pulp` | `==2.7.0` | ILP solver for Snakemake 8 DAG scheduling |

Snakefile: `biorempp_snakemake_version/Snakefile`
Rules split across: `workflow/rules/00_preflight.smk`, `10_generation.smk`, `20_analysis.smk`, `30_validation.smk`, `90_reporting.smk`

### Pipeline — R (data processing)

| Package | Version | Purpose |
|---------|---------|---------|
| `dplyr` | `1.1.4` | DataFrame manipulation; `many-to-many` joins in `04_merge_relationships.R` |
| `readxl` | `1.4.3` | Reading `.xlsx` input files |
| `tidyr` | `1.3.1` | Data reshaping |
| `stringr` | `1.5.1` | String operations, regex extraction |
| `readr` | `2.1.5` | Tabular data reading |
| `jsonlite` | `1.8.8` | JSON serialization of outputs and metadata |
| `writexl` | `1.5.0` | Writing `.xlsx` output |
| `httr` | (rocker base) | HTTP GET requests to KEGG REST API (`03_fetch_kegg_data.R`) |
| `stats` | (R base) | `runif` for jitter in retry backoff |

Shared R utilities: `biorempp_snakemake_version/workflow/lib/utils.R`, `workflow/lib/io_contracts.R`

### Validation — Python (Great Expectations)

| Package | Version constraint | Purpose |
|---------|--------------------|---------|
| `great_expectations` | `~=1.12.0` | Expectation suites and checkpoints for pipeline outputs |
| `pandas` | `>=2.0,<3.0` | DataFrame backing for GX validators |
| `PyYAML` | `>=6.0,<7.0` | Loading `validation.yaml` config |
| `jsonschema` | `>=4.0,<5.0` | JSON schema validation helpers |
| `pytest` | `>=8.0,<9.0` (dev) | Test suite for validation package |

Package entry point: `biorempp-validate` → `biorempp_validation.run_validation:main_cli`
Source: `biorempp_validation/src/biorempp_validation/`

### Documentation

| Package | Version constraint | Purpose |
|---------|--------------------|---------|
| `mkdocs` | `>=1.5.0,<2.0.0` | Static site generator |
| `mkdocs-material` | `>=9.4.0,<10.0.0` | Material theme |
| `mkdocs-minify-plugin` | `>=0.7.0,<1.0.0` | HTML minification |
| `pymdown-extensions` | `>=10.3,<11.0.0` | Enhanced Markdown (mermaid diagrams, tasklists, etc.) |
| `Pygments` | `>=2.16.0` | Syntax highlighting |

MkDocs config: `mkdocs.yml`
Built site: `site/` (generated, not source)

---

## Build Tooling & Scripts

| Tool / Script | Purpose |
|---------------|---------|
| `scripts/build-docs.sh` | Bash script: creates venv, installs deps, builds/serves MkDocs docs |
| `biorempp_snakemake_version/env/Dockerfile` | Builds the full pipeline execution image |
| `biorempp_snakemake_version/env/docker-compose.yml` | Single-service compose: mounts project root, runs Snakemake |
| `.github/workflows/docs-ci.yml` | GitHub Actions CI: builds docs on push to `main`/`dev` (Python 3.11, ubuntu-latest) |
| `.readthedocs.yaml` | Read the Docs build config (Python 3.11, ubuntu-22.04, MkDocs) |

---

## Pipeline Configuration

Primary config: `biorempp_snakemake_version/config/config.yaml`

Key settings:
- `version: "1.1.0"` — database version string embedded in output filenames
- `kegg.base_url: "https://rest.kegg.jp"` — KEGG REST API base
- `outputs.database_csv_delimiter: ";"` — semicolon-delimited CSV output
- `analysis.top_n_compounds / top_n_ko / top_n_enzymes` — statistics cutoffs

Validation config: `biorempp_validation/config/validation.yaml`

Key settings:
- `strict_exact: true` — locks drift thresholds to exact counts from last run
- `policy.fail_on_critical: true`, `fail_on_warning: true`
- `csv.delimiter: ";"` — must match pipeline output

API retry behavior (configurable via env vars):
- `BIOREMPP_API_MAX_RETRIES` (default: 6)
- `BIOREMPP_API_TIMEOUT_SECONDS` (default: 90)
- `BIOREMPP_API_BACKOFF_BASE_SECONDS` (default: 1.0)
- `BIOREMPP_API_BACKOFF_MAX_SECONDS` (default: 30.0)
- `BIOREMPP_API_BACKOFF_JITTER_RATIO` (default: 0.25)

---

## Data Formats

| Format | Extension | Usage |
|--------|-----------|-------|
| Excel (OOXML) | `.xlsx` | Input curated compound/KO tables; final database output |
| CSV (semicolon-delimited, quoted) | `.csv` | Primary database output; intermediate cache files |
| TSV | `.tsv` | KEGG link cache files written by `cache_kegg_links.py` |
| JSON | `.json` | All analysis statistics, metadata, validation reports, GX expectation suites |
| R binary object | `.rds` | Intermediate pipeline data bundles passed between Snakemake rules |
| Plain text | `.txt` | Input KO list (`kegglistko.txt`), enzyme terms (`enzymes_unique.txt`), NA markers |
| YAML | `.yaml` | Pipeline and validation configuration |

---

## Confidence

- HIGH: All package versions, language choices, and runtime observed directly in `Dockerfile`, `python-requirements.txt`, `r-packages.txt`, `pyproject.toml`, `requirements.txt`
- HIGH: Data formats observed from file extensions in `input_data/`, `results/`, and from Snakemake rule I/O declarations
- HIGH: Env-var knobs observed directly in `kegg_api_client.py` and `03_fetch_kegg_data.R`
- MEDIUM: Python 3.12 as the actual in-container Python version (Dockerfile installs system `python3` on Ubuntu inside `rocker/tidyverse:4.4` which ships Ubuntu 22.04 / Python 3.10+; `.pyc` files in `__pycache__` are named `cpython-312`, confirming 3.12)
