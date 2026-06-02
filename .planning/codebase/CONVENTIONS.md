# Coding Conventions

_Last updated: 2026-05-31_

## Summary

BioRemPP DB is a multi-language pipeline (R + Python + Snakemake) that enforces consistent conventions across all layers. R scripts follow a strict `source → load → parse → execute → log` structure. Python code uses frozen dataclasses and YAML-driven settings. Git history uses the Conventional Commits specification with a two-letter severity/scope code suffix.

---

## R Style

### File Header Pattern

Every R script begins with a shebang and immediately sources the shared library:

```r
#!/usr/bin/env Rscript

source("workflow/lib/utils.R")
source("workflow/lib/io_contracts.R")   # only when database column contracts are needed
```

Paths are always relative to the Snakemake working directory (`biorempp_snakemake_version/`), never absolute.

### Package Loading

All packages are loaded via `load_required_packages()` from `workflow/lib/utils.R`. Never call `library()` or `require()` directly in a script.

```r
load_required_packages(c("dplyr", "stringr", "jsonlite"))
```

`load_required_packages()` suppresses startup messages and stops with an install hint if any package is missing. Defined in `biorempp_snakemake_version/workflow/lib/utils.R` (lines 3–27).

### CLI Argument Pattern

All scripts receive inputs exclusively as `--key value` CLI pairs. The pattern is:

```r
args <- parse_cli_args()
require_cli_args(args, c("input-csv", "output"))

input_file <- args[["input-csv"]]
output_file <- args[["output"]]
```

- `parse_cli_args()` — parses `commandArgs(trailingOnly = TRUE)` into a named list (`workflow/lib/utils.R` lines 29–49).
- `require_cli_args()` — stops with a clear error if any required key is absent (lines 51–56).
- Argument keys use `kebab-case` (e.g., `--input-csv`, `--csv-sep`, `--base-url`).

### Naming Conventions

| Element | Convention | Example |
|---|---|---|
| Functions | `snake_case` verbs | `normalize_cpd()`, `build_key_universe()` |
| Variables | `snake_case` nouns | `agency_norm`, `merged_compounds` |
| Constants (module-level) | `UPPER_SNAKE_CASE` | `UNSUPPORTED_KEY_WARN_THRESHOLD`, `NA_MARKERS` |
| Column names in data frames | `snake_case` (except legacy KEGG fields) | `reaction_description`, `referenceAG` (legacy exception) |

### Function Structure

Functions are small, single-purpose, and named with a verb prefix:

- `normalize_*` — strip prefixes, extract canonical IDs (e.g., `normalize_cpd`, `normalize_ko`)
- `build_*` — construct a data structure from inputs (e.g., `build_key_universe`, `build_ko_complete`)
- `extract_*` — pull a subset from a larger object (e.g., `extract_kegg_links`)
- `compute_*` — derive numeric summaries (e.g., `compute_completeness`)
- `add_*` — join/enrich an existing frame (e.g., `add_compound_names`)

Functions defined inside a script are placed before the top-level execution block. The execution block follows all function definitions at the bottom of the file.

### Logging Pattern

```r
log_message("Saved merged data to path/to/file.rds", "SUCCESS")
log_message("Unsupported key rate 6.2% exceeds 5.0% threshold", "WARNING")
log_message(sprintf("Universe keys: %d | Dense rows: %d", n_total, n_dense), "INFO")
```

`log_message(msg, level)` is defined in `workflow/lib/utils.R` (line 58). It writes to `stderr` with format `YYYY-MM-DD HH:MM:SS [LEVEL] message`. Levels used: `INFO`, `WARNING`, `SUCCESS`. Never use bare `message()` or `cat()` in scripts.

### I/O Helpers

Always use these wrappers from `workflow/lib/utils.R` — never call base R I/O directly:

| Helper | Purpose |
|---|---|
| `read_database_csv(path, sep)` | Read CSV with consistent `stringsAsFactors=FALSE`, `check.names=FALSE` |
| `write_database_csv(df, path, sep, quote)` | Write CSV with UTF-8 encoding, `row.names=FALSE` |
| `read_json_file(path)` | Reads JSON; stops if file not found |
| `write_json_file(object, path)` | Writes pretty JSON with `auto_unbox=TRUE` |
| `ensure_parent_dir(path)` | Creates parent directory if missing before writes |

