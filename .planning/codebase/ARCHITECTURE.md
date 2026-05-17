<!-- refreshed: 2026-05-17 -->
# Architecture

**Analysis Date:** 2026-05-17

## System Overview

BioRemPP is a bioinformatics database generation and validation system. It integrates data from environmental regulatory agencies, KEGG (Kyoto Encyclopedia of Genes and Genomes), and manual curation to produce a curated bioremediation compound-gene database. The system has two execution modes: a standalone R script (`generate_database.R`) for v1.0.0 and a full Snakemake pipeline (`biorempp_snakemake_version/`) for v1.1.0.

```text
┌────────────────────────────────────────────────────────────────────────┐
│                          Input Layer                                    │
│  Local files (XLSX/TXT)           KEGG REST API                        │
│  `input_data/`                    `https://rest.kegg.jp`               │
└──────────────────────────┬─────────────────────────┬───────────────────┘
                           │                         │
                           ▼                         ▼
┌────────────────────────────────────────────────────────────────────────┐
│               Generation Pipeline (Snakemake + R)                      │
│  `biorempp_snakemake_version/Snakefile`                                │
│  `biorempp_snakemake_version/workflow/rules/10_generation.smk`         │
│  `biorempp_snakemake_version/workflow/scripts/generation/`             │
└──────────────────────────────────────┬─────────────────────────────────┘
                                       │
                                       ▼
┌────────────────────────────────────────────────────────────────────────┐
│                    Database Output                                      │
│  `biorempp_snakemake_version/results/database/`                        │
│  biorempp_database_v1.1.0.csv / .xlsx                                  │
└──────────┬──────────────────────────────────────────────┬──────────────┘
           │                                              │
           ▼                                              ▼
┌──────────────────────────┐              ┌───────────────────────────────┐
│  Analysis (R)            │              │  KEGG Validation (Python)     │
│  `rules/20_analysis.smk` │              │  `rules/30_validation.smk`    │
│  `scripts/analysis/`     │              │  `scripts/validation/`        │
└──────────┬───────────────┘              └──────────────┬────────────────┘
           │                                             │
           ▼                                             ▼
┌────────────────────────────────────────────────────────────────────────┐
│              Results / Metadata / Reports Layer                        │
│  `results/analysis/*.json`  `results/metadata/*.json`                 │
│  `results/reports/workflow_summary.json`                               │
└──────────────────────────────────────┬─────────────────────────────────┘
                                       │
                                       ▼
