# Codebase Structure

**Analysis Date:** 2026-03-24

## Directory Layout

```
BioRemPP_DB_1.0.0/
├── biorempp_snakemake_version/    # Primary Snakemake pipeline (v1.0.0)
│   ├── Snakefile                   # Main workflow orchestrator
│   ├── README.md                    # Pipeline documentation
│   ├── config/
│   │   └── config.yaml              # Centralized configuration (paths, KEGG endpoints, analysis params)
│   ├── env/
│   │   ├── Dockerfile               # Docker image (rocker/tidyverse:4.3 base)
│   │   ├── docker-compose.yml       # Docker Compose service definition
│   │   ├── python-requirements.txt  # Snakemake 7.32.4, PuLP, etc.
│   │   └── r-packages.txt           # R packages (readxl, dplyr, tidyr, jsonlite, etc.)
│   ├── scripts/
│   │   ├── run_snakemake.sh         # Linux/macOS helper (runs Snakemake or Docker)
│   │   └── run_snakemake.bat        # Windows batch helper
│   ├── workflow/
│   │   ├── lib/                     # Shared R utility libraries
│   │   │   ├── utils.R              # General helpers (parse_cli_args, log_message, write_json_file, etc.)
│   │   │   └── io_contracts.R       # Input/output contract definitions
│   │   ├── rules/                   # Snakemake rule modules (4 files, processed by main Snakefile)
│   │   │   ├── 00_preflight.smk     # Input validation rule
│   │   │   ├── 10_generation.smk    # Data ETL rules (load local, fetch KEGG, merge, classify, enrich, export)
│   │   │   ├── 20_analysis.smk      # Statistical analysis rules (9 parallelizable rules → JSON)
│   │   │   ├── 30_validation.smk    # API-based consistency validation rules (2 Python scripts)
│   │   │   └── 90_reporting.smk     # Final run report generation (SHA-256 checksums)
│   │   └── scripts/                 # Rule implementations (R + Python)
│   │       ├── generation/          # Data generation layer (8 R scripts, 00-07 prefix)
│   │       │   ├── 00_check_inputs.R
│   │       │   ├── 01_load_local_data.R
│   │       │   ├── 02_fetch_kegg_info.R
│   │       │   ├── 03_fetch_kegg_data.R
│   │       │   ├── 04_merge_relationships.R
│   │       │   ├── 05_add_classifications.R
│   │       │   ├── 06_enrich_gene_info.R
│   │       │   └── 07_extract_enzymes_export.R
│   │       ├── analysis/            # Statistical analysis layer (9 R scripts, 01-09 prefix)
│   │       │   ├── 01_basic_statistics.R
│   │       │   ├── 02_compound_statistics.R
│   │       │   ├── 03_ko_statistics.R
│   │       │   ├── 04_enzyme_statistics.R
│   │       │   ├── 05_gene_statistics.R
│   │       │   ├── 06_crosstab_statistics.R
│   │       │   ├── 07_metadata.R
│   │       │   ├── 08_executive_summary.R
│   │       │   └── 09_merge_complete_analysis.R
│   │       ├── validation/          # API-based validation layer (2 Python scripts)
│   │       │   ├── 01_validate_keys_consistency_api.py
│   │       │   └── 02_validate_links_groundtruth_policy_api.py
│   │       └── reporting/           # Provenance reporting (1 Python script)
│   │           └── build_run_report.py
│   ├── work/                        # Intermediate .rds artifacts (generated, not committed)
│   │   ├── .gitkeep
│   │   ├── preflight_ok.json        # Marker file from preflight check
│   │   ├── local_data.rds           # Loaded input data (serialized R object)
│   │   ├── kegg_data.rds            # Fetched KEGG relationships
│   │   ├── merged_compounds.rds     # Joined local + KEGG data
│   │   └── classified_compounds.rds # After classification/enrichment
│   ├── results/                     # Final outputs (generated, committed per release)
│   │   ├── database/
│   │   │   ├── .gitkeep
│   │   │   ├── biorempp_database_v1.0.0.csv     # Final database (10,871 rows × 8 cols)
│   │   │   └── biorempp_database_v1.0.0.xlsx    # Same as Excel
│   │   ├── analysis/                # JSON statistics reports
│   │   │   ├── .gitkeep
│   │   │   ├── basic_statistics.json            # Row/column counts
│   │   │   ├── compound_statistics.json         # Top N compounds
│   │   │   ├── ko_statistics.json               # Top N KO IDs
│   │   │   ├── enzyme_statistics.json           # Top N enzymes
│   │   │   ├── gene_statistics.json             # Top N genes
│   │   │   ├── crosstab_statistics.json         # Compound×Agency crosstab
│   │   │   ├── database_metadata.json           # Schema + processing notes
│   │   │   ├── executive_summary.json           # High-level KPIs
│   │   │   └── complete_analysis.json           # Merged all analyses
│   │   ├── metadata/
│   │   │   ├── kegg_release.json                # KEGG release metadata (date, version)
│   │   │   ├── keys_consistency_report.json     # API validation results (mismatches)
│   │   │   └── links_groundtruth_policy_report.json # Transitive rule violations
│   │   └── reports/
│   │       └── workflow_summary.json            # SHA-256 checksums + metadata
│   ├── logs/                        # Per-rule execution logs (generated, not committed)
│   │   ├── .gitkeep
│   │   ├── preflight_check_inputs.log
│   │   ├── load_local_data.log
│   │   ├── fetch_kegg_data.log
│   │   ├── analysis_*.log           # 9 analysis rule logs
│   │   └── ... (one log per rule)
│   ├── .snakemake/                  # Snakemake metadata (locks, cache, conda)
│   │   ├── locks/                   # Execution locks
│   │   ├── log/                     # Snakemake system logs
│   │   ├── metadata/                # Rule metadata
│   │   └── conda/                   # Conda environment cache (if used)
│   └── input_data/                  # Symlink/copy of root input_data (used by Snakefile)
│
├── biorempp_validation/             # Standalone Great Expectations validation package
│   ├── README.md                     # Validation framework documentation
│   ├── pyproject.toml                # Python package metadata
│   ├── requirements.txt              # GX + dependencies
│   ├── config/
│   │   └── validation.yaml           # Validation rules (expected agencies, classes, strict_exact, fail_on_warning)
│   ├── great_expectations/
│   │   ├── great_expectations.yml    # GX context configuration
│   │   ├── checkpoints/
│   │   │   ├── critical_gate.yml     # Blocking checkpoint (critical suites)
│   │   │   └── warning_report.yml    # Report-only checkpoint (warning suites)
│   │   ├── expectations/             # JSON expectation suite definitions
│   │   │   ├── database_critical.json                # Schema, nulls, regex, duplicates
│   │   │   ├── database_warning.json                 # Vocab, exact counts (configurable)
│   │   │   ├── analysis_json_critical.json          # Required keys, structure
│   │   │   ├── analysis_json_warning.json           # Quality checks
│   │   │   ├── analysis_json_exact_critical.json    # Metric parity (CSV ↔ JSON)
│   │   │   ├── cross_consistency_critical.json      # Count cross-validation
│   │   │   └── metadata_kegg_critical.json          # KEGG traceability
│   │   └── plugins/                  # Custom validators (reserved)
│   │       └── .gitkeep
│   ├── src/biorempp_validation/
│   │   ├── __init__.py              # Package init
│   │   ├── run_validation.py        # Main validation entry point + orchestration
│   │   ├── settings.py              # ValidationSettings dataclass (config parsing)
│   │   ├── loaders.py               # File loading utilities (CSV, JSON, path resolution)
│   │   ├── gx_context.py            # Great Expectations context creation + suite execution
│   │   ├── json_to_dataframe.py     # Convert JSON analysis artifacts to DataFrames for validation
│   │   ├── consistency_checks.py    # Cross-validation logic (CSV ↔ JSON parity)
│   │   └── report_builder.py        # Validation result aggregation + HTML data docs
│   ├── tests/
│   │   ├── test_happy_path.py       # Valid outputs pass all checks
│   │   ├── test_kegg_metadata.py    # KEGG release validation
│   │   ├── test_missing_files.py    # Handles missing pipeline outputs gracefully
│   │   ├── test_schema_break.py     # Catches schema violations
│   │   └── test_warning_only_drift.py # Warning suites don't block by default
│   └── results/                      # Validation output (generated, not committed)
│       ├── critical_checkpoint_result.json   # Critical suite results (blocks if failed)
│       ├── warning_checkpoint_result.json    # Warning suite results
│       ├── validation_summary.json           # Aggregated pass/fail
│       └── data_docs/                        # HTML validation report
│           └── index.html
│
├── input_data/                      # Input files (canonical location, 6 required files)
│   ├── kegglistcompounds.xlsx       # Compound registry with KEGG IDs
│   ├── kegglistko.txt               # KEGG KO identifiers (one per line)
│   ├── enzymes_unique.txt           # Enzyme names (one per line)
│   ├── compostos_todasagencias.xlsx # Compound-agency mappings
│   ├── confirm_class_CURATED.xlsx   # Compound classifications (manually curated)
│   └── missing_compounds_founds_curated.xlsx # Fallback/curated compounds
│
├── output_data/                     # Deprecated (legacy monolithic script outputs)
│   └── .gitkeep
│
├── docs/                            # MkDocs documentation site
│   ├── index.md                     # Main documentation index
│   ├── about/                       # Project info (changelog, contributing, license, how-to-cite)
│   ├── getting-started/             # User guides (installation, quick start, requirements)
│   ├── user-guide/                  # Usage documentation (input data, output understanding, troubleshooting)
│   ├── database/                    # Database documentation (schema, statistics, FAIR compliance)
│   ├── technical/                   # Technical docs (pipeline architecture, snakemake rules, config reference)
│   ├── validation/                  # Validation documentation (old, legacy GX docs)
│   ├── validation-gx/               # New Great Expectations documentation
│   ├── interoperability/            # Multi-omics integration, R/Python integration
│   ├── reference/                   # Data sources, environmental agencies, glossary
│   └── stylesheets/                 # Custom CSS
│
├── scripts/
│   └── build-docs.sh                # MkDocs documentation build helper
│
├── .github/
│   └── workflows/                   # CI/CD workflows (GitHub Actions)
│
├── .planning/
│   └── codebase/                    # GSD-generated codebase analysis documents
│       ├── ARCHITECTURE.md          # Pipeline architecture
│       ├── STRUCTURE.md             # This file
│       ├── CONVENTIONS.md           # (optional, quality focus)
│       ├── TESTING.md               # (optional, quality focus)
│       ├── STACK.md                 # (optional, tech focus)
│       ├── INTEGRATIONS.md          # (optional, tech focus)
│       └── CONCERNS.md              # (optional, concerns focus)
│
├── .claude/                         # Claude workspace (internal)
├── .benchmarks/                     # Performance benchmarks
├── .archive/                        # Historical docs + archived components
│   ├── gx_documentation/            # Old Great Expectations documentation
│   ├── V1.1.0/                      # Unreleased v1.1.0 prototype code
│   └── draft_papper/                # Research drafts
│
├── .gitignore                       # Git ignore patterns (venv, work/, .snakemake, etc.)
├── mkdocs.yml                       # MkDocs configuration
├── .readthedocs.yaml                # ReadTheDocs deployment config
├── requirements.txt                 # Python dependencies for documentation build
├── LICENSE.md                       # Apache 2.0 + CC BY 4.0 dual license
├── README.md                        # Project overview
├── generate_database.R              # Legacy monolithic script (base for Snakemake modularization)
└── venv/                            # Python virtual environment (not committed, local dev)
```

