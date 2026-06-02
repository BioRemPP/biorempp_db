# Codebase Structure

_Last updated: 2026-05-31_

## Summary

The project root contains two major subsystems: `biorempp_snakemake_version/` (the Snakemake + R pipeline that generates the database) and `biorempp_validation/` (the standalone Python/Great Expectations post-generation quality layer). Documentation lives in `docs/` with a built site in `site/`. Legacy or auxiliary scripts are in `scripts/`. Input data files are in `input_data/` (root level, consumed by the pipeline via symlink or config path `../input_data`).

---

## Directory Layout

```
BioRemPP_DB_1.0.0/                         # Project root
│
├── biorempp_snakemake_version/            # Snakemake pipeline (generates the database)
│   ├── Snakefile                          # Pipeline entry point
│   ├── config/
│   │   └── config.yaml                   # Version, paths, KEGG endpoints, analysis params
│   ├── workflow/
│   │   ├── rules/                         # Snakemake rule definitions (one file per phase)
│   │   │   ├── 00_preflight.smk
│   │   │   ├── 10_generation.smk
│   │   │   ├── 20_analysis.smk
│   │   │   ├── 30_validation.smk
│   │   │   └── 90_reporting.smk
│   │   ├── lib/                           # Shared R libraries (sourced by all R scripts)
│   │   │   ├── io_contracts.R             # EXPECTED_DATABASE_COLUMNS, REQUIRED_INPUT_FILES, KEGG_ENDPOINTS
│   │   │   ├── utils.R                    # CLI parsing, logging, NA normalization, I/O helpers
│   │   │   └── na_markers.txt             # Custom NA marker strings (sourced by utils.R)
│   │   └── scripts/
│   │       ├── generation/                # R scripts 00–07: data ingestion → database CSV
│   │       │   ├── 00_check_inputs.R
│   │       │   ├── 01_load_local_data.R
│   │       │   ├── 02_fetch_kegg_info.R
│   │       │   ├── 03_fetch_kegg_data.R
│   │       │   ├── 04_merge_relationships.R   # 6-stage fallback chain
│   │       │   ├── 05_add_classifications.R
│   │       │   ├── 06_enrich_gene_info.R
│   │       │   └── 07_extract_enzymes_export.R
│   │       ├── analysis/                  # R scripts 01–09: statistics and metadata JSONs
│   │       │   ├── 01_basic_statistics.R
│   │       │   ├── 02_compound_statistics.R
│   │       │   ├── 03_ko_statistics.R
│   │       │   ├── 04_enzyme_statistics.R
│   │       │   ├── 05_gene_statistics.R
│   │       │   ├── 06_crosstab_statistics.R
│   │       │   ├── 07_metadata.R
│   │       │   ├── 08_executive_summary.R
│   │       │   └── 09_merge_complete_analysis.R
│   │       ├── validation/                # Python scripts: KEGG cache + key validation
│   │       │   ├── cache_kegg_links.py
│   │       │   ├── kegg_api_client.py
│   │       │   ├── common_normalization.py
│   │       │   ├── 01_validate_keys_consistency_api.py
│   │       │   └── 02_validate_links_groundtruth_policy_api.py
│   │       └── reporting/                 # Python script: workflow summary report
│   │           └── build_run_report.py
│   ├── input_data/                        # Symlink or copy of ../input_data (6 source files)
│   │   ├── kegglistcompounds.xlsx
│   │   ├── compostos_todasagencias.xlsx
│   │   ├── missing_compounds_founds_curated.xlsx
│   │   ├── confirm_class_CURATED.xlsx
│   │   ├── kegglistko.txt
│   │   └── enzymes_unique.txt
│   ├── results/                           # Final pipeline outputs (committed or archived)
│   │   ├── database/
│   │   │   ├── biorempp_database_v1.1.0.csv     # Primary deliverable (;-delimited, UTF-8)
│   │   │   └── biorempp_database_v1.1.0.xlsx    # Excel mirror
│   │   ├── analysis/                             # 9 statistics + metadata JSON files
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
│   │   │   └── links_groundtruth_policy_report.json
│   │   └── reports/
│   │       └── workflow_summary.json
│   ├── work/                              # Transient RDS intermediates (gitignored)
│   │   ├── preflight_ok.json
│   │   ├── local_data.rds
│   │   ├── kegg_data.rds
│   │   ├── merged_compounds.rds
│   │   ├── classified_compounds.rds
│   │   └── enriched_compounds.rds
│   ├── cache/
│   │   └── kegg_link_cache/               # 5 KEGG link TSVs cached for validation
│   │       ├── ko_ec.tsv
│   │       ├── ko_reaction.tsv
│   │       ├── cpd_ec.tsv
│   │       ├── cpd_reaction.tsv
│   │       └── ec_reaction.tsv
│   ├── logs/                              # Per-rule log files from Snakemake shell calls
│   ├── env/                               # Conda environment definition files
│   └── scripts/                          # Standalone helper/utility scripts (not in Snakemake DAG)
│
├── biorempp_validation/                   # Post-pipeline GX validation (standalone Python pkg)
│   ├── config/
│   │   └── validation.yaml               # Validation settings, thresholds, column contract
│   ├── src/
│   │   └── biorempp_validation/           # Installable Python package (src layout)
│   │       ├── run_validation.py          # CLI entry point and main orchestrator
│   │       ├── settings.py               # ValidationSettings dataclass + YAML loader
│   │       ├── loaders.py                # File resolution and data loading
│   │       ├── json_to_dataframe.py      # Analysis JSON → pandas DataFrame converters
│   │       ├── consistency_checks.py     # Cross-consistency DataFrame builder
│   │       ├── gx_context.py             # Great Expectations context and suite runner
│   │       └── report_builder.py         # Builds validation_summary dict
│   ├── great_expectations/
│   │   ├── checkpoints/
│   │   │   ├── critical_gate.yml         # Fail-fast checkpoint config
│   │   │   └── warning_report.yml        # Warning-only checkpoint config
│   │   ├── expectations/                  # GX expectation suite JSON files
│   │   │   ├── database_critical.json
│   │   │   ├── database_warning.json
│   │   │   ├── analysis_json_critical.json
│   │   │   ├── analysis_json_exact_critical.json
│   │   │   ├── analysis_json_warning.json
│   │   │   ├── cross_consistency_critical.json
│   │   │   ├── metadata_kegg_critical.json
│   │   │   └── pipeline_reports_critical.json
│   │   └── plugins/                       # Custom GX expectation plugins
│   ├── baselines/
│   │   └── release_v1_1_0_kegg_118_0plus/ # Pinned baseline for regression detection
│   │       ├── analysis/                  # Frozen analysis JSONs
│   │       └── metadata/                  # Frozen kegg_release.json
│   ├── results/                           # GX output (written by run_validation.py)
│   │   ├── critical_checkpoint_result.json
│   │   ├── warning_checkpoint_result.json
│   │   ├── validation_summary.json
│   │   └── data_docs/
│   │       └── index.html                # HTML summary page
│   ├── tests/                             # pytest unit tests for validation package
│   ├── env/                               # Conda environment for validation
│   └── docs/                              # GX validation documentation
│
├── input_data/                            # Source input files (root-level canonical copy)
│   ├── kegglistcompounds.xlsx
│   ├── compostos_todasagencias.xlsx
│   ├── missing_compounds_founds_curated.xlsx
│   ├── confirm_class_CURATED.xlsx
│   ├── kegglistko.txt
│   └── enzymes_unique.txt
│
├── output_data/                           # Legacy or archived output artifacts
│
├── scripts/                               # Root-level utility/auxiliary scripts
│
├── docs/                                  # MkDocs source documentation
│   ├── about/
│   ├── database/
│   ├── getting-started/
│   ├── interoperability/
│   ├── reference/
│   ├── technical/
│   ├── user-guide/
│   ├── validation/
│   └── validation-gx/
│
├── site/                                  # Built MkDocs HTML site (gitignored or generated)
│
├── .planning/                             # GSD planning documents
│   └── codebase/
│       ├── ARCHITECTURE.md
│       └── STRUCTURE.md
│
└── biorempp_validation/BASELINE_AUDIT_2026-05-31.md   # Ad-hoc audit file (untracked)
```