┌────────────────────────────────────────────────────────────────────────┐
│           Great Expectations Validation (Python package)               │
│  `biorempp_validation/src/biorempp_validation/`                        │
│  `biorempp_validation/great_expectations/`                             │
└────────────────────────────────────────────────────────────────────────┘
```

## Component Responsibilities

| Component | Responsibility | File |
|-----------|----------------|------|
| Snakemake Orchestrator | DAG-based workflow coordination | `biorempp_snakemake_version/Snakefile` |
| Preflight Check | Validates input file presence before pipeline runs | `workflow/rules/00_preflight.smk` |
| Generation Rules | Declares R-script execution order for database build | `workflow/rules/10_generation.smk` |
| Analysis Rules | Declares R-script execution for statistical summaries | `workflow/rules/20_analysis.smk` |
| KEGG Validation Rules | Declares Python-script validation against live KEGG API | `workflow/rules/30_validation.smk` |
| Reporting Rule | Assembles final workflow summary JSON with checksums | `workflow/rules/90_reporting.smk` |
| IO Contracts (R) | Canonical column names, KEGG endpoint definitions, value patterns | `workflow/lib/io_contracts.R` |
| Utils (R) | Shared CLI argument parsing, package loading helpers | `workflow/lib/utils.R` |
| Generation Scripts (R) | 8 R scripts implementing step-by-step data transformation | `workflow/scripts/generation/` |
| Analysis Scripts (R) | 9 R scripts computing per-entity statistics and metadata | `workflow/scripts/analysis/` |
| Validation Scripts (Python) | 2 Python scripts checking keys and link correctness via KEGG API | `workflow/scripts/validation/` |
| Reporting Script (Python) | Builds `workflow_summary.json` with file hashes | `workflow/scripts/reporting/build_run_report.py` |
| GX Validation Package | Great Expectations-based data contract enforcement | `biorempp_validation/src/biorempp_validation/` |
| Standalone R Script | Original monolithic v1.0.0 generator (no Snakemake) | `generate_database.R` |

## Pattern Overview

**Overall:** Staged ETL pipeline with Snakemake DAG orchestration

**Key Characteristics:**
- Each Snakemake rule corresponds to exactly one R or Python script invoked via shell
- Intermediate data is serialized as `.rds` files (R binary) inside `work/`; final outputs are CSV/XLSX and JSON
- All scripts consume configuration exclusively from `config/config.yaml` via CLI flags (no hardcoded paths in scripts)
- IO contracts are centralized in `workflow/lib/io_contracts.R`, consumed by all generation R scripts
- The GX validation module runs independently against the `results/` output of the Snakemake pipeline

## Layers

**Input Layer:**
- Purpose: Curated source data and locally cached KEGG references
- Location: `input_data/`
- Contains: `.xlsx` agency compound lists, curated mappings, KO list (`.txt`), enzyme terms (`.txt`)
- Depends on: Nothing (root source)
- Used by: Generation scripts via `01_load_local_data.R`

**Generation Layer:**
- Purpose: Builds the core database by loading, merging, classifying, and enriching data
- Location: `biorempp_snakemake_version/workflow/scripts/generation/`
- Contains: 8 R scripts (`00_check_inputs.R` through `07_extract_enzymes_export.R`)
- Depends on: Input layer, KEGG REST API, `workflow/lib/io_contracts.R`
- Used by: Analysis layer

**Intermediate Work Layer:**
- Purpose: Stores in-progress `.rds` R data objects between generation steps
- Location: `biorempp_snakemake_version/work/`
- Contains: `preflight_ok.json`, `local_data.rds`, `kegg_data.rds`, `merged_compounds.rds`, `classified_compounds.rds`, `enriched_compounds.rds`
- Generated: Yes — not committed to source control
- Used by: Subsequent generation rules

**Analysis Layer:**
- Purpose: Computes statistical summaries over the generated database
- Location: `biorempp_snakemake_version/workflow/scripts/analysis/`
- Contains: 9 R scripts producing per-entity statistics JSON files
- Depends on: `results/database/` CSV output
- Used by: Validation layer, reporting layer

**Validation Layer:**
- Purpose: Verifies database keys and link correctness against live KEGG API
- Location: `biorempp_snakemake_version/workflow/scripts/validation/`
- Contains: `01_validate_keys_consistency_api.py`, `02_validate_links_groundtruth_policy_api.py`, `common_normalization.py`
- Depends on: `results/database/` CSV, KEGG REST API
- Used by: Reporting layer

**Results Layer:**
- Purpose: Persists all pipeline outputs in structured subdirectories
- Location: `biorempp_snakemake_version/results/`
- Contains: `database/` (CSV+XLSX), `analysis/` (JSON stats), `metadata/` (KEGG release + validation reports), `reports/` (workflow summary)
- Used by: GX validation package

**GX Validation Layer:**
- Purpose: Formal data contract enforcement using Great Expectations; runs as a separate Python package after the Snakemake pipeline
- Location: `biorempp_validation/src/biorempp_validation/`
- Contains: `run_validation.py` (entrypoint), `settings.py`, `loaders.py`, `gx_context.py`, `json_to_dataframe.py`, `consistency_checks.py`, `report_builder.py`
- Depends on: `results/` directory from Snakemake pipeline, `biorempp_validation/config/validation.yaml`
- Used by: CI/CD, manual quality gates

**Documentation Layer:**
- Purpose: MkDocs-based static site documentation
- Location: `docs/`, `mkdocs.yml`
- Built by: `scripts/build-docs.sh`, CI via `.github/workflows/docs-ci.yml`

## Data Flow

### Primary Database Generation Path

1. **Preflight** — `00_check_inputs.R` verifies all 6 required input files exist; writes `work/preflight_ok.json`
2. **Load local data** — `01_load_local_data.R` reads XLSX/TXT input files; serializes to `work/local_data.rds`
3. **Fetch KEGG info** — `02_fetch_kegg_info.R` queries `https://rest.kegg.jp/info/kegg`; writes `results/metadata/kegg_release.json`
4. **Fetch KEGG data** — `03_fetch_kegg_data.R` retrieves KO-EC, KO-reaction, compound-EC, compound-reaction, EC-reaction, reaction-description, and compound-list endpoints; serializes to `work/kegg_data.rds`
5. **Merge relationships** — `04_merge_relationships.R` joins local + KEGG data on EC numbers and reactions; writes `work/merged_compounds.rds`
6. **Add classifications** — `05_add_classifications.R` joins curated compound classes; writes `work/classified_compounds.rds`
7. **Enrich gene info** — `06_enrich_gene_info.R` adds gene symbol/name from KEGG KO list; writes `work/enriched_compounds.rds`
8. **Extract enzymes + export** — `07_extract_enzymes_export.R` pattern-matches enzyme terms, cleans annotations, writes `results/database/biorempp_database_v1.1.0.csv` and `.xlsx`

