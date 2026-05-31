# INTEGRATIONS — BioRemPP DB 1.0.0

> Last mapped: 2026-05-31

## Summary

BioRemPP DB 1.0.0 integrates with a single external web service (the KEGG REST API) for live database construction, reads six locally curated flat-file inputs, and writes its outputs as CSV/XLSX/JSON. Two separate integration layers exist: the R-based KEGG fetcher that builds the database, and the Python-based KEGG cache fetcher used by validation. No cloud storage, message queues, authentication services, or relational databases are used. Documentation is published through GitHub Actions CI and Read the Docs.

---

## External APIs & Web Services

### KEGG REST API

**Purpose:** Authoritative source for KO–EC, KO–reaction, compound–EC, compound–reaction, EC–reaction links, compound names, reaction descriptions, and KEGG release metadata. All biologically meaningful relationships in the final database derive from these endpoints.

**Base URL:** `https://rest.kegg.jp`  
**Protocol:** HTTP GET, plain-text TSV responses (tab-separated)  
**Authentication:** None (public API)

**Endpoints consumed:**

| Endpoint path | Data returned | Consumer |
|---------------|---------------|----------|
| `link/ko/ec` | KO ↔ EC pairs | `03_fetch_kegg_data.R` and `cache_kegg_links.py` |
| `link/ko/reaction` | KO ↔ Reaction pairs | `03_fetch_kegg_data.R` and `cache_kegg_links.py` |
| `link/compound/ec` | Compound ↔ EC pairs | `03_fetch_kegg_data.R` and `cache_kegg_links.py` |
| `link/cpd/reaction` | Compound ↔ Reaction pairs | `03_fetch_kegg_data.R` and `cache_kegg_links.py` |
| `link/ec/reaction` | EC ↔ Reaction pairs | `03_fetch_kegg_data.R` and `cache_kegg_links.py` |
| `list/reaction` | Reaction IDs + descriptions | `03_fetch_kegg_data.R` |
| `list/cpd/` | Compound IDs + names | `03_fetch_kegg_data.R` |
| `info/kegg` | Release version metadata | `02_fetch_kegg_info.R` |

**Configuration:** Base URL and all endpoint paths are externalized in `biorempp_snakemake_version/config/config.yaml` under the `kegg:` block. The R fetch layer uses `httr::GET`; the Python cache layer uses `urllib.request.urlopen`.

**Retry policy (both layers, configurable via env vars):**
- Max retries: 6 (`BIOREMPP_API_MAX_RETRIES`)
- Timeout: 90 s (`BIOREMPP_API_TIMEOUT_SECONDS`)
- Exponential backoff base: 1.0 s (`BIOREMPP_API_BACKOFF_BASE_SECONDS`)
- Backoff cap: 30 s (`BIOREMPP_API_BACKOFF_MAX_SECONDS`)
- Jitter ratio: 25 % (`BIOREMPP_API_BACKOFF_JITTER_RATIO`)
- HTTP 429 and 5xx are retried; other non-200 status codes abort immediately

**KEGG data caching:** Raw TSV payloads from the five link endpoints are persisted to `biorempp_snakemake_version/work/kegg_link_cache/` as `.tsv` files by `workflow/scripts/validation/cache_kegg_links.py` (Snakemake rule `fetch_kegg_link_cache`). Subsequent validation rules (`validate_keys_consistency`, `validate_links_groundtruth_policy`) read from disk rather than re-fetching.

**Token patterns matched against KEGG responses:**
- KO: `K\d{5}` (e.g., `K00001`)
- Compound: `C\d{5}` (e.g., `C00001`)
- Reaction: `R\d{5}` (e.g., `R00001`)
- EC: `\d+\.\d+\.\d+\.[0-9A-Za-z\-]+` (e.g., `1.1.1.1`)

---

## Local File-Based Inputs

All input files reside in `input_data/` (and mirrored in `biorempp_snakemake_version/input_data/`). These are manually curated and version-controlled.

