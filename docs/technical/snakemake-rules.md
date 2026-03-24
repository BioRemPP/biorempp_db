# Snakemake Rules Reference

This document provides a complete reference for every Snakemake rule in the BioRemPP pipeline, organized by rule module.

---

## Rule Modules Overview

The pipeline is composed of 4 rule files (`*.smk`) loaded by the main `Snakefile`:

| Module | File | Rules | Purpose |
|--------|------|-------|---------|
| Preflight | `workflow/rules/00_preflight.smk` | 1 | Input validation |
| Generation | `workflow/rules/10_generation.smk` | 7 | Data ETL pipeline |
| Analysis | `workflow/rules/20_analysis.smk` | 9 | Statistical analysis |
| Reporting | `workflow/rules/90_reporting.smk` | 1 | Provenance tracking |

**Total rules:** 18

The `Snakefile` defines a `rule all` target that requests all final outputs, and declares `localrules: all` so the target rule is not submitted to cluster schedulers.

---

## Module: Preflight (`00_preflight.smk`)

### Rule: `preflight_check_inputs`

**Purpose:** Validates that all 6 required input files exist in the configured input directory before any processing begins.

| Property | Value |
|----------|-------|
| **Script** | `workflow/scripts/generation/00_check_inputs.R` |
| **Input** | *(none — triggered by dependency)* |
| **Output** | `work/preflight_ok.json` |
| **Parameters** | `--input-dir {input_dir}`, `--output {output}`, `--config {config_file}` |
| **Log** | `logs/preflight_check_inputs.log` |

**Behavior:** Checks existence of all files listed in `REQUIRED_INPUT_FILES` (from `io_contracts.R`). Writes a JSON report with file paths and validation status. Fails if any file is missing.

---

## Module: Generation (`10_generation.smk`)

### Rule: `fetch_kegg_info`

**Purpose:** Fetches the current KEGG database release version from the API for provenance tracking.

| Property | Value |
|----------|-------|
| **Script** | `workflow/scripts/generation/02_fetch_kegg_info.R` |
| **Input** | *(none)* |
| **Output** | `results/metadata/kegg_release.json` |
| **Parameters** | `--base-url {base_url}`, `--endpoint {info_endpoint}`, `--output {output}`, `--config {config_file}` |
| **Log** | `logs/fetch_kegg_info.log` |

**Behavior:** Hits `rest.kegg.jp/info/kegg`, parses the release version string, and saves a JSON file containing the release version, timestamp, and raw API response.

!!! note
    This rule runs independently of the generation chain and can execute in parallel with other rules until `extract_enzymes_export` needs it.

---

### Rule: `load_local_data`

**Purpose:** Reads all 6 local input files into a single R list bundle.

| Property | Value |
|----------|-------|
| **Script** | `workflow/scripts/generation/01_load_local_data.R` |
| **Input** | `work/preflight_ok.json` |
| **Output** | `work/local_data.rds` |
| **Parameters** | `--input-dir {input_dir}`, `--output {output}`, `--config {config_file}` |
| **Log** | `logs/load_local_data.log` |

**Behavior:** Reads 4 Excel files + 2 text files, bundles them into a named R list, and saves as `.rds`. The preflight sentinel ensures inputs have been validated first.

---

### Rule: `fetch_kegg_data`

**Purpose:** Fetches 5 KEGG API endpoints (link and list queries) for compound-gene relationships.

| Property | Value |
|----------|-------|
| **Script** | `workflow/scripts/generation/03_fetch_kegg_data.R` |
| **Input** | `work/preflight_ok.json` |
| **Output** | `work/kegg_data.rds` |
| **Parameters** | `--base-url {base_url}`, `--output {output}`, `--config {config_file}` |
| **Log** | `logs/fetch_kegg_data.log` |

**Behavior:** Fetches 5 endpoints with retry logic (3 attempts with linear backoff — `Sys.sleep(attempt)`: 1 s, 2 s, 3 s). Trims compound name synonyms after `;`. Bundles all API responses into a named R list saved as `.rds`.

**KEGG endpoints queried:**

| Endpoint | Description |
|----------|-------------|
| `link/ko/ec` | KO ↔ EC number links |
| `link/ko/reaction` | KO ↔ Reaction links |
| `link/compound/ec` | Compound ↔ EC links |
| `link/cpd/reaction` | Compound ↔ Reaction links |
| `list/cpd/` | Compound list with names |

!!! info "Parallelism"
    `load_local_data` and `fetch_kegg_data` run **in parallel** after preflight, as they have no mutual dependency.

---

### Rule: `merge_relationships`

**Purpose:** Merges KO-compound relationships via both EC numbers and reaction links, integrates agency and curated compounds, and adds KEGG compound names.

| Property | Value |
|----------|-------|
| **Script** | `workflow/scripts/generation/04_merge_relationships.R` |
| **Input** | `work/local_data.rds`, `work/kegg_data.rds` |
| **Output** | `work/merged_compounds.rds` |
| **Parameters** | `--local-data {local_data}`, `--kegg-data {kegg_data}`, `--output {output}`, `--config {config_file}` |
| **Log** | `logs/merge_relationships.log` |

