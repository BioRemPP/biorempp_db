# Architecture

_Last updated: 2026-05-31_

## Summary

BioRemPP DB is a reproducible bioinformatics database pipeline that integrates local curated Excel/text files with live KEGG REST API data to produce a normalized relational CSV/XLSX database of compound–KO–EC–reaction relationships for environmental remediation research. The pipeline is orchestrated by Snakemake (v8+) with R scripts for data generation and analysis, Python scripts for structural validation and reporting, and a separate Python Great Expectations layer for post-generation quality assurance. A 6-stage fallback chain in the merge step assigns a `support_stage` provenance tag to every row, and a column contract (`EXPECTED_DATABASE_COLUMNS`) enforced in `io_contracts.R` ensures the schema never drifts silently.

---

## High-Level Data Flow

```
input_data/ (Excel + TXT)
        │
        ▼
┌───────────────────────────────────────────────────────┐
│           Snakemake Pipeline                          │
│   biorempp_snakemake_version/                         │
│                                                       │
│  [00] preflight_check_inputs                          │
│         │                                             │
│  [01] load_local_data  ──┐                            │
│  [02] fetch_kegg_info    │                            │
│  [03] fetch_kegg_data  ──┤                            │
│         │                │                            │
│  [04] merge_relationships  (6-stage fallback chain)   │
│         │                                             │
│  [05] add_classifications                             │
│         │                                             │
│  [06] enrich_gene_info                                │
│         │                                             │
│  [07] extract_enzymes_export ──► results/database/    │
│         │                         *.csv  *.xlsx       │
│         │                                             │
│  [Analysis 01–09] ──────────────► results/analysis/  │
│                                     *.json            │
│  [Validation 01–02] ────────────► results/metadata/  │
│                                     *.json            │
│  [Reporting] ───────────────────► results/reports/   │
│                                     workflow_summary  │
└───────────────────────────────────────────────────────┘
        │
        ▼
biorempp_validation/  (Great Expectations layer)
        │
        ▼
  validation_summary.json
  critical_checkpoint_result.json
  warning_checkpoint_result.json
```

---

## Snakemake Rule Graph

The `Snakefile` at `biorempp_snakemake_version/Snakefile` reads `config/config.yaml` and includes five rule files:

| Include file | Phase | Rules |
|---|---|---|
| `workflow/rules/00_preflight.smk` | Preflight | `preflight_check_inputs` |
| `workflow/rules/10_generation.smk` | Generation | `fetch_kegg_info`, `load_local_data`, `fetch_kegg_data`, `merge_relationships`, `add_classifications`, `enrich_gene_info`, `extract_enzymes_export` |
| `workflow/rules/20_analysis.smk` | Analysis | `basic_statistics`, `compound_statistics`, `ko_statistics`, `enzyme_statistics`, `gene_statistics`, `crosstab_statistics`, `database_metadata`, `executive_summary`, `complete_analysis` |
| `workflow/rules/30_validation.smk` | Validation | `fetch_kegg_link_cache`, `validate_keys_consistency`, `validate_links_groundtruth_policy` |
| `workflow/rules/90_reporting.smk` | Reporting | `build_run_report` |

Intermediate RDS files are written to `work/` and are not final outputs. Final outputs go to `results/`.

---

## Generation Pipeline: R Scripts 00–07

All scripts live in `biorempp_snakemake_version/workflow/scripts/generation/`. Every script sources `workflow/lib/utils.R` and uses `parse_cli_args()` / `require_cli_args()` for argument parsing. Scripts that produce database rows also source `workflow/lib/io_contracts.R`.

### Script Sequence

| Script | Input | Output | Purpose |
|---|---|---|---|
| `00_check_inputs.R` | `input_data/` dir | `work/preflight_ok.json` | Validates presence of all 6 `REQUIRED_INPUT_FILES` |
| `01_load_local_data.R` | `input_data/*.xlsx`, `*.txt` | `work/local_data.rds` | Reads agency compounds, curated compounds, compound classes, KO list, enzyme terms |
| `02_fetch_kegg_info.R` | KEGG REST API | `results/metadata/kegg_release.json` | Captures KEGG release version stamp |
| `03_fetch_kegg_data.R` | KEGG REST API | `work/kegg_data.rds` | Fetches 7 endpoint bundles: ko_ec, ko_reaction, compound_ec, compound_reaction, ec_reaction, reaction_list, compound_list |
| `04_merge_relationships.R` | `local_data.rds`, `kegg_data.rds` | `work/merged_compounds.rds` | **Core join step** — builds cpd×ko×ec×reaction matrix via 6-stage fallback chain; assigns `support_stage` |
| `05_add_classifications.R` | `merged_compounds.rds`, `local_data.rds` | `work/classified_compounds.rds` | Joins compound class labels; normalizes KO strings |
| `06_enrich_gene_info.R` | `classified_compounds.rds`, `local_data.rds` | `work/enriched_compounds.rds` | Left-joins `genesymbol` and `genename` from local KO list; drops rows without gene info |
| `07_extract_enzymes_export.R` | `enriched_compounds.rds`, `local_data.rds`, `kegg_data.rds` | `results/database/*.csv`, `*.xlsx` | Joins `reaction_description`, extracts `enzyme_activity` via regex, applies `EXPECTED_DATABASE_COLUMNS` column gate, writes final database |

