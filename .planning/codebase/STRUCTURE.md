# Codebase Structure

**Analysis Date:** 2026-05-17

## Directory Layout

```
BioRemPP_DB_1.0.0/                          # Project root
├── generate_database.R                      # Standalone v1.0.0 monolithic generator (legacy)
├── requirements.txt                         # Python dependencies for MkDocs documentation site
├── mkdocs.yml                               # MkDocs static documentation site configuration
├── LICENSE.md
├── README.md
│
├── input_data/                              # Source data files (checked into git)
│   ├── kegglistcompounds.xlsx               # KEGG compound ID → name reference list
│   ├── compostos_todasagencias.xlsx         # Compound IDs from 9 environmental agencies
│   ├── missing_compounds_founds_curated.xlsx# Manually curated cpd→KO mappings (gap-fill)
│   ├── confirm_class_CURATED.xlsx           # Manually curated compound classifications
│   ├── kegglistko.txt                       # KEGG KO list with gene symbol/name columns
│   ├── enzymes_unique.txt                   # Unique enzyme activity terms for pattern matching
│   ├── biorempp_database_v1.0.0.csv         # Frozen v1.0.0 database (reference copy)
│   └── biorempp_database_v1.0.0.xlsx        # Frozen v1.0.0 database (Excel copy)
│
├── output_data/                             # Output from standalone generate_database.R
│   └── (generated CSV/XLSX — not committed)
│
├── biorempp_snakemake_version/              # Snakemake pipeline (v1.1.0 and forward)
│   ├── Snakefile                            # Pipeline entry point — declares all final outputs
│   ├── config/
│   │   └── config.yaml                      # All pipeline config: paths, KEGG endpoints, version
│   ├── env/                                 # Reproducible environment definitions
│   │   ├── Dockerfile                       # rocker/tidyverse:4.3 + Python3 image
│   │   ├── docker-compose.yml
│   │   ├── python-requirements.txt          # Python packages for pipeline scripts
│   │   └── r-packages.txt                   # R packages installed at Docker build time
│   ├── workflow/
│   │   ├── rules/                           # Snakemake rule files (numbered by stage)
│   │   │   ├── 00_preflight.smk             # Input file existence check
│   │   │   ├── 10_generation.smk            # Database generation rules (7 steps)
│   │   │   ├── 20_analysis.smk              # Statistical analysis rules (9 steps)
│   │   │   ├── 30_validation.smk            # KEGG API validation rules (2 steps)
│   │   │   └── 90_reporting.smk             # Workflow summary report rule
│   │   ├── lib/                             # Shared R library code
│   │   │   ├── io_contracts.R               # Canonical column names, KEGG endpoints, patterns
│   │   │   ├── utils.R                      # Shared CLI parsing, package loading helpers
│   │   │   └── na_markers.txt               # List of NA-like string values for normalization
│   │   └── scripts/                         # Implementation scripts grouped by stage
│   │       ├── generation/                  # R scripts for database construction
│   │       │   ├── 00_check_inputs.R        # Validates required input files exist
│   │       │   ├── 01_load_local_data.R     # Loads and parses all XLSX/TXT input files
│   │       │   ├── 02_fetch_kegg_info.R     # Fetches KEGG release metadata
│   │       │   ├── 03_fetch_kegg_data.R     # Fetches all KEGG link/list endpoints
│   │       │   ├── 04_merge_relationships.R # Joins local + KEGG data on EC/reaction keys
│   │       │   ├── 05_add_classifications.R # Joins curated compound class annotations
│   │       │   ├── 06_enrich_gene_info.R    # Joins KO → gene symbol/name
│   │       │   └── 07_extract_enzymes_export.R # Extracts enzyme terms, exports CSV+XLSX
│   │       ├── analysis/                    # R scripts for statistical summaries
│   │       │   ├── 01_basic_statistics.R
│   │       │   ├── 02_compound_statistics.R
│   │       │   ├── 03_ko_statistics.R
│   │       │   ├── 04_enzyme_statistics.R
│   │       │   ├── 05_gene_statistics.R
│   │       │   ├── 06_crosstab_statistics.R
│   │       │   ├── 07_metadata.R
│   │       │   ├── 08_executive_summary.R
│   │       │   └── 09_merge_complete_analysis.R
│   │       ├── validation/                  # Python scripts for KEGG API validation
│   │       │   ├── 01_validate_keys_consistency_api.py
│   │       │   ├── 02_validate_links_groundtruth_policy_api.py
│   │       │   └── common_normalization.py  # Shared NA detection, token normalization
│   │       └── reporting/                   # Python script for workflow summary
│   │           └── build_run_report.py
│   ├── input_data -> ../input_data          # Symlink or reference (pipeline uses ../input_data)
│   ├── results/                             # All pipeline outputs (generated, not committed)
│   │   ├── database/
│   │   │   ├── biorempp_database_v1.1.0.csv
│   │   │   └── biorempp_database_v1.1.0.xlsx
│   │   ├── analysis/                        # Per-entity statistics JSON files
│   │   │   ├── basic_statistics.json
│   │   │   ├── compound_statistics.json
│   │   │   ├── ko_statistics.json
│   │   │   ├── enzyme_statistics.json
│   │   │   ├── gene_statistics.json
│   │   │   ├── crosstab_statistics.json
│   │   │   ├── database_metadata.json
│   │   │   ├── executive_summary.json
│   │   │   └── complete_analysis.json
│   │   ├── metadata/
│   │   │   ├── kegg_release.json
│   │   │   ├── keys_consistency_report.json
│   │   │   ├── links_groundtruth_policy_report.json
│   │   │   └── link_consistency_audit.json
│   │   └── reports/
│   │       └── workflow_summary.json        # SHA-256 checksums + run metadata
│   ├── work/                                # Intermediate .rds files (generated, not committed)
│   │   ├── preflight_ok.json
│   │   ├── local_data.rds
│   │   ├── kegg_data.rds
│   │   ├── merged_compounds.rds
│   │   ├── classified_compounds.rds
│   │   └── enriched_compounds.rds
│   └── logs/                                # Per-rule log files (generated)
│
├── biorempp_validation/                     # GX validation Python package (post-pipeline QA)
│   ├── config/
│   │   └── validation.yaml                  # Validation config: thresholds, expected columns
│   ├── src/biorempp_validation/             # Installable Python package
│   │   ├── __init__.py
│   │   ├── run_validation.py                # CLI entrypoint for validation run
│   │   ├── settings.py                      # ValidationSettings dataclass + loader
│   │   ├── loaders.py                       # File loading utilities (CSV, JSON, path resolution)
│   │   ├── gx_context.py                    # Great Expectations context factory
│   │   ├── json_to_dataframe.py             # Converts analysis JSON payloads to GX DataFrames
│   │   ├── consistency_checks.py            # Builds cross-consistency DataFrame
│   │   └── report_builder.py                # Builds validation_summary.json
│   ├── great_expectations/
│   │   ├── checkpoints/
│   │   │   ├── critical_gate.yml            # Fail-blocking checkpoint (schema, key counts)
│   │   │   └── warning_report.yml           # Warning-only checkpoint (drift thresholds)
│   │   ├── expectations/                    # GX expectation suite JSON files
│   │   │   ├── database_critical.json       # Column schema, null checks on CSV
│   │   │   ├── database_warning.json        # Drift thresholds, value set checks on CSV
│   │   │   ├── analysis_json_critical.json  # Critical checks on analysis JSON payloads
│   │   │   ├── analysis_json_exact_critical.json # Exact count pinning (strict_exact mode)
│   │   │   ├── analysis_json_warning.json   # Warning checks on analysis JSON payloads
│   │   │   ├── metadata_kegg_critical.json  # KEGG release metadata checks
│   │   │   └── cross_consistency_critical.json # CSV vs JSON cross-consistency checks
│   │   └── plugins/                         # Custom GX expectation implementations
│   ├── tests/                               # pytest test suite for the validation package
│   │   ├── conftest.py
│   │   ├── test_happy_path.py
│   │   ├── test_kegg_metadata.py
│   │   ├── test_missing_files.py
│   │   ├── test_schema_break.py
│   │   └── test_warning_only_drift.py
│   └── results/                             # GX validation outputs (generated)
│       ├── critical_checkpoint_result.json
│       ├── warning_checkpoint_result.json
│       ├── validation_summary.json
│       └── data_docs/index.html
│
├── scripts/                                 # Project-level utility scripts
│   └── build-docs.sh                        # Builds MkDocs documentation site
│
├── docs/                                    # MkDocs source documentation
│   ├── index.md
│   ├── about/
│   ├── database/
│   ├── getting-started/
│   ├── interoperability/
│   ├── reference/
│   ├── stylesheets/extra.css
│   ├── technical/
│   ├── user-guide/
│   ├── validation/
│   └── validation-gx/
│
├── site/                                    # MkDocs built static site (generated)
│
├── .github/workflows/
│   └── docs-ci.yml                          # GitHub Actions: build and deploy docs
│
├── .archive/                                # Historical/draft materials (not production)
│   ├── .planning/codebase/                  # Archived planning documents
│   ├── draft_papper/
│   ├── gx_documentation/
│   ├── links/
│   └── V1.1.0/
│
└── .benchmarks/                             # Performance benchmarks
```