| File | Format | Contents | Loaded by |
|------|--------|----------|-----------|
| `kegglistcompounds.xlsx` | Excel (.xlsx) | KEGG compound ID → compound name mapping (pre-fetched, curated) | `01_load_local_data.R` → `load_kegg_compounds()` |
| `compostos_todasagencias.xlsx` | Excel (.xlsx) | Compound IDs → environmental agency reference codes (`referenceAG`) | `01_load_local_data.R` → `load_agency_compounds()` |
| `missing_compounds_founds_curated.xlsx` | Excel (.xlsx) | Manually curated compound–KO pairs not covered by KEGG links | `01_load_local_data.R` → `load_curated_compounds()` |
| `confirm_class_CURATED.xlsx` | Excel (.xlsx) | Compound class classification (Aliphatic, Aromatic, Metal, etc.) | `01_load_local_data.R` → `load_compound_classes()` |
| `kegglistko.txt` | TSV (.txt) | KO ID → gene symbol + gene name mapping | `01_load_local_data.R` → `load_kegg_ko_list()` |
| `enzymes_unique.txt` | Plain text (.txt) | List of unique enzyme activity terms | `01_load_local_data.R` → `load_enzyme_terms()` |

**Environmental agencies encoded in `referenceAG`:** ATSDR, CONAMA, EPA, EPC, IARC1, IARC2A, IARC2B, PSL, WFD

**Compound classes encoded in `compoundclass`:** Aliphatic, Aromatic, Chlorinated, Halogenated, Inorganic, Metal, Nitrogen-containing, Organometallic, Organophosphorus, Organosulfur, Polyaromatic, Sulfur-containing

---

## Pipeline Output Files (File-Based Integration Points)

These files are produced by the Snakemake pipeline and consumed by the Great Expectations validation layer.

| File | Format | Producer | Consumer |
|------|--------|----------|----------|
| `results/database/biorempp_database_v1.1.0.csv` | CSV (`;` delimiter, `"` quoted, UTF-8) | `07_extract_enzymes_export.R` | GX validation, reporting |
| `results/database/biorempp_database_v1.1.0.xlsx` | Excel (.xlsx) | `07_extract_enzymes_export.R` | End users |
| `results/analysis/*.json` (9 files) | JSON | Analysis R scripts (`01`–`09`) | GX validation, reporting |
| `results/metadata/kegg_release.json` | JSON | `02_fetch_kegg_info.R` | Analysis `07_metadata.R`, reporting, GX validation |
| `results/metadata/keys_consistency_report.json` | JSON | `01_validate_keys_consistency_api.py` | Reporting |
| `results/metadata/links_groundtruth_policy_report.json` | JSON | `02_validate_links_groundtruth_policy_api.py` | Reporting |
| `results/reports/workflow_summary.json` | JSON | `build_run_report.py` | End users, archival |
| `work/kegg_link_cache/*.tsv` (5 files) | TSV | `cache_kegg_links.py` | Validation Python scripts |
| `work/*.rds` | R binary (RDS) | Generation R scripts | Subsequent generation rules |

**Database schema (CSV/XLSX columns):** `cpd`, `compoundclass`, `ko`, `ec`, `reaction`, `reaction_description`, `referenceAG`, `compoundname`, `genesymbol`, `genename`, `enzyme_activity`

---

## CLI Tools Called as Subprocesses

All subprocess invocations are declared in Snakemake `shell:` blocks.