---

## The 6-Stage Fallback Chain

Defined in `biorempp_snakemake_version/workflow/scripts/generation/04_merge_relationships.R`, inside `expand_keys_with_consistent_mapping()`. Every cpd–ko–referenceAG key triple is resolved through the stages in order; a key exits the chain at the first stage that produces rows for it.

### Stage Definitions

```
Stage 1  dense
         ko_complete = ko_ec ⋈ ec_reaction ⋈ ko_reaction
         Rows have BOTH ec AND reaction, all three links confirmed.
         → Highest quality. cpd×ko keys that match ko_complete drop out here.

Stage 2  fallback_dense
         ko_fallback_dense = (ko_ec ∪ ko_reaction) filtered to KOs NOT in ko_complete,
         paired cross-wise (ko_ec × ko_reaction for same ko).
         Rows have BOTH ec AND reaction, but KO lacks a confirmed triple.
         → Used when KEGG has the two links but not the triangulated triple.

Stage 3  compound_bridge
         Compound-level bridging:
           Path A: cpd_ec ⋈ ko_reaction ⋈ cpd_reaction  (same cpd+reaction)
           Path B: cpd_reaction ⋈ ko_ec ⋈ cpd_ec        (same cpd+ec)
         Rows have BOTH ec AND reaction, grounded through the compound.
         → Fallback when KO-level pairing fails but compound links connect ec and reaction.

Stage 4  ec_only
         residual_keys ⋈ ko_ec
         Rows have ec; reaction = NA.

Stage 5  reaction_only
         residual_keys ⋈ ko_reaction
         Rows have reaction; ec = NA.

Stage 6  unsupported
         Keys not resolved by any of stages 1–5.
         Both ec and reaction = NA.
         Triggers a WARNING log if rate > 5% of total keys.
```

The `support_stage` column value for each row is one of:
`dense` | `fallback_dense` | `compound_bridge` | `ec_only` | `reaction_only` | `unsupported`

---

## The `EXPECTED_DATABASE_COLUMNS` Contract

Defined in `biorempp_snakemake_version/workflow/lib/io_contracts.R` (lines 12–25):

```r
EXPECTED_DATABASE_COLUMNS <- c(
  "cpd", "compoundclass", "ko", "ec", "reaction",
  "reaction_description", "referenceAG", "compoundname",
  "genesymbol", "genename", "enzyme_activity", "support_stage"
)
```

This constant is the single source of truth for the database schema. It is consumed at two enforcement points:

1. **`07_extract_enzymes_export.R`** (line 60): `dplyr::select(dplyr::all_of(EXPECTED_DATABASE_COLUMNS))` — hard-selects exactly these 12 columns before writing CSV/XLSX. Any extra or missing column causes an R error at pipeline time.

2. **`run_validation.py`** (`biorempp_validation/src/biorempp_validation/run_validation.py`, lines 66–68): `_apply_config_overrides_to_suite_payloads()` injects `settings.expected_columns` (mirroring the same 12 columns from `validation.yaml`) into the Great Expectations `expect_table_columns_to_match_ordered_list` expectation and the `basic_total_columns` count expectation. This means the validation layer is also schema-aware and will fail the critical gate if the column list changes.

The same 12 columns are also declared independently in `biorempp_validation/config/validation.yaml` under `database_contract.expected_columns`, making the contract explicit and auditable outside of R code.

---

## Database Schema

