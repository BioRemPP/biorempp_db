# ARCHITECTURE — BioRemPP DB 1.0.0

> Last mapped: 2026-05-31

## Summary

BioRemPP DB is a bioinformatics database-generation pipeline that integrates local curated datasets (Excel/text files listing environmental-agency compounds, KO lists, compound classes, and enzyme terms) with live KEGG REST API data to produce a relational database of bioremediation-relevant compound–KO–EC–reaction–gene relationships. The pipeline is orchestrated by Snakemake 8 and implemented in R (tidyverse) for data transformation and Python for validation and reporting. A secondary standalone Python package (`biorempp_validation`) runs Great Expectations suites over the finished outputs. A legacy monolithic R script (`generate_database.R`) pre-dates the pipeline and is kept for reference.

---

## System Overview

```text
┌─────────────────────────────────────────────────────────────────┐
│                       ENTRY POINTS                              │
│  scripts/run_snakemake.sh  (Docker/Compose launcher)            │
│  scripts/run_snakemake.bat (Windows launcher)                   │
│  biorempp-validate CLI     (standalone GX validation)           │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│              SNAKEMAKE ORCHESTRATOR                             │
│  biorempp_snakemake_version/Snakefile                           │
│  biorempp_snakemake_version/config/config.yaml                  │
└──┬──────────────┬──────────────┬───────────────┬───────────────┘
   │              │              │               │
   ▼              ▼              ▼               ▼
┌──────┐   ┌──────────┐  ┌──────────┐  ┌──────────────┐
│ 00   │   │ 10       │  │ 20       │  │ 30           │
│ PRE- │   │ GENERA-  │  │ ANALYSIS │  │ VALIDATION   │
│FLIGHT│   │ TION     │  │          │  │              │
│      │   │ (R)      │  │ (R)      │  │ (Python)     │
│rules/│   │rules/    │  │rules/    │  │rules/        │
│00_   │   │10_       │  │20_       │  │30_           │
│prefli│   │genera-   │  │analysis  │  │validation    │
│ght   │   │tion.smk  │  │.smk      │  │.smk          │
│.smk  │   │          │  │          │  │              │
└──────┘   └──────────┘  └──────────┘  └──────────────┘
                                              │
                                              ▼
                                    ┌──────────────────┐
                                    │ 90 REPORTING     │
                                    │ (Python)         │
                                    │ rules/90_        │
                                    │ reporting.smk    │
                                    └──────────────────┘
                                              │
                ┌─────────────────────────────┼────────────────────────┐
                ▼                             ▼                        ▼
    ┌──────────────────┐         ┌───────────────────┐    ┌───────────────────┐
    │  results/database│         │ results/analysis/ │    │results/metadata/  │
    │  *.csv  *.xlsx   │         │ *.json (9 files)  │    │ kegg_release.json │
    │                  │         │                   │    │ *_report.json     │
    └──────────────────┘         └───────────────────┘    └───────────────────┘
```

---

## Pipeline Stages

### Stage 00 — Preflight (`workflow/rules/00_preflight.smk`)

| Rule | Script | Input | Output |
|------|--------|-------|--------|
| `preflight_check_inputs` | `generation/00_check_inputs.R` | `input_data/` (6 local files) | `work/preflight_ok.json` |

Validates that all six required input files exist before any downstream work starts. Acts as a guard: every generation rule depends on `preflight_ok.json`.

### Stage 10 — Generation (`workflow/rules/10_generation.smk`)

Eight R scripts executed sequentially via RDS intermediate files under `work/`:

| Rule | Script | Key Input | Output |
|------|--------|-----------|--------|
| `fetch_kegg_info` | `generation/02_fetch_kegg_info.R` | KEGG REST `/info/kegg` | `results/metadata/kegg_release.json` |
| `load_local_data` | `generation/01_load_local_data.R` | 6 local `.xlsx`/`.txt` files | `work/local_data.rds` |
| `fetch_kegg_data` | `generation/03_fetch_kegg_data.R` | KEGG REST link/list endpoints | `work/kegg_data.rds` |
| `merge_relationships` | `generation/04_merge_relationships.R` | `local_data.rds`, `kegg_data.rds` | `work/merged_compounds.rds` |
| `add_classifications` | `generation/05_add_classifications.R` | `merged_compounds.rds`, `local_data.rds` | `work/classified_compounds.rds` |
| `enrich_gene_info` | `generation/06_enrich_gene_info.R` | `classified_compounds.rds`, `local_data.rds` | `work/enriched_compounds.rds` |
| `extract_enzymes_export` | `generation/07_extract_enzymes_export.R` | `enriched_compounds.rds`, `local_data.rds`, `kegg_data.rds`, `kegg_release.json` | `results/database/biorempp_database_v1.1.0.{csv,xlsx}` |

The core complexity lives in `04_merge_relationships.R`, which builds a compound–KO universe using a tiered join strategy: (1) "dense" KO triples (ko→ec→reaction fully consistent), (2) fallback dense (ko has separate ec and reaction links), (3) compound-bridge dense (cpd confirms the ec and reaction), (4) partial ec-only, (5) partial reaction-only, (6) unsupported (ec=NA, reaction=NA).

### Stage 20 — Analysis (`workflow/rules/20_analysis.smk`)

Nine R scripts that all read the final database CSV in parallel (fan-out), then merge:

| Rule | Script | Output |
|------|--------|--------|
| `basic_statistics` | `analysis/01_basic_statistics.R` | `analysis/basic_statistics.json` |
| `compound_statistics` | `analysis/02_compound_statistics.R` | `analysis/compound_statistics.json` |
| `ko_statistics` | `analysis/03_ko_statistics.R` | `analysis/ko_statistics.json` |
| `enzyme_statistics` | `analysis/04_enzyme_statistics.R` | `analysis/enzyme_statistics.json` |
| `gene_statistics` | `analysis/05_gene_statistics.R` | `analysis/gene_statistics.json` |
| `crosstab_statistics` | `analysis/06_crosstab_statistics.R` | `analysis/crosstab_statistics.json` |
| `database_metadata` | `analysis/07_metadata.R` | `analysis/database_metadata.json` |
| `executive_summary` | `analysis/08_executive_summary.R` | `analysis/executive_summary.json` |
| `complete_analysis` | `analysis/09_merge_complete_analysis.R` | `analysis/complete_analysis.json` |

### Stage 30 — Validation (`workflow/rules/30_validation.smk`)

Python-based cross-validation against live KEGG link endpoints:

| Rule | Script | Output |
|------|--------|--------|
| `fetch_kegg_link_cache` | `validation/cache_kegg_links.py` | `work/kegg_link_cache/*.tsv` (5 files) |
| `validate_keys_consistency` | `validation/01_validate_keys_consistency_api.py` | `results/metadata/keys_consistency_report.json` |
| `validate_links_groundtruth_policy` | `validation/02_validate_links_groundtruth_policy_api.py` | `results/metadata/links_groundtruth_policy_report.json` |

### Stage 90 — Reporting (`workflow/rules/90_reporting.smk`)

| Rule | Script | Output |
|------|--------|--------|
| `build_run_report` | `reporting/build_run_report.py` | `results/reports/workflow_summary.json` |

Aggregates all outputs into a single provenance/summary JSON with SHA-256 checksums, file sizes, and run metadata.

---

## Component Responsibilities