### Analysis Path

All 9 analysis scripts read from `results/database/biorempp_database_v1.1.0.csv` independently and write to `results/analysis/*.json`:

- `01_basic_statistics.R` → `basic_statistics.json`
- `02_compound_statistics.R` → `compound_statistics.json`
- `03_ko_statistics.R` → `ko_statistics.json`
- `04_enzyme_statistics.R` → `enzyme_statistics.json`
- `05_gene_statistics.R` → `gene_statistics.json`
- `06_crosstab_statistics.R` → `crosstab_statistics.json`
- `07_metadata.R` → `database_metadata.json`
- `08_executive_summary.R` (aggregates basic/compound/ko/enzyme JSONs) → `executive_summary.json`
- `09_merge_complete_analysis.R` (aggregates all JSONs) → `complete_analysis.json`

### KEGG Validation Path

Both Python scripts read the final CSV and hit the KEGG REST API to spot-check key linkages:

1. `01_validate_keys_consistency_api.py` → `results/metadata/keys_consistency_report.json`
2. `02_validate_links_groundtruth_policy_api.py` → `results/metadata/links_groundtruth_policy_report.json`

### Reporting Path

`build_run_report.py` aggregates all outputs (database files + all JSON results) and computes SHA-256 hashes → `results/reports/workflow_summary.json`

### GX Validation Path

`biorempp_validation/src/biorempp_validation/run_validation.py`:

1. Loads `validation.yaml` settings
2. Checks required files exist in `results/`
3. Loads CSV and analysis JSONs
4. Builds synthetic DataFrames from JSON payloads for GX suites
5. Runs `critical_gate` checkpoint (fail-on-critical) and `warning_report` checkpoint
6. Writes `critical_checkpoint_result.json`, `warning_checkpoint_result.json`, `validation_summary.json` to `biorempp_validation/results/`

**State Management:**
- Between pipeline steps: `.rds` R binary files in `work/`
- Final state: CSV/XLSX in `results/database/`, JSON files in `results/analysis/` and `results/metadata/`
- No shared in-memory state — all communication is via files

## Key Abstractions

**IO Contracts (`io_contracts.R`):**
- Purpose: Single source of truth for expected column names, KEGG endpoint definitions, and identifier regex patterns
- File: `biorempp_snakemake_version/workflow/lib/io_contracts.R`
- Pattern: Constants file sourced by all generation R scripts

**ValidationSettings (Python dataclass):**
- Purpose: Typed configuration object for the GX validation run
- File: `biorempp_validation/src/biorempp_validation/settings.py`
- Pattern: Immutable frozen dataclass loaded from `validation.yaml`

**Expectation Suites (JSON):**
- Purpose: GX expectation definitions for critical and warning checks, split by severity
- Files: `biorempp_validation/great_expectations/expectations/database_critical.json`, `database_warning.json`, `analysis_json_critical.json`, `analysis_json_exact_critical.json`, `analysis_json_warning.json`, `metadata_kegg_critical.json`, `cross_consistency_critical.json`
- Pattern: JSON payloads loaded at runtime and patched with dynamic thresholds from config

**Checkpoints (YAML):**
- Purpose: GX checkpoint definitions that map datasets to suites
- Files: `biorempp_validation/great_expectations/checkpoints/critical_gate.yml`, `warning_report.yml`

## Entry Points