---

## Directory Purposes

### `biorempp_snakemake_version/`

The main pipeline subsystem. Must be run from inside this directory so that relative paths in R scripts (`workflow/lib/utils.R`, `workflow/lib/io_contracts.R`, `config/config.yaml`) resolve correctly.

- `config/config.yaml` — single configuration file controlling version string, path prefixes, KEGG base URL, analysis `top_n` parameters, and validation thresholds
- `workflow/lib/` — shared R libraries; every generation and analysis script `source()`s `utils.R`; scripts that produce final database rows also `source()` `io_contracts.R`
- `workflow/rules/` — Snakemake rule files; numbered by phase (00/10/20/30/90) to reflect execution order
- `workflow/scripts/generation/` — numbered `00–07`; each script is an independent Rscript callable; intermediate state is RDS in `work/`
- `workflow/scripts/analysis/` — numbered `01–09`; read the final CSV from `results/database/`; write JSON to `results/analysis/`
- `workflow/scripts/validation/` — Python; fetch KEGG link caches and run two structural validation passes
- `workflow/scripts/reporting/` — Python; aggregates everything into `workflow_summary.json`
- `results/` — committed output tree; the `results/database/` subdirectory contains the versioned database CSV and XLSX
- `work/` — transient RDS files; safe to delete and regenerate; not committed
- `cache/kegg_link_cache/` — optional KEGG link TSV cache for validation; regenerated by `fetch_kegg_link_cache` rule

