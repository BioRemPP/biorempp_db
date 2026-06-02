# External Integrations

_Last updated: 2026-05-31_

## Summary

BioRemPP DB integrates with one external API — the KEGG REST API — for all biological relationship data. This API is called from two independent subsystems: the R generation pipeline (for database construction) and the Python validation scripts (for KEGG link caching and consistency checks). Great Expectations provides the internal data-contract validation layer, operating entirely offline against pipeline outputs. All other integrations are infrastructure-level (Docker Hub base images, Read the Docs, GitHub Actions).

---

## APIs & External Services

### KEGG REST API

**Base URL:** `https://rest.kegg.jp` (configured in `biorempp_snakemake_version/config/config.yaml`)

**Purpose:** Primary biological data source. Provides all compound–KO–EC–reaction relationship data used to build the database.

**Endpoints used:**

| Endpoint Slug              | Config Key                 | Returns                              |
|---------------------------|----------------------------|--------------------------------------|
| `link/ko/ec`              | `ko_ec_links`              | KO ↔ EC number pairs                |
| `link/ko/reaction`        | `ko_reaction_links`        | KO ↔ reaction ID pairs              |
| `link/compound/ec`        | `compound_ec_links`        | Compound ↔ EC number pairs          |
| `link/cpd/reaction`       | `compound_reaction_links`  | Compound ↔ reaction ID pairs        |
| `link/ec/reaction`        | `ec_reaction_links`        | EC ↔ reaction ID pairs              |
| `list/reaction`           | _(inline)_                 | Reaction ID → description list      |
| `list/cpd/`               | _(inline)_                 | Compound ID → compound name list    |
| `info/kegg`               | `info_endpoint`            | KEGG release metadata (version text)|

**Response format:** Tab-separated plain text (`\t` delimiter); two-column pairs per line.

**Authentication:** None (public API).

**Rate limiting:** No explicit rate limits enforced by the API; no `Retry-After` header handling. The pipeline implements defensive retry logic instead.

**Retry strategy (identical implementation in R and Python):**
- Max retries: 6 (env var `BIOREMPP_API_MAX_RETRIES`)
- Timeout per request: 90 s (env var `BIOREMPP_API_TIMEOUT_SECONDS`)
- Backoff: exponential with jitter — `base * 2^(attempt-1)` capped at `max`, then multiplied by `uniform(1 ± jitter_ratio)`
  - Base: 1.0 s (`BIOREMPP_API_BACKOFF_BASE_SECONDS`), Max: 30.0 s (`BIOREMPP_API_BACKOFF_MAX_SECONDS`), Jitter: ±25% (`BIOREMPP_API_BACKOFF_JITTER_RATIO`)
- HTTP 429 and 5xx → retryable. HTTP 4xx (except 429) → non-retryable, fails immediately.

**R client:** `biorempp_snakemake_version/workflow/scripts/generation/03_fetch_kegg_data.R`
- Uses `httr::GET()` with `httr::timeout()`
- Fetches all 7 endpoints; saves combined bundle as `work/kegg_data.rds` (R binary format)
- Column orientation auto-detected and canonicalised via `canonicalize_link_endpoint()` using regex patterns defined in `biorempp_snakemake_version/workflow/lib/io_contracts.R`

**R info fetcher:** `biorempp_snakemake_version/workflow/scripts/generation/02_fetch_kegg_info.R`
- Uses `readLines()` directly (no `httr`)
- Fetches `info/kegg`; extracts release version via regex `[0-9]+(?:\.[0-9]+)?(?:\+)?`
- Saves to `results/metadata/kegg_release.json`

**Python client:** `biorempp_snakemake_version/workflow/scripts/validation/kegg_api_client.py`
- Uses `urllib.request.urlopen()` (stdlib only, no external HTTP library)
- Same retry/backoff parameters as R client

**Python cache script:** `biorempp_snakemake_version/workflow/scripts/validation/cache_kegg_links.py`
- Fetches all 5 link endpoints; writes each to `cache/kegg_link_cache/{name}.tsv`
- Cache is populated by Snakemake rule `fetch_kegg_link_cache` in `biorempp_snakemake_version/workflow/rules/30_validation.smk`

**Caching model:**
- The R generation path does **not** cache to disk between steps; KEGG data is held in memory as an RDS file (`work/kegg_data.rds`).
- The Python validation path caches KEGG link endpoints as `.tsv` files under `cache/kegg_link_cache/` before running validation rules. These are Snakemake outputs and are re-fetched only when missing or explicitly invalidated.

**Value patterns (used for response validation):**
- KO: `^(ko:)?K\d{5}$`
- EC: `^(ec:)?[0-9]+\.[0-9]+\.[0-9]+\.[0-9A-Za-z\-]+$`
- Reaction: `^(rn:)?R\d{5}$`
- Compound: `^(cpd:)?C\d{5}$`

---

## Data Validation Layer — Great Expectations

**Package:** `great_expectations` 1.12.3 (pinned in `biorempp_validation/requirements-dev.lock.txt`)

**Entrypoint:** `biorempp_validation/src/biorempp_validation/run_validation.py`
- CLI command: `biorempp-validate --config <path>` (registered in `biorempp_validation/pyproject.toml`)
- Config: `biorempp_validation/config/validation.yaml`

**Context type:** Ephemeral in-memory (`create_context()` in `biorempp_validation/src/biorempp_validation/gx_context.py`); no persistent GX store. All suites are loaded from JSON files at runtime.

**Datasource type:** Pandas in-memory (`create_pandas_datasource()`). All data is loaded into DataFrames before being passed to GX.

