# Architecture

**Analysis Date:** 2026-03-24

## Pattern Overview

**Overall:** Multi-stage ETL pipeline with decoupled validation layer

**Key Characteristics:**
- Snakemake-based workflow orchestration with modular rule files (declarative dependencies)
- Layered processing: preflight validation → data generation → statistical analysis → validation gates → reporting
- Dual-track data flow: primary generation pipeline + independent Great Expectations validation framework
- API-first design for KEGG integration with fallback/enrichment strategies
- Containerized execution via Docker for reproducibility
- Contract-based outputs (fixed naming: `biorempp_database_v1.0.0.*`)

## Layers

**Preflight Layer:**
- Purpose: Validates input file existence and integrity before pipeline execution
- Location: `biorempp_snakemake_version/workflow/rules/00_preflight.smk`
- Contains: Single input validation rule triggered before all dependent rules
- Depends on: Local filesystem input data
- Used by: All downstream generation rules depend on preflight completion marker `work/preflight_ok.json`
- Key Script: `workflow/scripts/generation/00_check_inputs.R` - validates 6 required input files exist in `../input_data/`

**Generation Layer (Data ETL):**
- Purpose: Load local and external data, merge relationships, classify compounds, enrich metadata, export final database
- Location: `biorempp_snakemake_version/workflow/rules/10_generation.smk`
- Contains: 7 sequential rules producing intermediate `.rds` artifacts
- Depends on: Preflight validation, local input files, KEGG REST API
- Used by: Analysis and validation layers consume the final CSV output
- Data flow:
  1. **Preflight** → `work/preflight_ok.json`
  2. **fetch_kegg_info** → `results/metadata/kegg_release.json` (independent, run in parallel)
  3. **load_local_data** → `work/local_data.rds` (reads 6 Excel/text files from `../input_data/`)
  4. **fetch_kegg_data** → `work/kegg_data.rds` (queries KO-EC, KO-reaction, cpd-EC links via REST API)
  5. **merge_relationships** → `work/merged_compounds.rds` (joins local + KEGG data)
  6. **add_classifications** → `work/classified_compounds.rds` (adds compound class annotations)
  7. **enrich_gene_info** → intermediate enrichment (not explicitly shown, embedded in extraction)
  8. **extract_enzymes_export** → `results/database/biorempp_database_v1.0.0.csv` + `.xlsx` (final table export)
- Key Scripts:
  - `workflow/scripts/generation/01_load_local_data.R` - reads 4 Excel files and 2 text files
  - `workflow/scripts/generation/02_fetch_kegg_info.R` - queries KEGG info endpoint, stores release metadata
  - `workflow/scripts/generation/03_fetch_kegg_data.R` - fetches link relationships via KEGG REST API, caches in memory
  - `workflow/scripts/generation/04_merge_relationships.R` - joins via compound ID and KO ID with fallback enrichment
  - `workflow/scripts/generation/07_extract_enzymes_export.R` - final CSV/XLSX export with 8-column schema

**Analysis Layer (Statistical Processing):**
- Purpose: Generate 9 independent JSON reports summarizing database contents and relationships
- Location: `biorempp_snakemake_version/workflow/rules/20_analysis.smk`
- Contains: 9 parallelizable rules, each reading final CSV and producing summary JSON
- Depends on: Final CSV output from generation layer
- Used by: Validation layer and workflow reporting
- Key Rules:
  - `basic_statistics` → `results/analysis/basic_statistics.json` (row count, column info)
  - `compound_statistics` → `results/analysis/compound_statistics.json` (top N compounds, frequency)
  - `ko_statistics` → `results/analysis/ko_statistics.json` (top N KO IDs, distribution)
  - `enzyme_statistics` → `results/analysis/enzyme_statistics.json` (top N enzymes extracted)
  - `gene_statistics` → `results/analysis/gene_statistics.json` (gene symbol frequencies)
  - `crosstab_statistics` → `results/analysis/crosstab_statistics.json` (cross-tabulations: compound×agency)
  - `metadata` → `results/analysis/database_metadata.json` (column descriptions, sources, processing notes)
  - `executive_summary` → `results/analysis/executive_summary.json` (high-level KPIs: total entries, unique compounds, unique KOs)
  - `complete_analysis` → `results/analysis/complete_analysis.json` (merged all above)
- Key Scripts: `workflow/scripts/analysis/0{1-9}_*.R` - each reads CSV via `readr::read_csv()`, aggregates, exports JSON

