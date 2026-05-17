# External Integrations

**Analysis Date:** 2026-05-17

## APIs & External Services

**KEGG REST API (Primary data source):**
- Service: KEGG (Kyoto Encyclopedia of Genes and Genomes) — `https://rest.kegg.jp`
- Used for: fetching KO-EC links, KO-Reaction links, compound-EC links, compound-Reaction links, compound lists, KO lists, and KEGG release metadata
- Client: R native `read.csv(url, ...)` and `readLines(url)` in `generate_database.R` and `biorempp_snakemake_version/workflow/scripts/generation/`; Python `urllib.request.urlopen` in `biorempp_snakemake_version/workflow/scripts/validation/01_validate_keys_consistency_api.py`
- Auth: None — public REST API, no authentication required
- Endpoints used:
  - `link/ko/ec` — KO to EC number mappings
  - `link/ko/reaction` — KO to reaction mappings
  - `link/compound/ec` — compound to EC mappings
  - `link/cpd/reaction` — compound to reaction mappings
  - `link/ec/reaction` — EC to reaction mappings (validation only)
  - `list/cpd/` — full compound list with names
  - `info/kegg` — KEGG release version metadata
- Retry behavior: configurable via env vars (`BIOREMPP_API_MAX_RETRIES`, `BIOREMPP_API_TIMEOUT_SECONDS`, `BIOREMPP_API_BACKOFF_BASE_SECONDS`, `BIOREMPP_API_BACKOFF_MAX_SECONDS`, `BIOREMPP_API_BACKOFF_JITTER_RATIO`); exponential backoff with jitter in Python scripts
- Config key: `kegg.base_url` in `biorempp_snakemake_version/config/config.yaml`

**MathJax CDN:**
- Service: jsDelivr CDN — `https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js`
- Used for: rendering mathematical notation in documentation pages
- Auth: None

**Polyfill.io:**
- Service: `https://polyfill.io/v3/polyfill.min.js?features=es6`
- Used for: ES6 polyfills in documentation site
- Auth: None

## Data Storage

**Databases:**
- No relational or hosted database is used. The pipeline generates flat-file databases (CSV and XLSX formats) as its primary outputs.

**Input flat files (local):**
- `input_data/kegglistcompounds.xlsx` — local KEGG compound reference list
- `input_data/compostos_todasagencias.xlsx` — compounds from 9 environmental agencies
- `input_data/missing_compounds_founds_curated.xlsx` — manually curated compound-KO mappings
- `input_data/confirm_class_CURATED.xlsx` — manually curated compound class annotations
- `input_data/kegglistko.txt` — pre-downloaded KEGG KO list (tab-delimited: ko, genesymbol, genename)
- `input_data/enzymes_unique.txt` — unique enzyme activity terms for pattern matching
- Same files duplicated under `biorempp_snakemake_version/input_data/`

**Output flat files (generated):**
- `output_data/biorempp_database_v1.0.0.csv` — standalone pipeline output (CSV)
- `output_data/biorempp_database_v1.0.0.xlsx` — standalone pipeline output (Excel)
- `biorempp_snakemake_version/results/database/biorempp_database_v1.1.0.csv` — Snakemake pipeline output (delimiter: `;`, quoted)
- `biorempp_snakemake_version/results/database/biorempp_database_v1.1.0.xlsx` — Snakemake pipeline output (Excel)
- `biorempp_snakemake_version/results/analysis/*.json` — statistics JSON files (basic, compound, KO, enzyme, gene, crosstab, executive summary, complete)
- `biorempp_snakemake_version/results/metadata/kegg_release.json` — KEGG release version snapshot
- `biorempp_snakemake_version/results/metadata/keys_consistency_report.json` — API validation report
- `biorempp_snakemake_version/results/metadata/links_groundtruth_policy_report.json` — ground-truth link validation report
- `biorempp_snakemake_version/results/reports/workflow_summary.json` — Snakemake run summary

**Intermediate work files (Snakemake):**
- `biorempp_snakemake_version/work/local_data.rds` — loaded local data (R serialized)
- `biorempp_snakemake_version/work/kegg_data.rds` — fetched KEGG API data
- `biorempp_snakemake_version/work/merged_compounds.rds` — merged compound relationships
- `biorempp_snakemake_version/work/classified_compounds.rds` — compounds with classifications
- `biorempp_snakemake_version/work/enriched_compounds.rds` — compounds with gene info