## Directory Purposes

**`input_data/`:**
- Purpose: All curated source data files that feed the database generation pipeline
- Contains: XLSX spreadsheets from 9 environmental agencies, curated compound-KO mappings, KEGG compound/KO lists, enzyme activity terms
- Key files: `compostos_todasagencias.xlsx`, `confirm_class_CURATED.xlsx`, `kegglistko.txt`, `enzymes_unique.txt`
- Committed: Yes — these are the versioned ground-truth inputs

**`biorempp_snakemake_version/workflow/rules/`:**
- Purpose: Snakemake rule definitions — declare input/output dependencies and shell commands only; no business logic
- Contains: 5 `.smk` files numbered by execution stage (00, 10, 20, 30, 90)
- Key files: `10_generation.smk` (7 rules), `20_analysis.smk` (9 rules)

**`biorempp_snakemake_version/workflow/lib/`:**
- Purpose: Shared R library code sourced by all generation scripts
- Key file: `io_contracts.R` — defines `REQUIRED_INPUT_FILES`, `EXPECTED_DATABASE_COLUMNS`, `KEGG_ENDPOINTS`, `KEGG_VALUE_PATTERNS`

**`biorempp_snakemake_version/workflow/scripts/`:**
- Purpose: Implementation code organized by pipeline stage
- Organized by: Stage (generation, analysis, validation, reporting) — not by feature
- Naming: `NN_descriptive_name.{R,py}` — two-digit numeric prefix determines execution order within stage