**Validation Layer (API-Based Consistency Checks):**
- Purpose: Validate database integrity against KEGG API and enforce data quality gates
- Location: `biorempp_snakemake_version/workflow/rules/30_validation.smk`
- Contains: 2 API-driven validation rules producing JSON consistency reports
- Depends on: Final CSV output from generation layer, KEGG REST API
- Used by: Workflow reporting and external validation framework
- Key Rules:
  - `validate_keys_consistency` → `results/metadata/keys_consistency_report.json` - validates that database KO/cpd/EC relationships align with KEGG API ground truth
  - `validate_links_groundtruth_policy` → `results/metadata/links_groundtruth_policy_report.json` - checks bridge relationships (KO→EC→reaction) exist in KEGG
- Key Scripts:
  - `workflow/scripts/validation/01_validate_keys_consistency_api.py` - queries KEGG endpoints for KO-EC, KO-reaction, cpd-EC, cpd-reaction, EC-reaction links; compares with database
  - `workflow/scripts/validation/02_validate_links_groundtruth_policy_api.py` - validates transitive relationship rules and fallback enrichment policies

**Reporting Layer (Provenance & Checksums):**
- Purpose: Compute final run summary with SHA-256 hashes, execution metadata, and KEGG release info
- Location: `biorempp_snakemake_version/workflow/rules/90_reporting.smk`
- Contains: Single aggregation rule consuming all prior outputs
- Depends on: All database, analysis, metadata, and validation artifacts
- Used by: External documentation, CI/CD validation, audit trails
- Key Rule:
  - `build_run_report` → `results/reports/workflow_summary.json` - aggregates checksums, timestamps, KEGG release, artifact paths
- Key Script:
  - `workflow/scripts/reporting/build_run_report.py` - computes SHA-256 for all outputs, collects execution context

**Validation Framework Layer (Post-Pipeline, Independent):**
- Purpose: Standalone Great Expectations validation suite verifying database schema, content integrity, and statistical consistency
- Location: `biorempp_validation/` (separate Python package)
- Contains: GX checkpoints, expectation suites, schema validators, cross-consistency checks
- Depends on: Final pipeline outputs (CSV + JSON analysis artifacts)
- Used by: CI/CD, release gates, compliance audits
- Key Components:
  - `biorempp_validation/great_expectations/expectations/` - JSON expectation suites for schema, nulls, vocab, exact counts
  - `biorempp_validation/src/biorempp_validation/run_validation.py` - orchestrates suite execution
  - `biorempp_validation/src/biorempp_validation/consistency_checks.py` - validates CSV↔JSON parity
  - Schema enforcement: database critical (blocks on schema violations), database warning (vocab controlled)
  - Analysis JSON validation: critical (required keys/structure), warning (top-N quality), exact (metric parity)

## Data Flow

**Main Pipeline (Generation → Analysis → Validation → Reporting):**

1. **Ingestion Phase:**
   - Preflight rule checks 6 input files in `../input_data/` exist
   - Two parallel branches:
     - **Local Data:** `01_load_local_data.R` reads 4 Excel + 2 text files → `work/local_data.rds`
     - **KEGG Metadata:** `02_fetch_kegg_info.R` queries KEGG info endpoint → `results/metadata/kegg_release.json`
     - **KEGG Links:** `03_fetch_kegg_data.R` fetches KO-EC, KO-reaction, etc. via REST → `work/kegg_data.rds`

2. **Transformation Phase:**
   - `04_merge_relationships.R` joins local data + KEGG links via compound ID + KO ID with fallback enrichment
   - `05_add_classifications.R` annotates compound classes (from `confirm_class_CURATED.xlsx`)
   - `06_enrich_gene_info.R` supplements gene symbols + descriptions (from local mapping)
   - `07_extract_enzymes_export.R` parses enzyme activity from gene names → final 8-column CSV/XLSX export

3. **Analysis Phase (9 Independent Rules):**
   - Each rule reads the final CSV
   - Computes metrics: counts, top-N, distributions, cross-tabs, metadata
   - Outputs JSON to `results/analysis/`
   - Final `09_merge_complete_analysis.R` concatenates all JSON files

4. **Validation Phase (API-Based):**
   - `01_validate_keys_consistency_api.py` queries KEGG for each KO/cpd/EC in database, counts matches
   - `02_validate_links_groundtruth_policy_api.py` validates bridge relationships (KO→EC→reaction)
   - Outputs JSON reports to `results/metadata/`