| Column | Type | Nullable | Description | Example |
|---|---|---|---|---|
| `cpd` | character | No | KEGG compound ID | `C00001` |
| `compoundclass` | character | No | Chemical classification | `Aromatic` |
| `ko` | character | No | KEGG Orthology ID | `K00001` |
| `ec` | character | **Yes** | Enzyme Commission number | `1.1.1.1` |
| `reaction` | character | **Yes** | KEGG reaction ID | `R00623` |
| `reaction_description` | character | **Yes** | KEGG reaction text/equation | `polyphosphate polyphosphohydrolase; ...` |
| `referenceAG` | character | No | Source environmental agency | `EPA` |
| `compoundname` | character | No | KEGG compound name | `Water` |
| `genesymbol` | character | No | Gene symbol | `ADH1` |
| `genename` | character | No | Full gene name | `alcohol dehydrogenase` |
| `enzyme_activity` | character | No | Extracted enzyme activity term | `dehydrogenase` |
| `support_stage` | character | No | Fallback stage that produced this row | `dense` |

Nullable columns (`ec`, `reaction`, `reaction_description`) are explicitly declared in `biorempp_validation/config/validation.yaml` under `database_contract.nullable_columns`.

---

## Analysis Layer: R Scripts 01–09

All scripts in `biorempp_snakemake_version/workflow/scripts/analysis/`. Each reads the final database CSV directly (no RDS dependency) and writes a single JSON artifact to `results/analysis/`.

| Script | Output JSON | Content |
|---|---|---|
| `01_basic_statistics.R` | `basic_statistics.json` | Row count, column count, null rates, stage distribution |
| `02_compound_statistics.R` | `compound_statistics.json` | Top-N compounds by KO count |
| `03_ko_statistics.R` | `ko_statistics.json` | Top-N KOs by compound count |
| `04_enzyme_statistics.R` | `enzyme_statistics.json` | Top-N enzyme activities |
| `05_gene_statistics.R` | `gene_statistics.json` | Unique gene symbols and names |
| `06_crosstab_statistics.R` | `crosstab_statistics.json` | Cross-tabulations (e.g., class × agency) |
| `07_metadata.R` | `database_metadata.json` | Full schema, KEGG coverage, link-match provenance, completeness, policy record |
| `08_executive_summary.R` | `executive_summary.json` | Aggregated summary from 01–04 |
| `09_merge_complete_analysis.R` | `complete_analysis.json` | Merges all individual JSONs into one document |

`07_metadata.R` is the most complex analysis script. It re-normalizes the database CSV, recomputes `ko_complete`, and produces a `link_match` section with coverage counts, row-shape counts (`dense`/`ec_only`/`reaction_only`/`both_na`), pair provenance (`direct_compound_supported`/`ko_supported_only`/`unsupported`), and consistency sentinels (duplicate rows, resolvable-but-sparse pairs).

---

## In-Pipeline Validation Layer: Python Scripts

Located in `biorempp_snakemake_version/workflow/scripts/validation/`. Invoked via Snakemake rules in `30_validation.smk`.

| Script | Purpose | Output |
|---|---|---|
| `cache_kegg_links.py` | Downloads 5 KEGG link tables to `cache/kegg_link_cache/*.tsv` | TSV files |
| `01_validate_keys_consistency_api.py` | Checks cpd/ko/ec/reaction values in the CSV against KEGG patterns and cache | `results/metadata/keys_consistency_report.json` |
| `02_validate_links_groundtruth_policy_api.py` | Verifies link-level ground truth against KEGG API | `results/metadata/links_groundtruth_policy_report.json` |
| `kegg_api_client.py` | Shared KEGG HTTP client | (library) |
| `common_normalization.py` | Shared ID normalization utilities | (library) |

---

## Post-Pipeline Validation Layer: Great Expectations

The `biorempp_validation/` package is a standalone Python project consumed after the Snakemake pipeline completes. It reads `biorempp_snakemake_version/results/` as its `input_results_root`.

### Module Responsibilities

| Module | Responsibility |
|---|---|
| `run_validation.py` | Orchestrator: loads settings, builds dataframes, runs checkpoints, writes outputs |
| `settings.py` | `ValidationSettings` frozen dataclass; `load_settings()` parses `config/validation.yaml` |
| `loaders.py` | File existence checks; loads CSV and JSON artifacts |
| `json_to_dataframe.py` | Converts analysis JSON payloads to pandas DataFrames for GX inspection |
| `consistency_checks.py` | Builds `cross_consistency` DataFrame from database CSV + basic statistics |
| `gx_context.py` | Creates ephemeral GX context, datasource, and runs suites against DataFrames |
| `report_builder.py` | Builds `validation_summary` dict from critical + warning checkpoint results |

### Checkpoints and Expectation Suites

Two checkpoints run sequentially:

**`critical_gate`** — failures cause `run_validation.py` to return exit code 1 (controlled by `fail_on_critical: true`).

Expectation suites run inside `critical_gate`:

| Suite | Dataset | What it checks |
|---|---|---|
| `database_critical.json` | `database_csv` | Column list ordered match, no-null on required columns, value patterns |
| `metadata_kegg_critical.json` | `metadata_kegg` | KEGG release fields present |
| `pipeline_reports_critical.json` | `pipeline_reports` | keys_consistency_report and links_groundtruth_policy_report pass |
| `analysis_json_critical.json` | `analysis_critical` | Row/column counts, basic stats consistency (internal_consistency mode) |
| `analysis_json_internal_consistency_critical.json` | `analysis_internal_consistency` | Exact numeric agreement between database and analysis JSONs |
| `analysis_json_regression_critical.json` | `analysis_regression` | Current run vs. baseline snapshot (regression_detection mode) |
| `cross_consistency_critical.json` | `cross_consistency` | Cross-checks between database CSV and basic_statistics.json |

**`warning_report`** — failures are logged but configurable; `fail_on_warning: true` in `validation.yaml`.

| Suite | Dataset | What it checks |
|---|---|---|
| `database_warning.json` | `database_csv` | Row count bounds, unique value counts for cpd/ko/genesymbol/genename/enzyme_activity, allowed referenceAG and compoundclass sets |
| `analysis_json_warning.json` | `analysis_warning` | Warning-level analysis statistics checks |

### Drift Thresholds (from `validation.yaml`)

| Metric | Min | Max |
|---|---|---|
| row_count | 118,000 | 130,000 |
| unique_compounds | 360 | 410 |
| unique_ko | 1,440 | 1,650 |
| unique_genesymbol | 1,410 | 1,625 |
| unique_genename | 1,320 | 1,525 |
| unique_enzyme_activity | 185 | 230 |

---

## Shared Libraries

### `workflow/lib/utils.R`

Utility functions used by every R script:

- `parse_cli_args()` / `require_cli_args()` — `--key value` CLI parsing
- `load_required_packages()` — defensive package loader
- `log_message(msg, level)` — timestamped stderr logging
- `ensure_parent_dir(path)` — mkdir -p before write
- `is_na_like()` / `is_present_value()` / `normalize_na_text()` — NA-marker normalization (reads `na_markers.txt`)
- `read_database_csv()` / `write_database_csv()` — CSV I/O with consistent quoting and encoding
- `write_json_file()` / `read_json_file()` — JSON I/O via jsonlite

### `workflow/lib/io_contracts.R`

Declares three global constants:

- `REQUIRED_INPUT_FILES` — 6 input file names verified by `00_check_inputs.R`
- `EXPECTED_DATABASE_COLUMNS` — 12-column schema contract enforced at export time
- `KEGG_ENDPOINTS` — named list of endpoint definitions (used by `03_fetch_kegg_data.R`)
- `KEGG_VALUE_PATTERNS` — regex patterns for validating KEGG identifiers

---

## Key Design Decisions

1. **RDS intermediate format**: All inter-stage data in `work/` uses R's native `.rds` binary format, not CSV. This preserves R types and avoids CSV quoting/encoding edge cases.

2. **Normalization at every boundary**: `normalize_cpd()`, `normalize_ko()`, `normalize_ec()`, `normalize_reaction()` are re-implemented (not imported) in both the generation scripts and `07_metadata.R`. This is intentional: each use site is independently defensive.

3. **Column contract as selection gate**: `dplyr::select(all_of(EXPECTED_DATABASE_COLUMNS))` in `07_extract_enzymes_export.R` means the column list is enforced at write time, not just checked post-hoc. Adding or removing a column without updating `EXPECTED_DATABASE_COLUMNS` will hard-fail the pipeline.

4. **Support stage as provenance**: The `support_stage` column makes the quality of each row's ec/reaction linkage transparent to downstream users without needing separate metadata.

5. **Two-tier validation**: In-pipeline validation (`30_validation.smk`) checks structural integrity of KEGG keys immediately after generation. The post-pipeline GX layer checks statistical properties (drift), schema compliance, cross-consistency, and regression against a pinned baseline.

6. **Regression baseline**: `biorempp_validation/baselines/release_v1_1_0_kegg_118_0plus/` stores the frozen analysis JSONs and KEGG release for the reference build. The regression_detection mode in GX compares current run counts against this baseline to detect unintended KEGG-driven data drift.

7. **Config-driven delimiter**: The CSV uses `;` as delimiter (`config.yaml`: `database_csv_delimiter: ";"`) to avoid collisions with comma-containing gene names and reaction descriptions.

---

*Architecture analysis: 2026-05-31*