**Behavior:** Builds KO↔compound links via two independent pathways (EC-based and reaction-based), creates the union, integrates environmental agency compound lists and manually curated pairs, and adds KEGG compound names via left join.

---

### Rule: `add_classifications`

**Purpose:** Joins compound class annotations and normalizes data.

| Property | Value |
|----------|-------|
| **Script** | `workflow/scripts/generation/05_add_classifications.R` |
| **Input** | `work/merged_compounds.rds`, `work/local_data.rds` |
| **Output** | `work/classified_compounds.rds` |
| **Parameters** | `--merged-data {merged}`, `--local-data {local}`, `--output {output}`, `--config {config_file}` |
| **Log** | `logs/add_classifications.log` |

**Behavior:**

- Splits comma-separated compound class entries into individual rows
- Normalizes spelling errors (`Organometalic` → `Organometallic`)
- Removes annotation artifacts (`(repeated)` tags)
- Sanitizes KO identifiers to canonical `K\d{5}` format via regex extraction

---

### Rule: `enrich_gene_info`

**Purpose:** Enriches compound data with gene symbols and gene names from the KEGG KO reference.

| Property | Value |
|----------|-------|
| **Script** | `workflow/scripts/generation/06_enrich_gene_info.R` |
| **Input** | `work/classified_compounds.rds`, `work/local_data.rds` |
| **Output** | `work/enriched_compounds.rds` |
| **Parameters** | `--classified-data {classified}`, `--local-data {local}`, `--output {output}`, `--config {config_file}` |
| **Log** | `logs/enrich_gene_info.log` |

**Behavior:** Left-joins gene symbol and gene name from the 27,990-row KO reference (`kegglistko.txt`). Rows without matching gene information are **filtered out** (excluded from the database).

---

### Rule: `extract_enzymes_export`

**Purpose:** Extracts enzyme activity terms, selects the final 8-column schema, and exports the database as CSV and Excel.

| Property | Value |
|----------|-------|
| **Script** | `workflow/scripts/generation/07_extract_enzymes_export.R` |
| **Input** | `work/enriched_compounds.rds`, `work/local_data.rds`, `results/metadata/kegg_release.json` |
| **Output** | `results/database/*.csv`, `results/database/*.xlsx` |
| **Parameters** | `--enriched-data {enriched}`, `--local-data {local}`, `--output-csv {csv}`, `--output-xlsx {xlsx}`, `--config {config_file}` |
| **Log** | `logs/extract_enzymes_export.log` |

**Behavior:**

1. Builds a regex pattern from 218 enzyme activity terms (word-boundary matching)
2. Extracts `enzyme_activity` from `genename` via regex
3. Strips EC numbers from `genename`
4. Trims `genesymbol` to first alias (before comma)
5. Selects the final 8 columns defined in `EXPECTED_DATABASE_COLUMNS`
6. Writes CSV and XLSX to `results/database/`

---

## Module: Analysis (`20_analysis.smk`)

Most analysis rules read only the generated CSV database and produce JSON output files. The exception is `database_metadata`, which also reads `kegg_release.json` (see below).

### Rule: `basic_statistics`

| Property | Value |
|----------|-------|
| **Script** | `workflow/scripts/analysis/01_basic_statistics.R` |
| **Input** | `results/database/*.csv` |
| **Output** | `results/analysis/basic_statistics.json` |
| **Parameters** | `--input-csv {input}`, `--output {output}`, `--config {config_file}` |
| **Log** | `logs/analysis_basic_statistics.log` |

**Content:** Row counts, unique counts per column, missing value counts.

---

### Rule: `compound_statistics`

| Property | Value |
|----------|-------|
| **Script** | `workflow/scripts/analysis/02_compound_statistics.R` |
| **Input** | `results/database/*.csv` |
| **Output** | `results/analysis/compound_statistics.json` |
| **Parameters** | `--input-csv {input}`, `--top-n {top_n}`, `--output {output}`, `--config {config_file}` |
| **Log** | `logs/analysis_compound_statistics.log` |

**Content:** Compounds per class/agency, top-N compounds (configurable), distribution summary.

---

### Rule: `ko_statistics`

| Property | Value |
|----------|-------|
| **Script** | `workflow/scripts/analysis/03_ko_statistics.R` |
| **Input** | `results/database/*.csv` |
| **Output** | `results/analysis/ko_statistics.json` |
| **Parameters** | `--input-csv {input}`, `--top-n {top_n}`, `--output {output}`, `--config {config_file}` |
| **Log** | `logs/analysis_ko_statistics.log` |

**Content:** KO frequency distribution, top-N KO entries, compounds-per-KO statistics.

---

### Rule: `enzyme_statistics`

| Property | Value |
|----------|-------|
| **Script** | `workflow/scripts/analysis/04_enzyme_statistics.R` |
| **Input** | `results/database/*.csv` |
| **Output** | `results/analysis/enzyme_statistics.json` |
| **Parameters** | `--input-csv {input}`, `--top-n {top_n}`, `--output {output}`, `--config {config_file}` |
| **Log** | `logs/analysis_enzyme_statistics.log` |