## Directory Purposes

**biorempp_snakemake_version/**
- Purpose: Primary Snakemake pipeline implementation for v1.0.0 database generation
- Contains: Declarative workflow rules, reusable R/Python scripts, configuration, runtime artifacts
- Key files: `Snakefile` (orchestrator), `config/config.yaml` (parameters), `workflow/` (rule modules + scripts)

**biorempp_snakemake_version/workflow/rules/**
- Purpose: Modular Snakemake rule definitions, separated by layer (00_preflight, 10_generation, 20_analysis, 30_validation, 90_reporting)
- Contains: `.smk` files that define DAG structure, dependencies, inputs, outputs
- Key files: `00_preflight.smk` (1 rule), `10_generation.smk` (8 rules), `20_analysis.smk` (9 rules), `30_validation.smk` (2 rules), `90_reporting.smk` (1 rule)

**biorempp_snakemake_version/workflow/scripts/generation/**
- Purpose: Data ETL implementations (R scripts)
- Contains: Load, fetch, merge, classify, enrich, export operations
- Execution order: 00 → 01 → 02 → 03 → 04 → 05 → 06 → 07 (some parallelizable)
- Key files: `01_load_local_data.R` (reads 6 input files), `03_fetch_kegg_data.R` (REST API calls), `07_extract_enzymes_export.R` (CSV/XLSX export)

**biorempp_snakemake_version/workflow/scripts/analysis/**
- Purpose: Statistical aggregation implementations (R scripts)
- Contains: Parallel statistics rules computing top-N, counts, distributions, crosstabs
- Execution: All rules parallelizable (each reads final CSV independently)
- Key files: `01_basic_statistics.R` (row/col counts), `08_executive_summary.R` (KPIs), `09_merge_complete_analysis.R` (aggregates all JSON)

**biorempp_snakemake_version/workflow/scripts/validation/**
- Purpose: API-based consistency validation (Python scripts)
- Contains: KEGG API queries, comparison logic, report generation
- Key files: `01_validate_keys_consistency_api.py` (validates KO/cpd/EC links), `02_validate_links_groundtruth_policy_api.py` (validates transitive rules)

**biorempp_snakemake_version/workflow/lib/**
- Purpose: Shared utility libraries (R functions)
- Contains: Argument parsing, logging, JSON I/O, contract helpers
- Key files: `utils.R` (load_required_packages, parse_cli_args, log_message, write_json_file), `io_contracts.R` (input/output schema definitions)

**biorempp_snakemake_version/work/**
- Purpose: Intermediate artifacts (serialized R objects)
- Contains: `.rds` files produced by generation rules
- Generated: Yes (cleared with `snakemake --delete-temp-outputs`)
- Committed: No (in `.gitignore`)

**biorempp_snakemake_version/results/**
- Purpose: Final outputs (database CSV/XLSX, analysis JSON, metadata, reports)
- Contains: Three subdirectories (database/, analysis/, metadata/, reports/)
- Generated: Yes
- Committed: Yes (per release, for reproducibility and downstream use)

**biorempp_validation/**
- Purpose: Standalone Great Expectations validation framework
- Contains: Expectation suites (JSON), validation logic (Python), tests, configuration
- Key files: `run_validation.py` (main entry point), `great_expectations/expectations/` (suite definitions), `config/validation.yaml` (runtime config)

**biorempp_validation/tests/**
- Purpose: Test validation framework behavior
- Contains: Happy path tests, schema violation tests, missing file handling, warning-only mode tests
- Key files: `test_happy_path.py` (valid outputs), `test_schema_break.py` (rejection tests)

**input_data/**
- Purpose: Canonical input data location
- Contains: 6 required files (Excel files, text files)
- Generated: No (user-provided)
- Committed: Yes (required for reproducibility)

**docs/**
- Purpose: User and developer documentation (MkDocs site)
- Contains: Markdown files organized by topic (getting started, user guide, technical, validation, reference)
- Key files: `index.md` (site home), `technical/pipeline-architecture.md` (system design), `validation-gx/` (GX docs)

## Key File Locations

**Entry Points:**
- `biorempp_snakemake_version/Snakefile`: Main Snakemake orchestrator (includes rules, declares all targets)
- `biorempp_validation/src/biorempp_validation/run_validation.py`: Validation framework entry point
- `biorempp_snakemake_version/scripts/run_snakemake.sh`: Linux/macOS execution helper
- `biorempp_snakemake_version/scripts/run_snakemake.bat`: Windows execution helper

**Configuration:**
- `biorempp_snakemake_version/config/config.yaml`: Pipeline configuration (paths, KEGG URLs, analysis parameters)
- `biorempp_validation/config/validation.yaml`: Validation configuration (expected values, thresholds, severity)
- `biorempp_snakemake_version/env/Dockerfile`: Container image definition
- `biorempp_snakemake_version/env/python-requirements.txt`: Python dependencies
- `biorempp_snakemake_version/env/r-packages.txt`: R package dependencies

**Core Logic:**
- `biorempp_snakemake_version/workflow/scripts/generation/01_load_local_data.R`: Loads 6 input files
- `biorempp_snakemake_version/workflow/scripts/generation/03_fetch_kegg_data.R`: Fetches KEGG relationships via REST API
- `biorempp_snakemake_version/workflow/scripts/generation/04_merge_relationships.R`: Joins local + KEGG data
- `biorempp_snakemake_version/workflow/scripts/generation/07_extract_enzymes_export.R`: Final CSV/XLSX export
- `biorempp_validation/src/biorempp_validation/run_validation.py`: Validation orchestration

**Testing:**
- `biorempp_validation/tests/test_happy_path.py`: Valid pipeline output tests
- `biorempp_validation/tests/test_schema_break.py`: Schema violation detection tests

## Naming Conventions

**Files:**

- **Rule modules:** `{priority}_{layer}.smk` (e.g., `00_preflight.smk`, `10_generation.smk`, `20_analysis.smk`)
  - Priority: 00 (preflight), 10 (generation), 20 (analysis), 30 (validation), 90 (reporting)
  - Layer: preflight, generation, analysis, validation, reporting

- **Scripts:** `{sequence}_{operation}.R` or `.py` within layer directories
  - Sequence: 00-09 (execution order or grouping number)
  - Operation: descriptive name (load_local_data, fetch_kegg_info, extract_enzymes_export)
  - Example: `workflow/scripts/generation/01_load_local_data.R`

- **Output files:** `biorempp_database_v{VERSION}.{ext}` (fixed, immutable)
  - Format: `biorempp_database_v1.0.0.csv`, `biorempp_database_v1.0.0.xlsx`
  - JSON analyses: `{metric}_statistics.json` (e.g., `compound_statistics.json`, `ko_statistics.json`)

**Directories:**

- **Layer directories:** `{priority}_{layer_name}` within `workflow/rules/` (e.g., `00_preflight.smk` is a single file, not a directory)
- **Script subdirectories:** `{layer_name}` within `workflow/scripts/` (generation/, analysis/, validation/, reporting/)
- **Results subdirectories:** `{artifact_type}` (database/, analysis/, metadata/, reports/)
- **Log files:** `{rule_name}.log` (e.g., `load_local_data.log`, `analysis_basic_statistics.log`)

## Where to Add New Code

**New Data Validation Rule:**
- Primary code: Add rule to `biorempp_snakemake_version/workflow/rules/30_validation.smk` (or new `.smk` file if major layer)
- Script implementation: `biorempp_snakemake_version/workflow/scripts/validation/{sequence}_{operation}.py` (Python preferred for API validation)
- Log file: Auto-generated at `biorempp_snakemake_version/logs/{rule_name}.log`
- Register in Snakefile: Add `include:` directive if new rule file

**New Analysis Statistic:**
- Primary code: Add rule to `biorempp_snakemake_version/workflow/rules/20_analysis.smk`
- Script implementation: `biorempp_snakemake_version/workflow/scripts/analysis/{next_sequence}_{operation}.R` (follow 01-09 numbering)
- Output: `biorempp_snakemake_version/results/analysis/{operation}_statistics.json` OR `{operation}.json`
- Integration: Update `biorempp_snakemake_version/workflow/scripts/analysis/09_merge_complete_analysis.R` to include new JSON file

**New Input/Output Contract:**
- Definition: Add to `biorempp_snakemake_version/workflow/lib/io_contracts.R`
- Reference: Call contract validator in relevant generation script
- Documentation: Update `biorempp_validation/great_expectations/expectations/database_critical.json` with new expectations

**New Great Expectations Validation Suite:**
- Expectation JSON: Create `biorempp_validation/great_expectations/expectations/{suite_name}.json`
- Register in config: Add to `biorempp_validation/config/validation.yaml` under appropriate severity (critical/warning)
- Checkpoint assignment: Assign to `critical_gate` or `warning_report` checkpoint in `great_expectations/checkpoints/`
- Test: Add test case to `biorempp_validation/tests/test_*.py`

**Shared Utility Functions:**
- R utilities: Add to `biorempp_snakemake_version/workflow/lib/utils.R` (load_required_packages, parse_cli_args, log_message, etc.)
- Python utilities: Add to `biorempp_validation/src/biorempp_validation/` (loaders.py, consistency_checks.py, etc.)
- Usage: Source with `source("workflow/lib/utils.R")` in R scripts; import in Python modules

**Documentation:**
- User docs: `docs/user-guide/` (Markdown files)
- Technical docs: `docs/technical/` (Markdown files)
- API/schema reference: `docs/reference/` (Markdown files)
- Build locally: `mkdocs serve` (requires `pip install -r requirements.txt`)

## Special Directories

**biorempp_snakemake_version/work/**
- Purpose: Intermediate serialized R objects
- Generated: Yes (created by generation rules)
- Committed: No (in `.gitignore`)
- Cleanup: Snakemake clears with `--delete-temp-outputs` flag

**biorempp_snakemake_version/results/**
- Purpose: Final outputs for release
- Generated: Yes (created by all rules)
- Committed: Yes (for v1.0.0 release reproducibility)
- Note: Versioned files (e.g., `biorempp_database_v1.0.0.csv`) remain stable; new versions need new filenames

**biorempp_snakemake_version/.snakemake/**
- Purpose: Snakemake system metadata (locks, logs, caches)
- Generated: Yes (auto-created by Snakemake)
- Committed: No (in `.gitignore`)
- Note: Safe to delete; Snakemake regenerates as needed

**biorempp_validation/results/**
- Purpose: Validation framework outputs (checkpoint results, HTML data docs)
- Generated: Yes (created by `run_validation.py`)
- Committed: No (in `.gitignore`)
- Note: Review after validation run to verify suite results

**input_data/**
- Purpose: Canonical input location
- Generated: No (user-provided or copy from external source)
- Committed: Yes (required for reproducibility)
- Note: Symlink supported; pipeline resolves `../input_data` from Snakefile directory

**.archive/**
- Purpose: Historical code, obsolete components, research drafts
- Generated: No (curated by maintainers)
- Committed: Yes (for historical reference)
- Note: Not part of active pipeline; kept for audit trail

---

*Structure analysis: 2026-03-24*