**`biorempp_snakemake_version/work/`:**
- Purpose: Scratch directory for intermediate `.rds` files passed between generation rules
- Generated: Yes — created at runtime, not committed

**`biorempp_snakemake_version/results/`:**
- Purpose: All pipeline outputs, organized by output type
- Subdirs: `database/` (final CSV+XLSX), `analysis/` (JSON statistics), `metadata/` (KEGG release + validation reports), `reports/` (workflow summary)

**`biorempp_validation/src/biorempp_validation/`:**
- Purpose: Installable Python package implementing GX-based data contract validation
- Contains: 7 Python modules with clear single responsibilities

**`biorempp_validation/great_expectations/`:**
- Purpose: GX configuration — expectation suites (JSON) and checkpoints (YAML)
- Expectations are split by severity: `*_critical` suites block CI; `*_warning` suites report only

**`biorempp_validation/tests/`:**
- Purpose: pytest tests for the validation package itself (not the database)
- Key files: `test_happy_path.py`, `test_schema_break.py`, `test_missing_files.py`, `test_warning_only_drift.py`

**`docs/`:**
- Purpose: MkDocs source markdown for the project documentation site
- Organized by: Topic area (getting-started, technical, database, validation, validation-gx, etc.)

## Key File Locations

**Entry Points:**
- `biorempp_snakemake_version/Snakefile`: Snakemake pipeline entry point
- `biorempp_validation/src/biorempp_validation/run_validation.py`: GX validation CLI entry
- `generate_database.R`: Legacy standalone generator

**Configuration:**
- `biorempp_snakemake_version/config/config.yaml`: Pipeline version, paths, KEGG endpoints, analysis parameters
- `biorempp_validation/config/validation.yaml`: GX validation thresholds, expected schema, file requirements
- `biorempp_snakemake_version/env/Dockerfile`: Reproducible execution environment
- `mkdocs.yml`: Documentation site configuration