**Expectation suites (JSON files in `biorempp_validation/great_expectations/expectations/`):**

| Suite file                          | Severity  | Dataset target              | Validation mode                    |
|------------------------------------|-----------|-----------------------------|------------------------------------|
| `database_critical.json`           | Critical  | `database_csv`              | Always                             |
| `database_warning.json`            | Warning   | `database_csv`              | Always                             |
| `metadata_kegg_critical.json`      | Critical  | `metadata_kegg`             | `current_artifacts`                |
| `pipeline_reports_critical.json`   | Critical  | `pipeline_reports`          | Always                             |
| `analysis_json_critical.json`      | Critical  | `analysis_critical`         | `internal_consistency` mode only   |
| `analysis_json_warning.json`       | Warning   | `analysis_warning`          | `internal_consistency` mode only   |
| `analysis_json_exact_critical.json`| Critical  | `analysis_internal_consistency` / `analysis_regression` | Cloned per mode |
| `cross_consistency_critical.json`  | Critical  | `cross_consistency`         | `internal_consistency` mode only   |

**Checkpoints:**
- `biorempp_validation/great_expectations/checkpoints/critical_gate.yml` — halts pipeline on failure when `fail_on_critical: true`
- `biorempp_validation/great_expectations/checkpoints/warning_report.yml` — halts pipeline on failure when `fail_on_warning: true`

**Validation modes (configured in `biorempp_validation/config/validation.yaml`):**
- `internal_consistency` — checks that analysis JSON outputs are internally consistent with the database CSV
- `regression_detection` — compares current outputs against a frozen baseline at `biorempp_validation/baselines/release_v1_1_0_kegg_118_0plus/`

**Config-driven thresholds** (applied dynamically at runtime, overriding suite JSON defaults):
- `row_count`: 118,000–130,000
- `unique_compounds`: 360–410
- `unique_ko`: 1,440–1,650
- `unique_genesymbol`: 1,410–1,625
- `unique_genename`: 1,320–1,525
- `unique_enzyme_activity`: 185–230

**Outputs (written to `biorempp_validation/results/`):**
- `critical_checkpoint_result.json`
- `warning_checkpoint_result.json`
- `validation_summary.json`
- `data_docs/index.html` (summary HTML page, when `generate_summary_page: true`)

---

## Container Infrastructure

### Docker Hub — rocker/tidyverse

**Image:** `rocker/tidyverse:4.4`
**Digest:** `sha256:7b6ad006caffcbae246f8f3e761a2ec268b2101a25d54266a27c1bce6ced0689`
**Dockerfile:** `biorempp_snakemake_version/env/Dockerfile`
**Purpose:** R 4.4 runtime with tidyverse pre-installed; Python 3 added on top for Snakemake.

### Docker Hub — python:3.11-slim-bookworm

**Image:** `python:3.11-slim-bookworm`
**Digest:** `sha256:8dca233de9f3d9bb410665f00a4da6dd06f331083137e0e98ccf227236fcc438`
**Dockerfile:** `biorempp_validation/env/Dockerfile`
**Purpose:** Minimal Python runtime for the Great Expectations validation package.

---

## Documentation Hosting — Read the Docs

**Platform:** Read the Docs
**Config:** `.readthedocs.yaml`
**Site URL:** `https://biorempp-database.readthedocs.io`
**Build OS:** ubuntu-22.04, Python 3.11
**Formats built:** HTML, PDF, ePub
**Python deps:** `requirements.txt` (MkDocs + Material theme)
**No authentication required** — public documentation site.

---

## CI/CD — GitHub Actions

**Workflow:** `.github/workflows/docs-ci.yml`
**Trigger:** Push/PR to `main`/`dev` touching `docs/**`, `mkdocs.yml`, or `scripts/build-docs.sh`
**Actions used:**
- `actions/checkout@v4`
- `actions/setup-python@v5` (Python 3.11 with pip cache)
- `actions/upload-artifact@v4`

**No pipeline CI detected** — Snakemake pipeline is executed manually via Docker Compose; there is no automated CI workflow for running the database generation or validation pipeline.

---

## Local Input Data

**Source:** Manual curation + environmental agency data (not fetched from an API).

**Required input files** (must be placed in `../input_data/` relative to `biorempp_snakemake_version/`):

| File                                  | Format  | Purpose                                |
|---------------------------------------|---------|----------------------------------------|
| `kegglistcompounds.xlsx`              | Excel   | KEGG compound list baseline            |
| `compostos_todasagencias.xlsx`        | Excel   | Compounds from all environmental agencies |
| `missing_compounds_founds_curated.xlsx` | Excel | Manually curated missing compounds    |
| `confirm_class_CURATED.xlsx`          | Excel   | Curated compound class assignments     |
| `kegglistko.txt`                      | Text    | KEGG KO list                           |
| `enzymes_unique.txt`                  | Text    | Unique enzyme activity annotations     |

These files are loaded in Snakemake rule `load_local_data` via `biorempp_snakemake_version/workflow/scripts/generation/01_load_local_data.R`.

---

## Monitoring & Observability

**Error Tracking:** None (no Sentry, Datadog, or equivalent).
**Logging:** Structured log messages via `log_message()` in `biorempp_snakemake_version/workflow/lib/utils.R` and `print()` statements in Python scripts. All rule output redirected to per-rule `.log` files under `biorempp_snakemake_version/logs/` via Snakemake `log:` directives.
**Metrics:** No runtime metrics collection.

---

## Webhooks & Callbacks

**Incoming:** None.
**Outgoing:** None.

---

*Integration audit: 2026-05-31*
