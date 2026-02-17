# BioRemPP Snakemake Version

Public, modular, and reproducible BioRemPP pipeline implementation for database generation and statistical analysis, orchestrated with Snakemake and executed in a containerized environment.

## 1) Purpose

This directory provides an implementation of the `v1.0.0` database workflow, including:

- consolidated database generation (`CSV` and `XLSX`)
- modular analysis outputs in `JSON`
- mandatory KEGG release tracking via `https://rest.kegg.jp/info/kegg`
- final run summary with artifact checksums (`SHA256`)
- consistent input resolution from the repository root `../input_data`

## 2) Architecture principles

- **Declarative orchestration:** `Snakefile` + `.smk` rules define dependencies and execution order.
- **Functional modularity:** small R scripts, each with a single responsibility.
- **Public reproducibility:** full runtime environment versioned under `env/`.
- **Traceability:** KEGG release metadata and output hashes are generated every run.
- **Contract compatibility:** final output names remain `biorempp_database_v1.0.0.*`.

## 3) Pipeline architecture (DAG)

High-level flow:

1. `preflight_check_inputs`
2. `fetch_kegg_info`
3. `load_local_data`
4. `fetch_kegg_data`
5. `merge_relationships`
6. `add_classifications`
7. `enrich_gene_info`
8. `extract_enzymes_export`
9. `basic_statistics`, `compound_statistics`, `ko_statistics`, `enzyme_statistics`, `gene_statistics`, `crosstab_statistics`, `database_metadata`
10. `executive_summary`
11. `complete_analysis`
12. `build_run_report`
13. `all`

Layered design:

- **Ingestion:** input validation, KEGG release retrieval, local/API loading.
- **Transformation:** merging, classification, KO sanitization, gene enrichment, enzyme activity extraction.
- **Analysis:** independent statistics modules and final merged analysis report.
- **Provenance:** KEGG release metadata + run summary with checksums.

## 4) Directory tree (ASCII)

```text
biorempp_snakemake_version/
|-- Snakefile
|-- README.md
|-- .gitignore
|-- config/
|   `-- config.yaml
|-- env/
|   |-- Dockerfile
|   |-- docker-compose.yml
|   |-- python-requirements.txt
|   `-- r-packages.txt
|-- scripts/
|   |-- run_snakemake.sh
|   `-- run_snakemake.bat
|-- workflow/
|   |-- lib/
|   |   |-- io_contracts.R
|   |   `-- utils.R
|   |-- rules/
|   |   |-- 00_preflight.smk
|   |   |-- 10_generation.smk
|   |   |-- 20_analysis.smk
|   |   `-- 90_reporting.smk
|   `-- scripts/
|       |-- generation/
|       |   |-- 00_check_inputs.R
|       |   |-- 01_load_local_data.R
|       |   |-- 02_fetch_kegg_info.R
|       |   |-- 03_fetch_kegg_data.R
|       |   |-- 04_merge_relationships.R
|       |   |-- 05_add_classifications.R
|       |   |-- 06_enrich_gene_info.R
|       |   `-- 07_extract_enzymes_export.R
|       |-- analysis/
|       |   |-- 01_basic_statistics.R
|       |   |-- 02_compound_statistics.R
|       |   |-- 03_ko_statistics.R
|       |   |-- 04_enzyme_statistics.R
|       |   |-- 05_gene_statistics.R
|       |   |-- 06_crosstab_statistics.R
|       |   |-- 07_metadata.R
|       |   |-- 08_executive_summary.R
|       |   `-- 09_merge_complete_analysis.R
|       `-- reporting/
|           `-- build_run_report.py
|-- results/
|   |-- database/
|   |-- analysis/
|   |-- metadata/
|   `-- reports/
|-- work/
|   `-- .gitkeep
`-- logs/
    `-- .gitkeep

repository_root/
`-- input_data/   <- canonical input source used by this pipeline (default)
```

## 5) Required inputs (canonical path)

Place these files in the repository root directory `input_data/` (relative to this folder: `../input_data`):

- `kegglistcompounds.xlsx`
- `compostos_todasagencias.xlsx`
- `missing_compounds_founds_curated.xlsx`
- `confirm_class_CURATED.xlsx`
- `kegglistko.txt`
- `enzymes_unique.txt`

## 6) How to run

### 6.1 Recommended execution (Docker)

From `biorempp_snakemake_version/`:

```bash
docker compose -f env/docker-compose.yml run --rm snakemake
```

Helper scripts:

```bash
./scripts/run_snakemake.sh 4
```

```bat
scripts\run_snakemake.bat 4
```

### 6.2 DAG dry-run validation

```bash
docker compose -f env/docker-compose.yml run --rm snakemake \
  snakemake -n --snakefile Snakefile --configfile config/config.yaml --cores 1