**Snakemake Pipeline:**
- Location: `biorempp_snakemake_version/Snakefile`
- Triggers: `snakemake --snakefile Snakefile --configfile config/config.yaml --cores N`
- Responsibilities: Declares all pipeline outputs in `rule all`, includes all `.smk` rule files

**Standalone R Script (v1.0.0):**
- Location: `generate_database.R`
- Triggers: `Rscript generate_database.R` or run from RStudio
- Responsibilities: Complete monolithic pipeline — loads, fetches, merges, classifies, enriches, exports

**GX Validation CLI:**
- Location: `biorempp_validation/src/biorempp_validation/run_validation.py`
- Triggers: `python -m biorempp_validation.run_validation --config biorempp_validation/config/validation.yaml`
- Responsibilities: Loads pipeline results, runs Great Expectations checkpoints, writes validation reports

**Docker Entry Point:**
- Location: `biorempp_snakemake_version/env/Dockerfile`
- CMD: `snakemake --snakefile Snakefile --configfile config/config.yaml --cores 2 --printshellcmds`
- Base image: `rocker/tidyverse:4.3` with Python 3 added

## Architectural Constraints

- **Execution order:** Snakemake enforces DAG ordering via file dependencies — no rule runs unless its input files exist
- **Inter-script communication:** Exclusively via files (`.rds`, `.json`, `.csv`) — no shared memory, no sockets
- **KEGG API dependency:** Rules `fetch_kegg_info`, `fetch_kegg_data`, and both validation rules require network access to `https://rest.kegg.jp`
- **R version:** Base image pins `rocker/tidyverse:4.3`; key packages: `readxl`, `dplyr`, `tidyr`, `stringr`, `readr`, `xlsx`, `jsonlite`, `httr`
- **Python version:** `python3` (no specific version pinned outside Docker)
- **Global state:** `io_contracts.R` is sourced as a side-effectful file, defining package-level constants. `common_normalization.py` loads NA markers at module import
- **Circular imports:** None detected
- **Config authority:** `biorempp_snakemake_version/config/config.yaml` is the single config for the pipeline; `biorempp_validation/config/validation.yaml` is the single config for GX validation — they are separate files

## Anti-Patterns

### Standalone Script vs Pipeline Duplication

**What happens:** `generate_database.R` at the project root duplicates the full database generation logic that also lives in `workflow/scripts/generation/`. Both implement the same ETL steps independently.

**Why it's wrong:** Changes to the pipeline logic must be applied in two places; the standalone script will drift from the canonical pipeline implementation.

**Do this instead:** Use only the Snakemake pipeline for all generation. Treat `generate_database.R` as a legacy artifact. New features go into `workflow/scripts/generation/` scripts only.

## Error Handling

**Strategy:** Fail-fast with informative messages at each layer

**Patterns:**
- R scripts call `stop()` with descriptive messages when required files or arguments are missing
- Python validation scripts use `argparse` for required argument enforcement
- GX validation separates critical failures (pipeline-halting) from warnings (report-only) via `fail_on_critical` and `fail_on_warning` settings in `validation.yaml`
- KEGG API calls in Python validation use retry logic with exponential backoff (configured via env vars `BIOREMPP_API_MAX_RETRIES`, `BIOREMPP_API_TIMEOUT_SECONDS`)

## Cross-Cutting Concerns

**Logging:** R scripts write stdout/stderr to per-rule log files in `biorempp_snakemake_version/logs/` (e.g., `logs/fetch_kegg_info.log`). Snakemake captures these via shell redirection `> {log} 2>&1`.

**Validation:** Two distinct validation layers: (1) in-pipeline KEGG key/link validation via Python scripts in `workflow/scripts/validation/`; (2) post-pipeline Great Expectations data contract validation in `biorempp_validation/`.

**Configuration:** All configurable values (paths, KEGG endpoints, output names, analysis top-N counts) are in `biorempp_snakemake_version/config/config.yaml`. Validation thresholds and database contract are in `biorempp_validation/config/validation.yaml`.

**Reproducibility:** `build_run_report.py` records SHA-256 checksums of all output files in `workflow_summary.json`. The GX `strict_exact` mode pins exact row/entity counts from a prior run.

---

*Architecture analysis: 2026-05-17*
