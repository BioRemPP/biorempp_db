# STRUCTURE — BioRemPP DB 1.0.0

> Last mapped: 2026-05-31

## Summary

The repository has two execution surfaces: a monolithic legacy R script at the root and a fully-structured Snakemake pipeline under `biorempp_snakemake_version/`. All active development targets the Snakemake tree. A standalone Python validation package lives in `biorempp_validation/`. Documentation is managed with MkDocs under `docs/`.

---

## Annotated Directory Tree

```
BioRemPP_DB_1.0.0/                        ← repo root
│
├── generate_database.R                    ← LEGACY monolithic generator (v1.0.0)
├── requirements.txt                       ← root-level Python deps (likely for validation venv)
├── mkdocs.yml                             ← MkDocs site config
├── LICENSE.md
├── README.md
│
├── input_data/                            ← SHARED local input files (both legacy and pipeline)
│   ├── kegglistcompounds.xlsx             ← KEGG compound list (cpd → compoundname)
│   ├── compostos_todasagencias.xlsx       ← Agency compound list (cpd → referenceAG)
│   ├── missing_compounds_founds_curated.xlsx ← Manual curations (cpd → ko)
│   ├── confirm_class_CURATED.xlsx         ← Compound class assignments (cpd → compoundclass)
│   ├── kegglistko.txt                     ← KO reference (ko, genesymbol, genename)
│   └── enzymes_unique.txt                 ← Enzyme activity terms for regex extraction
│
├── output_data/                           ← LEGACY output (v1.0.0 static release)
│   ├── biorempp_database_v1.0.0.csv
│   └── biorempp_database_v1.0.0.xlsx
│
├── docs/                                  ← MkDocs source pages
│   ├── index.md
│   ├── about/
│   ├── database/
│   ├── getting-started/
│   ├── interoperability/
│   ├── reference/
│   ├── stylesheets/
│   ├── technical/
│   ├── user-guide/
│   ├── validation/
│   └── validation-gx/
│
├── site/                                  ← MkDocs compiled HTML (generated, not committed)
│
├── scripts/                               ← Root-level helper scripts
│   └── build-docs.sh                      ← Builds MkDocs site
│
├── venv/                                  ← Python virtual environment (not committed)
│
│── biorempp_validation/                   ← Standalone GX validation package
│   ├── pyproject.toml                     ← Package definition, deps (great_expectations ~1.12, pandas 2.x)
│   ├── README.md
│   ├── requirements.txt
│   ├── config/
│   │   └── validation.yaml                ← Validation run config (paths, suite references)
│   ├── great_expectations/                ← GX project directory (suites, checkpoints, data docs)
│   ├── src/
│   │   └── biorempp_validation/           ← Python package source
│   │       ├── run_validation.py          ← CLI entry point (`biorempp-validate` command)
│   │       ├── loaders.py                 ← File loading utilities
│   │       ├── json_to_dataframe.py       ← Converts analysis JSON outputs to GX-ready dataframes
│   │       ├── consistency_checks.py      ← Cross-consistency dataframe builder
│   │       ├── gx_context.py              ← Great Expectations context/datasource/checkpoint helpers
│   │       ├── report_builder.py          ← Validation summary report builder
│   │       ├── settings.py                ← ValidationSettings dataclass
│   │       └── __init__.py
│   ├── tests/                             ← pytest test suite for validation package
│   │   ├── conftest.py
│   │   ├── test_happy_path.py
│   │   ├── test_kegg_metadata.py
│   │   ├── test_missing_files.py
│   │   ├── test_schema_break.py
│   │   └── test_warning_only_drift.py
│   └── results/                           ← Validation run outputs
│
└── biorempp_snakemake_version/            ← ACTIVE Snakemake pipeline (v1.1.0)
    ├── Snakefile                          ← Pipeline entry point and DAG definition
    ├── config/
    │   └── config.yaml                    ← All runtime parameters
    ├── scripts/                           ← Launcher scripts
    │   ├── run_snakemake.sh               ← Linux/macOS Docker launcher
    │   └── run_snakemake.bat              ← Windows Docker launcher
    ├── env/                               ← Containerization
    │   ├── Dockerfile                     ← Pinned image (rocker/tidyverse:4.4, Python 3, Snakemake 8)
    │   ├── docker-compose.yml             ← Compose service definition
    │   ├── r-packages.txt                 ← Pinned R package versions manifest
    │   └── python-requirements.txt        ← Pinned Python package versions manifest
    ├── workflow/                          ← All pipeline logic
    │   ├── rules/                         ← Snakemake rule files (numbered by stage)
    │   │   ├── 00_preflight.smk           ← Input validation guard
    │   │   ├── 10_generation.smk          ← Database generation rules (R)
    │   │   ├── 20_analysis.smk            ← Statistical analysis rules (R)
    │   │   ├── 30_validation.smk          ← KEGG cross-validation rules (Python)
    │   │   └── 90_reporting.smk           ← Final summary report rule (Python)
    │   ├── scripts/                       ← Script implementations by stage
    │   │   ├── generation/                ← R scripts 00–07
    │   │   │   ├── 00_check_inputs.R
    │   │   │   ├── 01_load_local_data.R
    │   │   │   ├── 02_fetch_kegg_info.R
    │   │   │   ├── 03_fetch_kegg_data.R
    │   │   │   ├── 04_merge_relationships.R
    │   │   │   ├── 05_add_classifications.R
    │   │   │   ├── 06_enrich_gene_info.R
    │   │   │   └── 07_extract_enzymes_export.R
    │   │   ├── analysis/                  ← R scripts 01–09
    │   │   │   ├── 01_basic_statistics.R
    │   │   │   ├── 02_compound_statistics.R
    │   │   │   ├── 03_ko_statistics.R
    │   │   │   ├── 04_enzyme_statistics.R
    │   │   │   ├── 05_gene_statistics.R
    │   │   │   ├── 06_crosstab_statistics.R
    │   │   │   ├── 07_metadata.R
    │   │   │   ├── 08_executive_summary.R
    │   │   │   └── 09_merge_complete_analysis.R
    │   │   ├── validation/                ← Python scripts + shared modules
    │   │   │   ├── cache_kegg_links.py
    │   │   │   ├── 01_validate_keys_consistency_api.py
    │   │   │   ├── 02_validate_links_groundtruth_policy_api.py
    │   │   │   ├── kegg_api_client.py     ← Shared HTTP client (retry/backoff)
    │   │   │   └── common_normalization.py ← Shared NA/token normalization (mirrors utils.R)
    │   │   └── reporting/
    │   │       └── build_run_report.py    ← Workflow summary with SHA-256 checksums
    │   └── lib/                           ← Shared R library
    │       ├── utils.R                    ← CLI parsing, logging, NA normalization, JSON/CSV I/O
    │       ├── io_contracts.R             ← Required input files, DB column schema, KEGG endpoints
    │       └── na_markers.txt             ← Canonical NA string list (used by R and Python)
    ├── input_data/                        ← Symlink/copy of root input_data used by pipeline
    ├── work/                              ← Intermediate RDS files (Snakemake-managed)
    │   ├── preflight_ok.json
    │   ├── local_data.rds
    │   ├── kegg_data.rds
    │   ├── merged_compounds.rds
    │   ├── classified_compounds.rds
    │   ├── enriched_compounds.rds
    │   └── kegg_link_cache/               ← Cached KEGG link TSVs (ko_ec, ko_reaction, …)
    ├── results/                           ← Final pipeline outputs (Snakemake-managed)
    │   ├── database/
    │   │   ├── biorempp_database_v1.1.0.csv   ← Primary database (semicolon-delimited, quoted)
    │   │   └── biorempp_database_v1.1.0.xlsx
    │   ├── analysis/                      ← 9 JSON statistics files + complete_analysis.json
    │   ├── metadata/
    │   │   ├── kegg_release.json
    │   │   ├── keys_consistency_report.json
    │   │   └── links_groundtruth_policy_report.json
    │   └── reports/
    │       └── workflow_summary.json      ← Terminal artifact: provenance + checksums
    └── logs/                              ← Per-rule Snakemake log files
```

