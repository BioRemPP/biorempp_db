# Technology Stack

**Analysis Date:** 2026-05-17

## Languages

**Primary:**
- R (≥4.3, via `rocker/tidyverse:4.3` Docker base image) — database generation pipeline (`generate_database.R`, all scripts under `biorempp_snakemake_version/workflow/scripts/generation/` and `analysis/`)
- Python 3.12 (local venv, `python3.12.0`) / Python 3.11 (CI and Read the Docs) — Snakemake orchestration, validation scripts (`biorempp_snakemake_version/workflow/scripts/validation/`), Great Expectations validation module (`biorempp_validation/`)

**Secondary:**
- YAML — pipeline configuration (`biorempp_snakemake_version/config/config.yaml`, `mkdocs.yml`, `.readthedocs.yaml`)
- Bash — documentation build script (`scripts/build-docs.sh`), Snakemake runner (`biorempp_snakemake_version/scripts/run_snakemake.sh`)
- Batch — Windows Snakemake runner (`biorempp_snakemake_version/scripts/run_snakemake.bat`)

## Runtime

**Environment:**
- Python 3.12.0 (local venv at `venv/`, created from `C:\Users\Douglas\AppData\Local\Programs\Python\Python312`)
- Python 3.11 (CI on ubuntu-latest via GitHub Actions; Read the Docs on ubuntu-22.04)
- R 4.3 (Docker container via `rocker/tidyverse:4.3`)

**Package Manager:**
- pip — Python dependencies managed via `requirements.txt` (docs), `biorempp_snakemake_version/env/python-requirements.txt` (pipeline), `biorempp_validation/requirements.txt` (validation)
- R built-in `install.packages()` — R packages listed in `biorempp_snakemake_version/env/r-packages.txt`
- Lockfile: Not present (no `pip-lock` or `poetry.lock`); version ranges used instead

## Frameworks

**Core Pipeline:**
- Snakemake 7.32.4 — workflow/pipeline orchestration (`biorempp_snakemake_version/Snakefile`, rules under `workflow/rules/`)
- pulp 2.7.0 — linear programming solver, Snakemake dependency for scheduling

**Data Validation:**
- Great Expectations ≥1.12,<1.13 — data quality validation framework (`biorempp_validation/src/biorempp_validation/`)
- pytest ≥8.0,<9.0 — test runner for the validation module (`biorempp_validation/tests/`)

**Documentation:**
- MkDocs ≥1.5.0,<2.0.0 — documentation site generator (`mkdocs.yml`)
- mkdocs-material ≥9.4.0,<10.0.0 — Material theme for MkDocs
- mkdocs-minify-plugin ≥0.7.0,<1.0.0 — HTML minification for built docs

**Build/Dev:**
- Docker + Docker Compose — containerized pipeline execution (`biorempp_snakemake_version/env/Dockerfile`, `docker-compose.yml`)
- GitHub Actions — CI for documentation build (`docs-ci.yml`)
- Read the Docs — hosted documentation deployment (`.readthedocs.yaml`)

## Key Dependencies

**R Packages (pipeline):**
- `readxl` — reading `.xlsx` input files (KEGG compounds, agency compounds, curations, classifications)
- `dplyr` — data manipulation (filtering, joining, summarising, arranging)
- `tidyr` — data tidying (`separate_rows` for multi-value compound class columns)
- `stringr` — string operations (regex extraction, trimming, pattern matching for enzyme terms)
- `readr` — reading delimited text files
- `jsonlite` — JSON serialization (metadata output, KEGG release info)
- `writexl` — writing `.xlsx` output files (Snakemake version uses `writexl` instead of `xlsx`)
- `xlsx` — writing `.xlsx` output (standalone `generate_database.R` uses `xlsx` with Java)
- `rstudioapi` — optional RStudio integration for working directory detection

**Python Packages (validation):**
- `great_expectations ≥1.12,<1.13` — expectation suites, checkpoints, data docs generation
- `pandas ≥2.0,<3.0` — DataFrame operations for validation inputs
- `PyYAML ≥6.0,<7.0` — parsing validation configuration YAML
- `jsonschema ≥4.0,<5.0` — JSON schema validation

**Python Packages (docs):**
- `pymdown-extensions ≥10.3,<11.0` — advanced Markdown extensions (superfences, arithmatex, tabbed, etc.)
- `Pygments ≥2.16.0` — syntax highlighting in documentation

## Configuration

**Environment:**
- No `.env` file detected; environment variables are read directly in Python validation scripts via `os.getenv()`:
  - `BIOREMPP_API_MAX_RETRIES` — number of retries for KEGG API calls (default: 6)
  - `BIOREMPP_API_TIMEOUT_SECONDS` — HTTP request timeout (default: 90)
  - `BIOREMPP_API_BACKOFF_BASE_SECONDS` — exponential backoff base (default: 1.0)
  - `BIOREMPP_API_BACKOFF_MAX_SECONDS` — maximum backoff cap (default: 30.0)
  - `BIOREMPP_API_BACKOFF_JITTER_RATIO` — backoff jitter ratio (default: 0.25)
  - `TZ=UTC` — timezone set in Docker container

**Build:**
- `biorempp_snakemake_version/config/config.yaml` — Snakemake pipeline config (version, paths, KEGG endpoints, output filenames, analysis top-N settings)
- `mkdocs.yml` — MkDocs site configuration (theme, plugins, navigation, markdown extensions)
- `.readthedocs.yaml` — Read the Docs build configuration (Python 3.11, PDF/epub formats)
- `.github/workflows/docs-ci.yml` — GitHub Actions CI configuration

## Platform Requirements

**Development:**
- Python 3.12+ (local venv)
- R 4.3+ with Java (for `xlsx` package used in standalone `generate_database.R`)
- Docker + Docker Compose (for containerized Snakemake pipeline)
- Windows or Linux/macOS (runner scripts provided for both)

**Production:**
- Docker container based on `rocker/tidyverse:4.3` with Python 3 installed alongside R
- Documentation deployed to Read the Docs at `https://biorempp-database.readthedocs.io`
- GitHub as source repository at `https://github.com/BioRemPP/biorempp_db`

---

*Stack analysis: 2026-05-17*