### `biorempp_validation/`

A standalone `src`-layout Python package. Install with `pip install -e biorempp_validation/` before running. Invoked as:

```
python -m biorempp_validation.run_validation --config biorempp_validation/config/validation.yaml
```

or via the `main_cli` entry point. Does **not** need to be run from inside the Snakemake directory; it reads the pipeline results tree via the `input_results_root` path in `validation.yaml`.

- `config/validation.yaml` — all tunables: thresholds, column contract, nullable columns, expected agencies, compound classes, baseline path, mode flags
- `great_expectations/expectations/` — 8 GX suite JSON files; `_apply_config_overrides_to_suite_payloads()` in `run_validation.py` injects dynamic values (column list, thresholds) at runtime so the JSON files do not need manual editing when thresholds change
- `baselines/release_v1_1_0_kegg_118_0plus/` — pinned reference snapshot for regression detection mode; update by running the pipeline with a new KEGG version and copying `results/analysis/` and `results/metadata/kegg_release.json` into a new baseline directory

### `input_data/` (root level)

The six required source files. These are referenced by the Snakemake config as `../input_data` (relative to `biorempp_snakemake_version/`). The pipeline's `00_check_inputs.R` verifies all six are present before any generation steps run.

### `docs/` and `site/`

MkDocs-based documentation. `docs/` is the Markdown source; `site/` is the generated HTML output. Not involved in pipeline execution.

---

## Key File Locations

### Entry Points

- **Pipeline**: `biorempp_snakemake_version/Snakefile` — run `snakemake --cores N` from inside `biorempp_snakemake_version/`
- **Validation**: `biorempp_validation/src/biorempp_validation/run_validation.py` — `main_cli()` entry point
- **Configuration (pipeline)**: `biorempp_snakemake_version/config/config.yaml`
- **Configuration (validation)**: `biorempp_validation/config/validation.yaml`

### Schema Contract

- **R definition**: `biorempp_snakemake_version/workflow/lib/io_contracts.R` (`EXPECTED_DATABASE_COLUMNS`, lines 12–25)
- **YAML mirror**: `biorempp_validation/config/validation.yaml` (`database_contract.expected_columns`, lines 44–57)
- **Enforcement point**: `biorempp_snakemake_version/workflow/scripts/generation/07_extract_enzymes_export.R` (line 60)

### Core Logic

- **6-stage fallback merge**: `biorempp_snakemake_version/workflow/scripts/generation/04_merge_relationships.R`
- **Analysis metadata + link provenance**: `biorempp_snakemake_version/workflow/scripts/analysis/07_metadata.R`
- **GX validation orchestrator**: `biorempp_validation/src/biorempp_validation/run_validation.py`
- **Shared R utilities**: `biorempp_snakemake_version/workflow/lib/utils.R`

### Primary Database Output

- `biorempp_snakemake_version/results/database/biorempp_database_v1.1.0.csv` — `;`-delimited, UTF-8, quoted, 12 columns
- `biorempp_snakemake_version/results/database/biorempp_database_v1.1.0.xlsx` — Excel mirror