---

## Directory Purposes

### `biorempp_snakemake_version/` — Active pipeline root

The working directory for Snakemake execution. All rules use relative paths from here. `scripts/run_snakemake.sh` `cd`s into this directory before invoking Docker.

### `biorempp_snakemake_version/config/`

Single file (`config.yaml`) controls all configurable parameters: version string, input/output paths, KEGG base URL and endpoint paths, analysis `top_n_*` parameters, and validation `max_invalid_line_ratio`. No code should hard-code values that appear here.

### `biorempp_snakemake_version/workflow/rules/`

Each `.smk` file groups rules for one pipeline stage. File numbering (`00_`, `10_`, `20_`, `30_`, `90_`) mirrors execution order, though Snakemake resolves the actual DAG from file dependencies. New pipeline stages should follow the numeric prefix convention and be `include:`d in `Snakefile`.

### `biorempp_snakemake_version/workflow/scripts/`

Scripts are organized by stage subdirectory (`generation/`, `analysis/`, `validation/`, `reporting/`). Each R script sources `workflow/lib/utils.R` and optionally `workflow/lib/io_contracts.R` at the top. Each script is self-contained: it accepts CLI flags, reads its inputs, writes its output, and logs via `log_message()`.

### `biorempp_snakemake_version/workflow/lib/`