5. **Reporting Phase:**
   - `build_run_report.py` computes SHA-256 for all outputs, aggregates metadata
   - Outputs `results/reports/workflow_summary.json`

**External Validation (Post-Pipeline):**

1. User runs: `python -m biorempp_validation.run_validation --config config/validation.yaml`
2. Framework loads database CSV from `biorempp_snakemake_version/results/database/`
3. Framework loads analysis JSON files from `biorempp_snakemake_version/results/analysis/`
4. Executes 7 expectation suites:
   - `database_critical` - schema, nulls, ID patterns, duplicates
   - `database_warning` - controlled vocab, strict exact counts (configurable)
   - `analysis_json_critical` - required keys, structural checks
   - `analysis_json_warning` - top-N quality, summary plausibility
   - `analysis_json_exact_critical` - metric parity (CSV row count ↔ basic_statistics.json)
   - `metadata_kegg_critical` - KEGG release traceability
   - `cross_consistency_critical` - validate CSV counts vs. analysis JSON summaries
5. Outputs checkpoint results + HTML data docs to `biorempp_validation/results/`
6. Exit code: 0 (pass all critical), 1 (any critical failure or configured warning failure)

**State Management:**

- **Intermediate State:** `.rds` files in `work/` - R-native serialization for fast deserialization across rules
- **Final State:** CSV/XLSX in `results/database/`, JSON in `results/analysis/` and `results/metadata/`
- **Metadata State:** KEGG release info, checksums, timestamps in `results/metadata/` and `results/reports/`
- **Validation State:** Great Expectations checkpoint results in `biorempp_validation/results/`

## Key Abstractions

**Compound-Gene-Enzyme Relationship (CGE):**
- Purpose: Core data model linking chemical compounds → KEGG KO → gene symbols → enzyme activities
- Examples: `biorempp_database_v1.0.0.csv` (8-column table: cpd, compoundclass, ko, referenceAG, compoundname, genesymbol, genename, enzyme_activity)
- Pattern: Relational table with multiple many-to-one joins (single compound maps to multiple KOs, each KO maps to multiple genes)

**Input Contract (6 Files):**
- Purpose: Defines canonical input sources
- Examples:
  - `kegglistcompounds.xlsx` - compound registry with KEGG IDs
  - `compostos_todasagencias.xlsx` - compound-agency mappings
  - `confirm_class_CURATED.xlsx` - compound classification (manually curated)
  - `kegglistko.txt` - KEGG KO identifiers
  - `enzymes_unique.txt` - unique enzyme names
  - `missing_compounds_founds_curated.xlsx` - gap-fill data (compounds found outside standard KEGG)
- Pattern: Static lookup tables + curated extensions (defined in `io_contracts.R`)

**Output Contract (Fixed Naming):**
- Purpose: Ensures reproducible, versionable output paths
- Examples: `biorempp_database_v1.0.0.csv`, `biorempp_database_v1.0.0.xlsx`
- Pattern: Version string in filename, immutable structure once v1.0.0 released

**KEGG Integration Pattern:**
- Purpose: Fetch and validate relationships from external KEGG API
- Examples:
  - `fetch_kegg_data.R` queries 5 endpoints (KO-EC, KO-reaction, cpd-EC, cpd-reaction, EC-reaction)
  - `02_validate_keys_consistency_api.py` re-queries same endpoints to verify consistency
- Pattern: Caching in intermediate `.rds` artifacts, API calls in dedicated generation step, separate validation step for audit trail

**Statistics Aggregation Pattern:**
- Purpose: Compute summary metrics independently then merge
- Examples: 9 analysis rules each read CSV, compute specialized metric, output JSON
- Pattern: Single-responsibility rules (compound_statistics only computes compound frequencies, not KO or enzyme data)

**Schema Validation Pattern:**
- Purpose: Enforce strict column definitions, nullability, regex patterns, vocabulary
- Examples: `database_critical` expectation suite validates 8 columns, null constraints, KEGG ID format (`^[A-Z]\d{5}$`)
- Pattern: Great Expectations JSON definitions, loaded at validation runtime, configurable severity (critical = blocks, warning = reports)

## Entry Points

**Pipeline Execution:**
- Location: `biorempp_snakemake_version/Snakefile`
- Triggers: `snakemake --snakefile Snakefile --configfile config/config.yaml --cores N` OR Docker Compose
- Responsibilities:
  - Includes all rule modules (00_preflight, 10_generation, 20_analysis, 30_validation, 90_reporting)
  - Declares target files for `all` rule (database CSV/XLSX, analysis JSON files, metadata, workflow summary)
  - Manages global variables (VERSION, PATHS, OUTPUTS, file locations)