| Command | Invoked from | Purpose |
|---------|-------------|---------|
| `Rscript workflow/scripts/generation/00_check_inputs.R` | `00_preflight.smk` | Validate presence of all input files |
| `Rscript workflow/scripts/generation/01_load_local_data.R` | `10_generation.smk` | Load all local curated inputs into RDS bundle |
| `Rscript workflow/scripts/generation/02_fetch_kegg_info.R` | `10_generation.smk` | Fetch KEGG release metadata |
| `Rscript workflow/scripts/generation/03_fetch_kegg_data.R` | `10_generation.smk` | Fetch all KEGG link endpoints into RDS bundle |
| `Rscript workflow/scripts/generation/04_merge_relationships.R` | `10_generation.smk` | Join local data with KEGG links |
| `Rscript workflow/scripts/generation/05_add_classifications.R` | `10_generation.smk` | Attach compound class labels |
| `Rscript workflow/scripts/generation/06_enrich_gene_info.R` | `10_generation.smk` | Attach gene symbol/name from KO list |
| `Rscript workflow/scripts/generation/07_extract_enzymes_export.R` | `10_generation.smk` | Produce final CSV + XLSX database |
| `Rscript workflow/scripts/analysis/01_basic_statistics.R` … `09_merge_complete_analysis.R` | `20_analysis.smk` | Generate JSON statistics outputs |
| `python3 workflow/scripts/validation/cache_kegg_links.py` | `30_validation.smk` | Download and cache KEGG link TSVs |
| `python3 workflow/scripts/validation/01_validate_keys_consistency_api.py` | `30_validation.smk` | Validate KO/EC/CPD/reaction key consistency |
| `python3 workflow/scripts/validation/02_validate_links_groundtruth_policy_api.py` | `30_validation.smk` | Validate link coverage against KEGG ground truth |
| `python3 workflow/scripts/reporting/build_run_report.py` | `90_reporting.smk` | Assemble workflow summary JSON |
| `biorempp-validate --config biorempp_validation/config/validation.yaml` | Manual / CI | Run Great Expectations suite over pipeline outputs |

---

## Documentation & Deployment Integrations

### GitHub Actions

- Workflow: `.github/workflows/docs-ci.yml`
- Trigger: push/PR on `main`/`dev` when `docs/**`, `mkdocs.yml`, or `scripts/build-docs.sh` change
- Runner: `ubuntu-latest`, Python 3.11
- Steps: checkout → setup Python → `./scripts/build-docs.sh install` → `./scripts/build-docs.sh build` → upload artifact (`site/`, 7-day retention)
- Repository referenced: `https://github.com/BioRemPP/biorempp_db`

### Read the Docs

- Config: `.readthedocs.yaml`
- OS: ubuntu-22.04, Python 3.11
- Builds from `mkdocs.yml`
- Published URL: `https://biorempp-database.readthedocs.io`
- Formats: HTML (primary), PDF, ePub
- Dependencies: `requirements.txt` (docs-only)

### External JavaScript (CDN, documentation only)

- `https://polyfill.io/v3/polyfill.min.js?features=es6` — ES6 polyfills for MathJax
- `https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js` — LaTeX math rendering in docs

---

## Data Storage

**Databases:** None. No SQL or NoSQL database is used. All persistent state is flat files.

**File storage:** Local filesystem only. No S3, GCS, or Azure Blob integration.

**Caching:** KEGG API responses are cached to `biorempp_snakemake_version/work/kegg_link_cache/*.tsv` by a dedicated Snakemake rule (`fetch_kegg_link_cache`). Snakemake's own `.snakemake/` metadata directory tracks rule completion and file timestamps.

---

## Authentication & Secrets

No authentication is required for any integration:
- KEGG REST API: public, unauthenticated
- GitHub Actions: uses default `GITHUB_TOKEN` (no custom secrets observed)
- Read the Docs: configured via `.readthedocs.yaml` in-repo

No `.env` file, secrets directory, or credential files were observed (existence checked, contents not read).

---

## Confidence

- HIGH: KEGG API base URL, all endpoint paths, and both HTTP client implementations observed directly in `config/config.yaml`, `02_fetch_kegg_info.R`, `03_fetch_kegg_data.R`, `kegg_api_client.py`, `io_contracts.R`
- HIGH: All input file names and formats confirmed from `io_contracts.R` (`REQUIRED_INPUT_FILES`), `01_load_local_data.R`, and directory listing of `input_data/`
- HIGH: All CLI subprocess invocations confirmed from `.smk` rule `shell:` blocks
- HIGH: CI/CD integrations confirmed from `.github/workflows/docs-ci.yml` and `.readthedocs.yaml`
- HIGH: Output file schema confirmed from `validation.yaml` `database_contract.expected_columns`