| Component | Responsibility | Location |
|-----------|----------------|----------|
| `Snakefile` | DAG definition, terminal targets, rule includes | `biorempp_snakemake_version/Snakefile` |
| `config.yaml` | All runtime parameters (paths, KEGG URLs, output filenames, top-N counts, validation thresholds) | `biorempp_snakemake_version/config/config.yaml` |
| `workflow/lib/utils.R` | Shared R utilities: CLI parsing, logging, NA normalization, JSON I/O, CSV I/O | `biorempp_snakemake_version/workflow/lib/utils.R` |
| `workflow/lib/io_contracts.R` | Schema contracts: required input filenames, expected DB columns, KEGG endpoint definitions, KEGG ID patterns | `biorempp_snakemake_version/workflow/lib/io_contracts.R` |
| `workflow/lib/na_markers.txt` | Canonical NA string list shared across R and Python normalization | `biorempp_snakemake_version/workflow/lib/na_markers.txt` |
| Generation scripts (R) | Transform raw inputs into enriched compound–gene rows | `biorempp_snakemake_version/workflow/scripts/generation/` |
| Analysis scripts (R) | Compute per-entity statistics from the finished CSV | `biorempp_snakemake_version/workflow/scripts/analysis/` |
| Validation scripts (Python) | Cross-check database rows against KEGG API ground truth | `biorempp_snakemake_version/workflow/scripts/validation/` |
| `kegg_api_client.py` | KEGG HTTP client with retry/backoff, token normalization, cache I/O | `biorempp_snakemake_version/workflow/scripts/validation/kegg_api_client.py` |
| `common_normalization.py` | Python-side NA detection and KEGG ID normalization (mirrors `utils.R`) | `biorempp_snakemake_version/workflow/scripts/validation/common_normalization.py` |
| `biorempp_validation/` | Standalone Great Expectations validation package | `biorempp_validation/` |
| `generate_database.R` | Legacy monolithic generator (v1.0.0, pre-pipeline) | `generate_database.R` |

---

## Data Flow

### Primary Build Path

```
input_data/*.xlsx, *.txt
        │
        ▼
01_load_local_data.R  ──►  work/local_data.rds
                              (kegg_compounds, agency_compounds,
                               curated_compounds, compound_classes,
                               ko_list, enzyme_terms)

KEGG REST API (link/list endpoints)
        │
        ▼
03_fetch_kegg_data.R  ──►  work/kegg_data.rds
                              (ko_ec_links, ko_reaction_links,
                               compound_ec_links, compound_reaction_links,
                               ec_reaction_links, reaction_list,
                               compound_list)

local_data.rds + kegg_data.rds
        │
        ▼
04_merge_relationships.R  ──►  work/merged_compounds.rds
                                 (cpd, ko, ec, reaction, referenceAG,
                                  compoundname — tiered join universe)

merged_compounds.rds + local_data.rds (compound_classes)
        │
        ▼
05_add_classifications.R  ──►  work/classified_compounds.rds
                                 (adds compoundclass column)

classified_compounds.rds + local_data.rds (ko_list)
        │
        ▼
06_enrich_gene_info.R  ──►  work/enriched_compounds.rds
                               (adds genesymbol, genename)

enriched_compounds.rds + local_data.rds (enzyme_terms) + kegg_data.rds (reaction_list)
        │
        ▼
07_extract_enzymes_export.R  ──►  results/database/biorempp_database_v1.1.0.csv
                                   results/database/biorempp_database_v1.1.0.xlsx
                                   (11-column final schema:
                                    cpd, compoundclass, ko, ec, reaction,
                                    reaction_description, referenceAG,
                                    compoundname, genesymbol, genename,
                                    enzyme_activity)
```

### Analysis Fan-Out

```
results/database/biorempp_database_v1.1.0.csv
        │
        ├──► basic_statistics.json
        ├──► compound_statistics.json
        ├──► ko_statistics.json
        ├──► enzyme_statistics.json
        ├──► gene_statistics.json
        ├──► crosstab_statistics.json
        ├──► database_metadata.json  (also reads kegg_release.json, kegg_data.rds)
        │
        ▼ (fan-in)
executive_summary.json  ──►  complete_analysis.json
```

### Validation Path

```
KEGG REST API (5 link endpoints)
        │
        ▼
cache_kegg_links.py  ──►  work/kegg_link_cache/{ko_ec,ko_reaction,cpd_ec,cpd_reaction,ec_reaction}.tsv

results/database/*.csv + kegg_link_cache/*.tsv
        │
        ├──► keys_consistency_report.json
        └──► links_groundtruth_policy_report.json
```

---

## Key Design Decisions