```

### 6.3 Local execution (without container)

Supported if Python/R dependencies are manually installed:

```bash
snakemake --snakefile Snakefile --configfile config/config.yaml --cores 4
```

By default, this command reads inputs from `../input_data` (repository root).

## 7) Public output contract

### Database outputs

- `results/database/biorempp_database_v1.0.0.csv`
- `results/database/biorempp_database_v1.0.0.xlsx`

### Analysis outputs

- `results/analysis/database_metadata.json`
- `results/analysis/basic_statistics.json`
- `results/analysis/compound_statistics.json`
- `results/analysis/ko_statistics.json`
- `results/analysis/enzyme_statistics.json`
- `results/analysis/gene_statistics.json`
- `results/analysis/crosstab_statistics.json`
- `results/analysis/executive_summary.json`
- `results/analysis/complete_analysis.json`

### Provenance outputs

- `results/metadata/kegg_release.json`
- `results/reports/workflow_summary.json`

## 8) Reproducibility and versioning

This implementation is prepared for public release. Critical reproducibility assets are versioned:

- **Runtime environment:** `env/Dockerfile`, `env/docker-compose.yml`
- **Pinned Python dependencies:** `env/python-requirements.txt`
- **R package manifest:** `env/r-packages.txt`
- **Pipeline logic:** `Snakefile`, rules, scripts in `workflow/`
- **Database/analysis outputs:** `results/**` (when present)

Important note:

- KEGG is an online source and may evolve over time. `kegg_release.json` plus hashes in `workflow_summary.json` provide the exact data context used for each run.

## 9) Configuration (`config/config.yaml`)

Main keys:

- `version`
- `paths.input_dir` (default: `../input_data`), `paths.results_dir`, `paths.work_dir`, `paths.logs_dir`
- `outputs.database_csv`, `outputs.database_xlsx`
- `kegg.base_url`, `kegg.endpoints`, `kegg.info_endpoint`
- `analysis.top_n_compounds`, `analysis.top_n_ko`, `analysis.top_n_enzymes`

## 10) Quick troubleshooting

- **Missing input error:** run preflight and verify files in repository-root `input_data/` (`../input_data` from this folder).
- **KEGG API failure:** check connectivity and network restrictions.
- **Docker volume permission issue:** verify writable mounts for `results/`, `work/`, and `logs/`.
- **Local environment inconsistency:** prefer container execution.

## 11) Useful commands

Run full pipeline:

```bash
docker compose -f env/docker-compose.yml run --rm snakemake \
  snakemake --snakefile Snakefile --configfile config/config.yaml --cores 4 --printshellcmds
```

Run only one target:

```bash
docker compose -f env/docker-compose.yml run --rm snakemake \
  snakemake --snakefile Snakefile --configfile config/config.yaml --cores 2 build_run_report
```

## 12) Release status

- Snakemake modular pipeline: **active**
- `v1.0.0` output contract: **preserved**
- Public reproducibility environment: **fully versioned**