**Validation Execution:**
- Location: `biorempp_validation/src/biorempp_validation/run_validation.py` (main function)
- Triggers: `python -m biorempp_validation.run_validation --config <yaml>` OR `biorempp-validate --config <yaml>` (installed entry point)
- Responsibilities:
  - Parses validation config (expected agencies, compound classes, strict_exact flag, fail_on_warning flag)
  - Loads pipeline outputs from disk
  - Instantiates Great Expectations context
  - Runs expectation suites sequentially
  - Aggregates results into checkpoint pass/fail
  - Generates validation summary JSON + HTML data docs
  - Returns exit code (0 = pass, 1 = fail)

**Development Entry Points (Scripts):**
- `biorempp_snakemake_version/scripts/run_snakemake.sh` - Linux/macOS helper (sets cores, runs Docker if available)
- `biorempp_snakemake_version/scripts/run_snakemake.bat` - Windows batch helper

## Error Handling

**Strategy:** Fail-fast with detailed logging + graceful API fallback for enrichment

**Patterns:**

1. **Input Validation (Preflight):**
   - `00_check_inputs.R` verifies all 6 files exist before pipeline starts
   - Exit if any missing → blocks entire DAG
   - Log: `logs/preflight_check_inputs.log`

2. **API Failure (Generation):**
   - `03_fetch_kegg_data.R` calls KEGG REST endpoints
   - If API unavailable: pipeline fails (no fallback local cache)
   - If partial response: pipeline fails (incomplete links)
   - Log: `logs/fetch_kegg_data.log`

3. **Data Inconsistency (Validation):**
   - `01_validate_keys_consistency_api.py` counts mismatches between database and KEGG API
   - Outputs report (does not block by default, requires separate validation run)
   - Log: `logs/validate_keys_consistency.log`

4. **Schema Violations (Validation Framework):**
   - Great Expectations detects missing columns, wrong data types, nulls, regex failures
   - `critical` expectations block execution (exit 1)
   - `warning` expectations report only (unless `fail_on_warning: true` in config)
   - Output: `biorempp_validation/results/critical_checkpoint_result.json`

5. **Logging:**
   - All R scripts use `log_message()` helper from `workflow/lib/utils.R` (timestamp + level)
   - All Python scripts use `logging` module with file + console handlers
   - Per-rule logs: `logs/<rule_name>.log`
   - Pipeline logs aggregated by Snakemake in `.snakemake/log/`

## Cross-Cutting Concerns

**Logging:**
- Approach: File-based per-rule logging (Snakemake redirects stdout/stderr to `logs/<rule>.log`)
- Pattern: R scripts use custom `log_message()` function with timestamp + level; Python scripts use standard `logging` module
- Centralized: All logs written to `logs/` directory, indexed by Snakemake

**Validation:**
- Approach: Multi-layer strategy - input validation (preflight), schema enforcement (Great Expectations), API consistency checks (workflow rules)
- Pattern:
  - Preflight rule blocks pipeline start
  - Generation rules fail if KEGG API unavailable
  - Validation rules produce reports (non-blocking by default)
  - Great Expectations framework enforces schema after pipeline completes
- Critical paths: CSV schema, null constraints, KEGG ID format (must pass)

**Authentication:**
- Approach: No authentication required (KEGG REST API is public)
- KEGG base URL: `https://rest.kegg.jp` (configurable in `config/config.yaml`)

**Configuration Management:**
- Approach: Centralized YAML config file
- Location: `biorempp_snakemake_version/config/config.yaml`
- Keys managed: version, paths (input/results/work/logs), outputs (CSV/XLSX filenames), KEGG endpoints, analysis parameters (top_n_compounds, etc.)
- Usage: Snakemake loads config automatically, passes to rules via `config["key"]` syntax

**Reproducibility:**
- Approach: Version all inputs + environment + pipeline + outputs
- Assets:
  - Input files: 6 static Excel/text files in `input_data/`
  - Pipeline code: `workflow/` scripts + rules + `Snakefile`
  - Environment: `env/Dockerfile`, `env/python-requirements.txt`, `env/r-packages.txt`
  - Metadata: `results/metadata/kegg_release.json` captures KEGG state at run time
  - Checksums: `results/reports/workflow_summary.json` contains SHA-256 hashes of all outputs

---

*Architecture analysis: 2026-03-24*