**Intermediate files as RDS.** Each generation step serializes its output as an R `.rds` binary. This gives Snakemake deterministic checkpointing and avoids repeated CSV parsing.

**Tiered join strategy in `04_merge_relationships.R`.** The core rule uses a priority-ordered cascade: dense → fallback-dense → compound-bridge-dense → partial-ec → partial-reaction → unsupported. This preserves maximum coverage while maintaining internal consistency of (ko, ec, reaction) triples. The strategy is fully documented in the function names of `04_merge_relationships.R`.

**Dual-language pipeline.** R (tidyverse) handles data transformation where dplyr's relational join semantics are expressive. Python handles HTTP/caching (KEGG link cache) and JSON aggregation (reporting), where standard library tooling is more natural.

**API retry/backoff shared across languages.** Both `03_fetch_kegg_data.R` and `kegg_api_client.py` implement exponential backoff with jitter, controlled by the same set of environment variables (`BIOREMPP_API_MAX_RETRIES`, `BIOREMPP_API_TIMEOUT_SECONDS`, `BIOREMPP_API_BACKOFF_BASE_SECONDS`, `BIOREMPP_API_BACKOFF_MAX_SECONDS`, `BIOREMPP_API_BACKOFF_JITTER_RATIO`).

**NA normalization contract.** `workflow/lib/na_markers.txt` defines a canonical list used by both `utils.R` (`load_na_markers()`) and `common_normalization.py` in Python. This ensures consistent handling of `""`, `"NA"`, `"NULL"`, `"NONE"`, `"N/A"`, `"<NA>"`, `"NAN"` across languages.

**Column schema as code contract.** `EXPECTED_DATABASE_COLUMNS` in `io_contracts.R` defines the 11-column final schema and is referenced in the export step's `dplyr::select(all_of(...))`, preventing silent column drift.

**Docker-first execution.** `env/Dockerfile` pins exact versions for all R packages and Python packages. `scripts/run_snakemake.sh` launches via `docker compose`, mounting the project root at `/workspace`. This makes the pipeline fully reproducible across platforms.

---

## External Integrations

**KEGG REST API (`https://rest.kegg.jp`):**
- `link/ko/ec`, `link/ko/reaction` — KO-to-biochemical links
- `link/compound/ec`, `link/cpd/reaction` — Compound-to-biochemical links
- `link/ec/reaction` — EC-to-reaction links
- `list/reaction` — Reaction descriptions
- `list/cpd/` — Compound names
- `info/kegg` — Release metadata

All endpoints are configured in `config/config.yaml` under `kegg.endpoints` and also declared in `KEGG_ENDPOINTS` in `io_contracts.R`.

---

## Error Handling Strategy

- **Preflight guard:** `00_check_inputs.R` halts with `stop()` if any required input file is absent, preventing partial runs.
- **R scripts:** Use `stop(call. = FALSE)` for all fatal errors; Snakemake captures stderr to per-rule log files under `logs/`.
- **Python scripts:** Use `sys.exit(1)` pattern (via exceptions propagating to `argparse`); also log to Snakemake-managed log files.
- **HTTP retries:** Exponential backoff with configurable jitter in both `03_fetch_kegg_data.R` and `kegg_api_client.py`. Non-retryable HTTP errors (e.g., 404) raise immediately.
- **Validation threshold:** `config.validation.max_invalid_line_ratio` (default `0.01`) controls how many inconsistent rows are tolerated before a validation rule fails.

---

## Confidence

- HIGH: pipeline stage structure, all rule inputs/outputs, script responsibilities — directly read from Snakefile, all `.smk` files, and all script files
- HIGH: data flow and intermediate artifacts — confirmed by presence of `.rds` files in `work/` and outputs in `results/`
- HIGH: NA normalization contract, column schema contract — directly read from `io_contracts.R` and `utils.R`
- MEDIUM: retry/backoff environment variable names — read from source, not tested live
- LOW: `generate_database.R` relationship to Snakemake pipeline — header comments indicate it is the legacy v1.0.0 generator, not integrated into the Snakemake DAG