**Content:** Top-N enzyme activities, frequency distributions.

---

### Rule: `gene_statistics`

| Property | Value |
|----------|-------|
| **Script** | `workflow/scripts/analysis/05_gene_statistics.R` |
| **Input** | `results/database/*.csv` |
| **Output** | `results/analysis/gene_statistics.json` |
| **Parameters** | `--input-csv {input}`, `--output {output}`, `--config {config_file}` |
| **Log** | `logs/analysis_gene_statistics.log` |

**Content:** Top-N gene symbols and gene names.

---

### Rule: `crosstab_statistics`

| Property | Value |
|----------|-------|
| **Script** | `workflow/scripts/analysis/06_crosstab_statistics.R` |
| **Input** | `results/database/*.csv` |
| **Output** | `results/analysis/crosstab_statistics.json` |
| **Parameters** | `--input-csv {input}`, `--output {output}`, `--config {config_file}` |
| **Log** | `logs/analysis_crosstab_statistics.log` |

**Content:** Class × agency, enzyme × class, and class-by-KO-diversity crosstabs.

---

### Rule: `database_metadata`

| Property | Value |
|----------|-------|
| **Script** | `workflow/scripts/analysis/07_metadata.R` |
| **Input** | `results/database/*.csv`, `results/metadata/kegg_release.json` |
| **Output** | `results/analysis/database_metadata.json` |
| **Parameters** | `--input-csv {csv}`, `--kegg-info {kegg_info}`, `--version {version}`, `--output {output}`, `--config {config_file}` |
| **Log** | `logs/analysis_database_metadata.log` |

**Content:** Schema documentation, data source provenance, completeness percentages per column.

---

### Rule: `executive_summary`

| Property | Value |
|----------|-------|
| **Script** | `workflow/scripts/analysis/08_executive_summary.R` |
| **Input** | `basic_statistics.json`, `compound_statistics.json`, `ko_statistics.json`, `enzyme_statistics.json` |
| **Output** | `results/analysis/executive_summary.json` |
| **Parameters** | `--basic {basic}`, `--compound {compound}`, `--ko {ko}`, `--enzyme {enzyme}`, `--output {output}`, `--config {config_file}` |
| **Log** | `logs/analysis_executive_summary.log` |

**Content:** High-level highlights (most represented class, top enzyme, KO coverage metrics).

!!! note "Fan-in pattern"
    This rule depends on 4 independent statistics outputs, forming the first fan-in point in the analysis layer.

---

### Rule: `complete_analysis`

| Property | Value |
|----------|-------|
| **Script** | `workflow/scripts/analysis/09_merge_complete_analysis.R` |
| **Input** | All 7 statistics JSONs + `executive_summary.json` |
| **Output** | `results/analysis/complete_analysis.json` |
| **Parameters** | `--metadata {metadata}`, `--basic {basic}`, `--compound {compound}`, `--ko {ko}`, `--enzyme {enzyme}`, `--gene {gene}`, `--crosstab {crosstab}`, `--executive {executive}`, `--output {output}`, `--config {config_file}` |
| **Log** | `logs/analysis_complete_analysis.log` |

**Content:** Merges all analysis outputs into a single consolidated JSON file.

!!! note "Second fan-in"
    This rule depends on all 8 analysis outputs, producing the complete analysis bundle.

---

## Module: Reporting (`90_reporting.smk`)

### Rule: `build_run_report`

**Purpose:** Creates a provenance report with SHA-256 checksums for all final artifacts.

| Property | Value |
|----------|-------|
| **Script** | `workflow/scripts/reporting/build_run_report.py` *(Python)* |
| **Input** | CSV, XLSX, `database_metadata.json`, `complete_analysis.json`, `kegg_release.json` |
| **Output** | `results/reports/workflow_summary.json` |
| **Parameters** | `--database-csv {csv}`, `--database-xlsx {xlsx}`, `--metadata-json {metadata}`, `--complete-json {complete}`, `--kegg-json {kegg}`, `--version {version}`, `--output {output}`, `--config {config_file}` |
| **Log** | `logs/build_run_report.log` |

**Content:** SHA-256 checksums, file sizes, KEGG release info, and execution timestamp for every output artifact.

!!! info
    This is the only Python script in the pipeline, leveraging Python's `hashlib` for checksum computation. All data transformation logic is in R.

---

## Execution Examples

### Dry Run (Validate DAG)

```bash
snakemake -n --snakefile Snakefile --configfile config/config.yaml
```

### Full Execution (4 cores)

```bash
snakemake --snakefile Snakefile --configfile config/config.yaml --cores 4 --printshellcmds
```

### Run Specific Rule

```bash
snakemake --snakefile Snakefile --configfile config/config.yaml --cores 1 --printshellcmds basic_statistics
```

### Force Re-run from a Specific Rule

```bash
snakemake --snakefile Snakefile --configfile config/config.yaml --cores 4 --printshellcmds --forcerun merge_relationships
```