**Core Logic:**
- `biorempp_snakemake_version/workflow/lib/io_contracts.R`: Canonical column/endpoint definitions
- `biorempp_snakemake_version/workflow/scripts/generation/07_extract_enzymes_export.R`: Final export step (produces database CSV/XLSX)
- `biorempp_validation/src/biorempp_validation/settings.py`: ValidationSettings dataclass
- `biorempp_validation/src/biorempp_validation/run_validation.py`: Full GX validation orchestration

**Testing:**
- `biorempp_validation/tests/`: pytest tests for the GX validation package

## Naming Conventions

**Files:**
- Snakemake rules: `NN_stage_name.smk` (e.g., `10_generation.smk`, `30_validation.smk`)
- Scripts: `NN_descriptive_name.R` or `NN_descriptive_name.py` (e.g., `04_merge_relationships.R`)
- GX expectation suites: `{dataset}_{severity}.json` (e.g., `database_critical.json`, `analysis_json_warning.json`)
- Results: `{entity}_statistics.json` (e.g., `compound_statistics.json`, `ko_statistics.json`)
- Databases: `biorempp_database_v{version}.csv` / `.xlsx`

**Python modules:** `snake_case.py`

**R scripts:** `snake_case.R`

**Directories:** `snake_case/` for scripts; `kebab-case/` inside `docs/` (e.g., `getting-started/`, `validation-gx/`)

## Where to Add New Code

**New generation step (new KEGG field, new enrichment):**
- Add R script to `biorempp_snakemake_version/workflow/scripts/generation/` with next numeric prefix (e.g., `08_new_step.R`)
- Add corresponding rule to `biorempp_snakemake_version/workflow/rules/10_generation.smk`
- Update `EXPECTED_DATABASE_COLUMNS` in `biorempp_snakemake_version/workflow/lib/io_contracts.R`
- Update `expected_columns` in `biorempp_validation/config/validation.yaml`
- Update GX expectations in `biorempp_validation/great_expectations/expectations/database_critical.json`

**New analysis statistic:**
- Add R script to `biorempp_snakemake_version/workflow/scripts/analysis/` with next numeric prefix
- Add corresponding rule to `biorempp_snakemake_version/workflow/rules/20_analysis.smk`
- Add new JSON output to `ANALYSIS_FILES` list in `biorempp_snakemake_version/Snakefile`
- Update `biorempp_snakemake_version/workflow/scripts/analysis/09_merge_complete_analysis.R` to include it

**New KEGG validation check:**
- Add or modify Python script in `biorempp_snakemake_version/workflow/scripts/validation/`
- Add corresponding rule to `biorempp_snakemake_version/workflow/rules/30_validation.smk`

**New GX expectation:**
- Add expectation to appropriate JSON file in `biorempp_validation/great_expectations/expectations/`
- If new severity level needed, create new checkpoint in `biorempp_validation/great_expectations/checkpoints/`

**New shared R utility:**
- Add to `biorempp_snakemake_version/workflow/lib/utils.R` (shared helpers) or `io_contracts.R` (constants)

**New documentation section:**
- Add markdown file under appropriate `docs/` subdirectory
- Register it in the `nav:` section of `mkdocs.yml`

## Special Directories

**`biorempp_snakemake_version/work/`:**
- Purpose: Intermediate `.rds` data objects between generation rules
- Generated: Yes — created at runtime by Snakemake
- Committed: No

**`biorempp_snakemake_version/results/`:**
- Purpose: Final pipeline outputs (database + JSON artifacts)
- Generated: Yes — produced by pipeline run
- Committed: Yes (for the current released version outputs)

**`biorempp_snakemake_version/.snakemake/`:**
- Purpose: Snakemake internal state (metadata, conda envs, locks)
- Generated: Yes — Snakemake runtime
- Committed: No

**`biorempp_validation/results/`:**
- Purpose: GX validation output reports
- Generated: Yes — produced by validation run
- Committed: Partially (summary reports may be committed as QA artifacts)

**`site/`:**
- Purpose: MkDocs built static HTML documentation site
- Generated: Yes — by `mkdocs build` or `scripts/build-docs.sh`
- Committed: No (built by CI)

**`.archive/`:**
- Purpose: Historical materials, draft papers, previous planning documents — not production code
- Committed: Yes — preserved for reference

---

*Structure analysis: 2026-05-17*
