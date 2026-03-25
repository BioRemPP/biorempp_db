# External Integrations

**Analysis Date:** 2026-03-24

## APIs & External Services

**KEGG REST API:**
- **Service:** KEGG (Kyoto Encyclopedia of Genes and Genomes)
- **What it's used for:** Real-time fetching of biological relationships (KO-to-EC, KO-to-Reaction, Compound-to-EC, Compound-to-Reaction, EC-to-Reaction links) and metadata
- **Base URL:** `https://rest.kegg.jp` (configured in `biorempp_snakemake_version/config/config.yaml`)
- **SDK/Client:** Native Python `urllib.request` HTTP client (no external SDK)
- **Endpoints used:**
  - `link/ko/ec` - KEGG Ortholog to Enzyme Commission links
  - `link/ko/reaction` - KEGG Ortholog to Reaction links
  - `link/compound/ec` - Compound to EC links
  - `link/cpd/reaction` - Compound to Reaction links
  - `link/ec/reaction` - EC to Reaction links
  - `list/cpd/` - Compound list
  - `info/kegg` - KEGG database metadata and version information
- **Authentication:** None (public API)
- **Timeout/Retry:** 3 retry attempts with exponential backoff (1s, 2s, 3s delays) in `biorempp_snakemake_version/workflow/scripts/validation/01_validate_keys_consistency_api.py`
- **Integration points:**
  - R script: `biorempp_snakemake_version/workflow/scripts/generation/03_fetch_kegg_data.R` - Initial KEGG data fetch
  - Python script: `biorempp_snakemake_version/workflow/scripts/validation/01_validate_keys_consistency_api.py` - API-based key consistency validation
  - Python script: `biorempp_snakemake_version/workflow/scripts/validation/02_validate_links_groundtruth_policy_api.py` - Policy-aware links ground-truth validation

## Data Storage

**Databases:**
- **Type:** File-based (no server-side database)
- **Primary outputs:**
  - CSV format: `results/database/biorempp_database_v1.0.0.csv` (configured in `biorempp_snakemake_version/config/config.yaml`)
  - Excel format: `results/database/biorempp_database_v1.0.0.xlsx`
- **Client:** R `readr` for reading, `writexl` for writing Excel; Python `csv` and `pandas` for CSV operations
- **Intermediate storage:** RDS (R Data Serialization) binary format used for inter-script data passing in `biorempp_snakemake_version/workflow/scripts/generation/`

**File Storage:**
- **Strategy:** Local filesystem only
- **Directory structure:**
  - Input data: `input_data/` (local Excel and text files for agencies, curated compounds, enzyme classifications)
  - Results: `results/` (database outputs, analysis JSON files, metadata, reports)
  - Workflow artifacts: `work/` (Snakemake temporary files)
  - Logs: `logs/` (Snakemake execution logs)
- **Supported input formats:**
  - Excel (`.xlsx`) - Agency compound lists in `input_data/compostos_todasagencias.xlsx`, curated data in `input_data/confirm_class_CURATED.xlsx`
  - Tab-separated text (`.txt`) - KEGG compound list in `input_data/kegglistcompounds.xlsx`, KO list in `input_data/kegglistko.txt`

**Caching:**
- None detected
- KEGG API results are fetched fresh on each validation run
- No in-memory or persistent cache mechanism

## Authentication & Identity

**Auth Provider:**
- None (public APIs and file-based data only)
- KEGG REST API is publicly accessible without authentication
- Great Expectations validation is internal to the pipeline

**Implementation:**
- No API keys or credentials required
- No authentication headers in HTTP requests

## Monitoring & Observability

**Error Tracking:**
- None detected (no external error tracking service like Sentry)

**Logs:**
- **Snakemake logs:** `logs/` directory (e.g., `logs/validate_keys_consistency.log`)
  - Configured via Snakemake rule `log:` directive in `biorempp_snakemake_version/workflow/rules/30_validation.smk`