Shared code available to all R scripts. `utils.R` and `io_contracts.R` must be sourced at the top of every R script that uses them. `na_markers.txt` is read at runtime by both `utils.R` and `common_normalization.py`. **Do not add stage-specific logic here.**

### `biorempp_snakemake_version/work/`

Snakemake intermediate directory. Contains `.rds` binary files that pass data between generation steps, plus the `kegg_link_cache/` subdirectory with TSV dumps of KEGG link tables. These files are regenerated by the pipeline and should not be manually edited. Not committed to git (or gitignored).

### `biorempp_snakemake_version/results/`

All final and near-final outputs. Snakemake creates subdirectories automatically. The primary deliverable is `results/database/biorempp_database_v1.1.0.csv`. The terminal DAG target is `results/reports/workflow_summary.json`.

### `biorempp_snakemake_version/env/`

Container definition. `Dockerfile` is based on `rocker/tidyverse:4.4` and pins exact package versions. `r-packages.txt` and `python-requirements.txt` serve as human-readable manifests; the Dockerfile `RUN` block installs from those pinned versions. Both files must be updated in sync when upgrading dependencies.

### `biorempp_validation/`

Standalone Python package (`biorempp-validation`) for post-pipeline Great Expectations validation. Installed as an editable package (`pip install -e .`). Entry point: `biorempp-validate --config biorempp_validation/config/validation.yaml`. This is independent of the Snakemake pipeline and runs separately against the finished outputs.

### `input_data/`

Six static curated source files. These are the only non-generated inputs to the pipeline. Any new input file must be (a) added to `REQUIRED_INPUT_FILES` in `biorempp_snakemake_version/workflow/lib/io_contracts.R`, (b) loaded in `biorempp_snakemake_version/workflow/scripts/generation/01_load_local_data.R`, and (c) declared in `00_check_inputs.R` validation logic.

### `output_data/`

Static release artifacts for database v1.0.0 (legacy). Not regenerated by the current pipeline.

### `docs/`

MkDocs Markdown source. Built by `scripts/build-docs.sh` into `site/`. Sections map to user-facing documentation areas (database, validation, reference, technical, etc.).

---

## Entry Points

**Run the full pipeline (Linux/macOS):**
`biorempp_snakemake_version/scripts/run_snakemake.sh [CORES]`
Launches Docker Compose, which runs Snakemake with the default config. Optional arg sets core count (default: 2).

**Run the full pipeline (Windows):**
`biorempp_snakemake_version/scripts/run_snakemake.bat`

**Snakemake directly (inside container or with local install):**
```bash
cd biorempp_snakemake_version
snakemake --snakefile Snakefile --configfile config/config.yaml --cores 2
```

**Run standalone GX validation:**
```bash
cd BioRemPP_DB_1.0.0
pip install -e biorempp_validation/
biorempp-validate --config biorempp_validation/config/validation.yaml
```

**Build documentation:**
```bash
bash scripts/build-docs.sh
```

---

## Naming Conventions

**Rule files:** `NN_stage_name.smk` (two-digit prefix + snake_case stage name)

**Scripts:** `NN_short_description.R` or `NN_short_description.py` (matching rule file prefix within each stage)

**Intermediate files in `work/`:** `{stage_name}.rds` (e.g., `merged_compounds.rds`, `enriched_compounds.rds`)

**Result JSON files in `results/analysis/`:** `{entity}_statistics.json` (e.g., `compound_statistics.json`)

**Shared lib files:** `snake_case.R` (no numeric prefix)

---

## Where to Add New Code

**New generation step (e.g., add a new data enrichment):**
- Create `biorempp_snakemake_version/workflow/scripts/generation/08_new_step.R`
- Add a rule to `biorempp_snakemake_version/workflow/rules/10_generation.smk`
- Output to `work/new_step_output.rds`
- The next step in the chain should take this as `input:`