RDS files are used for intermediate work-dir objects (`saveRDS` / `readRDS`). CSV and JSON are used for final outputs.

### NA Handling

Use `is_na_like()` and `normalize_na_text()` from `workflow/lib/utils.R` instead of `is.na()` for data frames that may contain string NAs (`"NA"`, `"<NA>"`, `"NULL"`, `"NONE"`, `"N/A"`):

```r
dplyr::filter(!is.na(cpd), !is.na(ko))          # OK for columns already normalized
text[is_na_like(values)] <- NA_character_        # use normalize_na_text() for raw input
```

`NA_MARKERS` is the global character vector loaded at `utils.R` line 97.

### dplyr Pipeline Style

All data manipulation uses `%>%` pipelines with explicit `dplyr::` namespace prefixes. Never use `attach()` or base R indexing for data frames inside pipelines. Always end grouped operations with `.groups = "drop"`.

```r
agency_norm %>%
  dplyr::inner_join(links$cpd_ec, by = "cpd", relationship = "many-to-many") %>%
  dplyr::transmute(cpd, ko, referenceAG) %>%
  dplyr::distinct()
```

---

## Shared Library Files

### `workflow/lib/utils.R`

Central utility library sourced by every R script. Provides:
- `load_required_packages()` — package loader
- `parse_cli_args()` / `require_cli_args()` — CLI parsing
- `log_message()` — structured logging
- `ensure_parent_dir()` — safe directory creation
- `write_json_file()` / `read_json_file()` — JSON I/O wrappers
- `read_database_csv()` / `write_database_csv()` — CSV I/O wrappers
- `is_na_like()` / `is_present_value()` / `normalize_na_text()` — NA helpers
- `NA_MARKERS` — global NA sentinel vector

### `workflow/lib/io_contracts.R`

Data contract constants. Sourced only by scripts that need to enforce schema or validate inputs against known keys.

- `REQUIRED_INPUT_FILES` — list of mandatory input Excel/text files
- `EXPECTED_DATABASE_COLUMNS` — ordered column list for the final database CSV
- `KEGG_ENDPOINTS` — canonical endpoint definitions (name, endpoint path, column names, separator)
- `KEGG_VALUE_PATTERNS` — regex patterns for `ko`, `ec`, `reaction`, `cpd` validation

---

## Python Style

### Module Structure

Python code lives exclusively in `biorempp_validation/src/biorempp_validation/`. Each module has a single responsibility:

| Module | Responsibility |
|---|---|
| `settings.py` | Load and validate `validation.yaml` into a frozen `ValidationSettings` dataclass |
| `run_validation.py` | Orchestrate the full validation run |
| `gx_context.py` | Create GE context, datasource, and run suites |
| `loaders.py` | Load CSV, JSON, and analysis payloads from disk |
| `json_to_dataframe.py` | Build pandas DataFrames from analysis JSON artifacts |
| `consistency_checks.py` | Compute cross-consistency DataFrame |
| `report_builder.py` | Build `validation_summary.json` from checkpoint results |

### Naming Conventions

| Element | Convention | Example |
|---|---|---|
| Functions (public) | `snake_case` verbs | `load_settings()`, `build_validation_summary()` |
| Functions (private/internal) | `_snake_case` with leading underscore | `_apply_config_overrides_to_suite_payloads()`, `_build_checkpoint_validations()` |
| Classes / dataclasses | `PascalCase` | `ValidationSettings`, `ValidationModes` |
| Constants (module-level) | `UPPER_SNAKE_CASE` | `DEFAULT_REGRESSION_BASELINE_ROOT`, `_ALWAYS_REQUIRED_NON_CSV` |
| Variables | `snake_case` | `suite_payloads`, `dataframe_by_dataset` |

### Import Style

All modules use `from __future__ import annotations` as the first line. Standard library imports come before third-party imports. Type annotations use `list[str]`, `dict[str, Any]`, `Path` (from `pathlib`) — never `List`, `Dict`, `Optional` from `typing` for simple cases.

### Settings Pattern

`ValidationSettings` is a frozen dataclass. It is constructed once by `load_settings(config_path)` from `settings.py` and passed through the call stack. Never read `validation.yaml` directly outside `settings.py`.