### Validation Outputs

- `biorempp_validation/results/validation_summary.json`
- `biorempp_validation/results/critical_checkpoint_result.json`
- `biorempp_validation/results/warning_checkpoint_result.json`

---

## Naming Conventions

**Scripts:**
- R generation scripts: `NN_snake_case.R` where NN is two-digit step number
- R analysis scripts: `NN_snake_case.R`
- Python validation scripts: `NN_snake_case.py` or `snake_case.py` for libraries
- Snakemake rules: `NN_description.smk` numbered by phase

**Intermediate files in `work/`:**
- `<stage_name>.rds` — e.g., `merged_compounds.rds`, `classified_compounds.rds`

**Result files:**
- JSONs: `<topic>.json` (e.g., `basic_statistics.json`, `keys_consistency_report.json`)
- Database: `biorempp_database_v<version>.csv` / `.xlsx`

**KEGG identifiers in data:**
- Compounds: `C` + 5 digits (e.g., `C00001`)
- KO: `K` + 5 digits (e.g., `K00001`)
- Reactions: `R` + 5 digits (e.g., `R00623`)
- EC: dot-notation (e.g., `1.1.1.1`)

---

## Where to Add New Code

**New generation step (between existing steps):**
- Add R script to `biorempp_snakemake_version/workflow/scripts/generation/` with next sequential number
- Add corresponding Snakemake rule to `biorempp_snakemake_version/workflow/rules/10_generation.smk`
- Output to `work/<name>.rds`; consume `utils.R` and optionally `io_contracts.R`

**New analysis statistic:**
- Add R script to `biorempp_snakemake_version/workflow/scripts/analysis/`
- Add rule to `workflow/rules/20_analysis.smk`
- Add output JSON path to `ANALYSIS_FILES` list in `Snakefile`
- Update `09_merge_complete_analysis.R` to include the new JSON in `complete_analysis.json`
- Update `run_validation.py` and relevant GX suites if the new statistic needs validation

**New database column:**
- Update `EXPECTED_DATABASE_COLUMNS` in `workflow/lib/io_contracts.R`
- Update `database_contract.expected_columns` in `biorempp_validation/config/validation.yaml`
- Update `nullable_columns` in `validation.yaml` if the column can be NA
- Update `07_extract_enzymes_export.R` to populate the column before the `select(all_of(...))` gate
- Update `07_metadata.R` schema section and `completeness` computation
- Update drift thresholds in `validation.yaml` if the column has a bounded unique-value expectation
- Update `analysis_json_exact_critical.json` `basic_total_columns` expectation bounds

**New validation expectation:**
- Add or modify JSON in `biorempp_validation/great_expectations/expectations/`
- Register the suite name in the appropriate checkpoint YAML (`critical_gate.yml` or `warning_report.yml`)
- If dynamic values are needed, add an override branch in `_apply_config_overrides_to_suite_payloads()` in `run_validation.py`

**New KEGG endpoint:**
- Add endpoint name and path to `config/config.yaml` under `kegg.endpoints`
- Add named entry to `KEGG_ENDPOINTS` in `workflow/lib/io_contracts.R`
- Update `03_fetch_kegg_data.R` to fetch and bundle the new endpoint

---

## Special Directories

**`work/`** — RDS intermediate files
- Generated: Yes (by Snakemake)
- Committed: No (transient; safe to delete)

**`cache/kegg_link_cache/`** — KEGG link TSVs
- Generated: Yes (by `fetch_kegg_link_cache` rule)
- Committed: Optional (can be committed to avoid repeated KEGG fetches; regenerated if missing)

**`biorempp_validation/baselines/`** — Regression baseline snapshots
- Generated: Manually (copy `results/analysis/` + `results/metadata/kegg_release.json` from a reference run)
- Committed: Yes (frozen reference for regression detection)

**`site/`** — Built MkDocs HTML
- Generated: Yes (by `mkdocs build`)
- Committed: Project-dependent

**`.planning/codebase/`** — GSD planning documents
- Generated: Yes (by GSD map-codebase agent)
- Committed: Yes (planning artifacts)

---

*Structure analysis: 2026-05-31*