**New analysis statistic:**
- Create `biorempp_snakemake_version/workflow/scripts/analysis/10_new_stat.R`
- Add a rule to `biorempp_snakemake_version/workflow/rules/20_analysis.smk`
- Add output path to `ANALYSIS_FILES` list in `biorempp_snakemake_version/Snakefile`
- Add the new JSON as an input to `complete_analysis` rule if it should appear in the merged output

**New validation check:**
- Create `biorempp_snakemake_version/workflow/scripts/validation/03_new_check.py`
- Import shared utilities from `kegg_api_client.py` and `common_normalization.py`
- Add a rule to `biorempp_snakemake_version/workflow/rules/30_validation.smk`
- Add output to `rule all:` in `Snakefile` if it should be a terminal target

**New input file:**
1. Place file in `input_data/`
2. Add filename to `REQUIRED_INPUT_FILES` in `biorempp_snakemake_version/workflow/lib/io_contracts.R`
3. Add a loader function in `biorempp_snakemake_version/workflow/scripts/generation/01_load_local_data.R`
4. Add the loaded data to the `local_data` list returned by that script

**New shared R utility:**
- Add to `biorempp_snakemake_version/workflow/lib/utils.R` (generic utilities) or `io_contracts.R` (schema/contract constants only)

**New database column:**
- Add to `EXPECTED_DATABASE_COLUMNS` in `biorempp_snakemake_version/workflow/lib/io_contracts.R`
- Update `07_extract_enzymes_export.R` to populate the column before the final `dplyr::select(all_of(EXPECTED_DATABASE_COLUMNS))`
- Update GX expectation suites in `biorempp_validation/great_expectations/`

---

## Special Directories

| Directory | Generated | Purpose |
|-----------|-----------|---------|
| `biorempp_snakemake_version/work/` | Yes (pipeline) | Snakemake intermediate RDS/JSON files; safe to delete to force full re-run |
| `biorempp_snakemake_version/results/` | Yes (pipeline) | Final and near-final outputs; primary deliverable lives here |
| `biorempp_snakemake_version/logs/` | Yes (pipeline) | Per-rule stderr/stdout captured by Snakemake |
| `biorempp_snakemake_version/work/kegg_link_cache/` | Yes (pipeline) | Cached KEGG API link tables as TSV; delete to force re-fetch from API |
| `site/` | Yes (MkDocs) | Compiled documentation HTML; not committed |
| `venv/` | Yes (manual) | Python virtual environment; not committed |
| `biorempp_validation/biorempp_validation.egg-info/` | Yes (pip) | Package metadata; not committed |

---

## Configuration Reference

All pipeline parameters are in `biorempp_snakemake_version/config/config.yaml`. Key fields:

| Field | Default | Used by |
|-------|---------|---------|
| `version` | `"1.1.0"` | Output filenames, metadata, report |
| `paths.input_dir` | `"../input_data"` | All generation rules |
| `paths.results_dir` | `"results"` | All output rules |
| `paths.work_dir` | `"work"` | Intermediate file rules |
| `outputs.database_csv` | `"biorempp_database_v1.1.0.csv"` | export + analysis rules |
| `outputs.database_csv_delimiter` | `";"` | All CSV read/write operations |
| `kegg.base_url` | `"https://rest.kegg.jp"` | `fetch_kegg_data`, `fetch_kegg_info`, validation |
| `kegg.endpoints.*` | (5 link endpoints + info) | `fetch_kegg_data`, validation cache rule |
| `analysis.top_n_compounds` | `20` | `compound_statistics` rule |
| `analysis.top_n_ko` | `20` | `ko_statistics` rule |
| `analysis.top_n_enzymes` | `30` | `enzyme_statistics` rule |
| `validation.max_invalid_line_ratio` | `0.01` | Both validation rules |

---

## Confidence

- HIGH: full directory tree — directly observed via filesystem listing
- HIGH: file purposes — confirmed by reading each file
- HIGH: where-to-add-new-code guidance — derived from patterns in existing rules and scripts
- MEDIUM: `biorempp_snakemake_version/input_data/` status (symlink vs. copy of root `input_data/`) — `config.yaml` sets `input_dir: "../input_data"`, suggesting the pipeline reads from root; the subdirectory may be a stale copy