- **R logging:** Custom logging functions in `biorempp_snakemake_version/workflow/lib/utils.R` (timestamp, level, message format)
- **Python logging:** `argparse`-driven CLI output with JSON-serialized report files
- **JSON reports:**
  - `results/metadata/keys_consistency_report.json` - API validation report with detailed parse statistics
  - `results/metadata/links_groundtruth_policy_report.json` - Policy adherence report
  - `results/reports/workflow_summary.json` - Aggregate workflow execution summary

**Approach:**
- Structured JSON output for programmatic consumption of validation results
- Text-based log files for human debugging
- Configuration-driven policy checks (fail on critical/warning conditions) in `biorempp_validation/config/validation.yaml`

## CI/CD & Deployment

**Hosting:**
- **Documentation:** Read the Docs (https://biorempp-database.readthedocs.io)
  - Auto-builds on GitHub pushes via `.readthedocs.yaml` configuration
  - Builds on Ubuntu 22.04 with Python 3.11
- **Source Code:** GitHub repository (https://github.com/BioRemPP/biorempp_db)
- **Container Registry:** Docker images are built locally; no external registry integration detected

**CI Pipeline:**
- **Read the Docs:** Automated documentation build and deployment on commit (MkDocs with Material theme)
- **Local execution:** Docker Compose for reproducible local/CI runs
- **No external CI service detected** (e.g., GitHub Actions, GitLab CI, Jenkins)

## Environment Configuration

**Required env vars:**
- None explicitly required by configuration files
- All configuration is YAML-based in `biorempp_snakemake_version/config/config.yaml`
- Docker Compose sets `TZ=UTC` environment variable in `biorempp_snakemake_version/env/docker-compose.yml`

**Secrets location:**
- No secrets management detected
- No `.env` files required
- API endpoints are public (no API keys)
- Input data files are version-controlled (no sensitive data detected)

## Webhooks & Callbacks

**Incoming:**
- None detected
- Pipeline is triggered manually via Snakemake commands or Docker Compose

**Outgoing:**
- None detected
- No webhook notifications for pipeline completion
- Results are written to local files only

## Data Sources

**Primary Data Sources:**
1. **KEGG Database** (https://rest.kegg.jp)
   - KO (Ortholog) to EC (Enzyme Commission) links
   - KO to Reaction links
   - Compound to EC links
   - Compound to Reaction links
   - EC to Reaction links
   - Compound metadata

2. **Environmental Agency Compound Lists** (manually curated)
   - Source file: `input_data/compostos_todasagencias.xlsx`
   - Agencies included: ATSDR, CONAMA, EPA, EPC, IARC1, IARC2A, IARC2B, PSL, WFD (from `biorempp_validation/config/validation.yaml`)

3. **Manual Curation Data**
   - Confirmed compound classifications: `input_data/confirm_class_CURATED.xlsx`
   - Missing compounds found via curation: `input_data/missing_compounds_founds_curated.xlsx`
   - Enzyme classifications: `input_data/enzymes_unique.txt`

4. **KEGG Reference Lists**
   - KO (Ortholog) list: `input_data/kegglistko.txt`
   - Compound list: `input_data/kegglistcompounds.xlsx`

## Validation Integration Points

**Data Contract Enforcement:**
- Expected database columns defined in `biorempp_validation/config/validation.yaml`
- Expected reference agencies and compound classes defined in same file
- Drift thresholds for row counts, unique compounds, unique KOs, genes, and enzyme activities

**Great Expectations Context:**
- Located in `biorempp_validation/great_expectations/` directory
- Expectation suites and checkpoints configured for automated validation

**Validation Workflow Rules:**
- `biorempp_snakemake_version/workflow/rules/30_validation.smk`:
  - `validate_keys_consistency` rule - Queries KEGG API to validate database key consistency
  - `validate_links_groundtruth_policy` rule - Validates database links against KEGG API with policy enforcement

---

*Integration audit: 2026-03-24*