**File Storage:**
- Local filesystem only. No cloud storage (S3, GCS, Azure Blob, etc.) is used.

**Caching:**
- Snakemake metadata cache at `biorempp_snakemake_version/.snakemake/` (file checksums and DAG state for incremental builds)
- pip cache used via `cache: 'pip'` in GitHub Actions CI

## Authentication & Identity

**Auth Provider:** None — the project has no user authentication layer. All external services (KEGG API, CDNs) are public and unauthenticated.

## Monitoring & Observability

**Error Tracking:** None — no third-party error tracking service (Sentry, Rollbar, etc.) is configured.

**Logs:**
- Snakemake rule logs written to `biorempp_snakemake_version/logs/` (one `.log` file per rule, e.g., `fetch_kegg_info.log`, `load_local_data.log`)
- Snakemake internal logs at `biorempp_snakemake_version/.snakemake/log/` (timestamped full workflow logs)
- R scripts use `message()` for structured console output with prefixes (`✓`, `⚠`, `✗`)
- Python validation scripts print JSON reports to stdout

## CI/CD & Deployment

**Hosting:**
- Documentation: Read the Docs (`https://biorempp-database.readthedocs.io`); configured via `.readthedocs.yaml`
- Source code: GitHub (`https://github.com/BioRemPP/biorempp_db`)

**CI Pipeline:**
- GitHub Actions (`docs-ci.yml`) — triggers on push to `main`/`dev` or PRs to `main` when `docs/**`, `mkdocs.yml`, `scripts/build-docs.sh`, or the workflow file change
- Steps: Python 3.11 setup → `pip install` (docs dependencies) → `mkdocs build` → artifact upload (`site/`, 7-day retention)
- Does NOT run the data pipeline or validation in CI

**Container Runtime:**
- Docker — `biorempp_snakemake_version/env/Dockerfile` builds from `rocker/tidyverse:4.3`, installs Python 3, pip, Snakemake, and R packages
- Docker Compose — `biorempp_snakemake_version/env/docker-compose.yml` mounts the project root at `/workspace` and runs Snakemake with 2 cores

## Environment Configuration

**Required environment variables (runtime, optional — all have defaults):**
- `BIOREMPP_API_MAX_RETRIES` — KEGG API retry count (default: 6)
- `BIOREMPP_API_TIMEOUT_SECONDS` — HTTP timeout in seconds (default: 90)
- `BIOREMPP_API_BACKOFF_BASE_SECONDS` — exponential backoff base in seconds (default: 1.0)
- `BIOREMPP_API_BACKOFF_MAX_SECONDS` — maximum backoff cap in seconds (default: 30.0)
- `BIOREMPP_API_BACKOFF_JITTER_RATIO` — jitter ratio for backoff (default: 0.25)
- `TZ` — timezone (set to `UTC` in Docker; not required locally)

**Secrets location:** None detected. No secret management system, credentials files, or `.env` files are present or required.

**Configuration files:**
- `biorempp_snakemake_version/config/config.yaml` — pipeline version, paths, KEGG endpoint names, output filenames, analysis parameters
- `biorempp_validation/config/validation.yaml` — Great Expectations validation settings (paths, policy, database contract, drift thresholds, expected columns, agency list, compound class list)

## Webhooks & Callbacks

**Incoming:** None

**Outgoing:** None

## Data Sources and Data Lineage

**External data sources:**
1. KEGG REST API (`https://rest.kegg.jp`) — live fetched at pipeline runtime; KEGG release version captured in `results/metadata/kegg_release.json` for reproducibility
2. Environmental agency compound lists — 9 agencies encoded in `input_data/compostos_todasagencias.xlsx` (pre-downloaded, local file)

**Manual curation layers:**
1. `input_data/missing_compounds_founds_curated.xlsx` — hand-curated compound-KO pairs for compounds not found automatically
2. `input_data/confirm_class_CURATED.xlsx` — hand-curated compound class annotations
3. `input_data/enzymes_unique.txt` — curated list of enzyme activity terms used for regex extraction

**Data sinks:**
- CSV and XLSX files in `output_data/` (standalone) or `biorempp_snakemake_version/results/database/` (Snakemake)
- JSON analysis and metadata reports in `biorempp_snakemake_version/results/`
- Validation reports in `biorempp_validation/` output directory (configured via `validation.yaml`)

---

*Integration audit: 2026-05-17*