```python
settings = load_settings("biorempp_validation/config/validation.yaml")
# settings.fail_on_critical, settings.drift_thresholds, etc.
```

---

## Snakemake Rule Naming

Rules are defined in numbered `.smk` files under `workflow/rules/`:

| File | Prefix | Rules |
|---|---|---|
| `00_preflight.smk` | `preflight_` | `preflight_check_inputs` |
| `10_generation.smk` | none / descriptive | `fetch_kegg_info`, `load_local_data`, `fetch_kegg_data`, `merge_relationships` |
| `20_analysis.smk` | none / descriptive | `basic_statistics`, `compound_statistics`, `ko_statistics`, `enzyme_statistics`, `gene_statistics`, `crosstab_statistics`, `database_metadata` |
| `30_validation.smk` | `validate_` / `fetch_` | `fetch_kegg_link_cache`, `validate_keys_consistency`, `validate_links_groundtruth_policy` |
| `90_reporting.smk` | `build_` | `build_run_report` |

Rule names use `snake_case` and match their primary output artifact name. The shell command in every rule redirects both stdout and stderr to the Snakemake log: `> {log} 2>&1`.

---

## Configuration Pattern

Three configuration files govern the pipeline. They are layered: Snakemake config drives pipeline execution, validation config drives the GE layer.

### `biorempp_snakemake_version/config/config.yaml`

Covers pipeline version, directory paths, output filenames, KEGG API endpoints, analysis `top_n` parameters, and the `validation.max_invalid_line_ratio` threshold. Consumed by Snakemake rules via `config["kegg"]["base_url"]`, etc.

### `biorempp_validation/config/validation.yaml`

Consumed exclusively by `load_settings()` in `settings.py`. Covers:
- `policy` — `fail_on_critical`, `fail_on_warning`, `generate_summary_page`
- `validation_modes` — `internal_consistency`, `regression_detection`
- `paths` — all input/output paths relative to `biorempp_validation/`
- `database_contract` — `expected_columns`, `expected_reference_agencies`, `expected_compound_classes`, `nullable_columns`
- `drift_thresholds` — `{min, max}` bands for row count and unique-value counts per column

The validation YAML is the single source of truth for the data contract. Never hard-code column lists or agency sets inside Python modules.

---

## Git Commit Style

Commits follow the Conventional Commits specification with an additional severity/priority code:

```
<type>(<scope>): <severity-code> -- <description>
```

**Types in use:**

| Type | When |
|---|---|
| `fix` | Bug fix or correction |
| `feat` | New feature |
| `chore` | Non-functional maintenance (regenerating outputs, dependency bumps) |
| `docs` | Documentation changes only |
| `refactor` | Structural improvement without behavior change |

**Scopes in use:** `generation`, `analysis`, `validation`, `env`, `results`, `planning`

**Severity codes (two-letter prefix after scope):**
- `L2`, `L5` — low severity
- `M5`, `M6`, `M7` — medium severity
- `H1`, `H2` — high severity

**Examples from the repo:**

```
fix(generation): L2 -- add support_stage provenance column to exported database
fix(env): L5 -- pin httr 1.4.7 in r-packages.txt and Dockerfile
chore(results): L2 -- regenerate outputs after support_stage schema addition
fix(validation): M7 -- move KEGG link cache from work/ to cache/
docs(planning): mark C1, C2, H1, H2 as [FIXED] in CONCERNS.md
feat(validation): cover three first-class pipeline outputs in GE critical gate
```

When regenerating pipeline outputs without code changes, use `chore(results):`.

---

## Script Numbering Convention

R scripts in `workflow/scripts/generation/` and `workflow/scripts/analysis/` are prefixed with two-digit numbers reflecting pipeline execution order:

- `00_check_inputs.R` → preflight
- `01_load_local_data.R` → load Excel inputs
- `02_fetch_kegg_info.R` → KEGG metadata
- `03_fetch_kegg_data.R` → KEGG API bulk fetch
- `04_merge_relationships.R` → core merge logic
- `05_add_classifications.R` → compound class enrichment
- `06_enrich_gene_info.R` → gene info enrichment
- `07_extract_enzymes_export.R` → final export to CSV/XLSX
- `01_basic_statistics.R` through `09_merge_complete_analysis.R` → analysis layer

Do not renumber existing scripts. New scripts in an existing stage insert at the next available number.
