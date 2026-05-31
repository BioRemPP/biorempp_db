# CONVENTIONS — BioRemPP DB 1.0.0

> Last mapped: 2026-05-31

## Summary

BioRemPP is a bilingual pipeline (Python + R) orchestrated by Snakemake. Python code lives in `biorempp_validation/` (a standalone installable package) and in `biorempp_snakemake_version/workflow/scripts/` (stand-alone CLI scripts). R code lives in `biorempp_snakemake_version/workflow/scripts/` and shared library files in `biorempp_snakemake_version/workflow/lib/`. Conventions are consistent within each language but there is no cross-language style enforcer (no `ruff`, `black`, `.eslintrc`, or `lintr` config found). The dominant style is explicit, verbose, and defensive — functions fail loudly rather than silently, all I/O goes through centralized helpers, and every script is independently runnable as a CLI tool.

---

## Naming Conventions

### Python (`biorempp_validation/` and `workflow/scripts/`)

| Element | Pattern | Example |
|---|---|---|
| Files | `snake_case.py` with numeric prefix where order matters | `01_validate_keys_consistency_api.py`, `common_normalization.py` |
| Functions — public | `snake_case` verbs | `build_cross_consistency_df`, `load_analysis_payloads`, `parse_args` |
| Functions — private | Leading underscore `_snake_case` | `_extract_failed_expectations`, `_write_json`, `_load_suite_payload` |
| Classes | `PascalCase` | `ValidationSettings` |
| Constants | `UPPER_SNAKE_CASE` at module scope | `NA_MARKERS`, `PATTERNS`, `RETRY_MAX`, `BACKOFF_BASE` |
| Variables | `snake_case` | `analysis_payloads`, `suite_results`, `checkpoint_success` |
| Type aliases | `dict[str, Any]`, `list[str]` (no `TypeAlias`) | — |

### R (`workflow/scripts/` and `workflow/lib/`)

| Element | Pattern | Example |
|---|---|---|
| Files | `NN_descriptive_name.R` (two-digit prefix) | `01_load_local_data.R`, `07_metadata.R` |
| Functions | `snake_case` | `load_required_packages`, `parse_cli_args`, `build_link_match` |
| Variables | `snake_case` | `local_data`, `enzyme_frequency`, `top_enzymes` |
| Constants | `UPPER_SNAKE_CASE` | `REQUIRED_INPUT_FILES`, `EXPECTED_DATABASE_COLUMNS`, `KEGG_ENDPOINTS` |
| Nested lists | `snake_case` keys matching JSON output keys | `database_info`, `data_sources`, `pair_support` |

### Snakemake rules (`workflow/rules/`)

| Element | Pattern | Example |
|---|---|---|
| Rule files | `NN_phase_name.smk` | `10_generation.smk`, `30_validation.smk` |
| Rule names | `snake_case` verbs | `fetch_kegg_info`, `validate_keys_consistency`, `build_run_report` |
| Path constants | `UPPER_SNAKE_CASE` | `RESULTS_DIR`, `WORK_DIR`, `KEGG_LINK_CACHE` |

---

## File Shebang and Header Convention

All Python scripts that are invoked directly carry a shebang:
```python
#!/usr/bin/env python3
```

All R scripts carry:
```r
#!/usr/bin/env Rscript
```

Python package modules in `biorempp_validation/src/` always open with:
```python
from __future__ import annotations
```

---

## Type Annotations (Python)

All public and private functions in `biorempp_validation/src/` carry full return-type annotations. Parameter types are annotated consistently:

```python
def build_cross_consistency_df(database_df: pd.DataFrame, basic_stats: dict) -> pd.DataFrame:
def load_settings(config_path: str | Path) -> ValidationSettings:
def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
def _write_json(path: Path, payload: dict[str, Any]) -> None:
```

Standalone validation scripts in `workflow/scripts/` use lighter typing — return types are annotated on key functions like `sha256sum(path: Path) -> str` but not universally applied.

---

## Script Organization Pattern

### Python scripts (`workflow/scripts/`)

Each script follows this layout:
1. Module-level imports (stdlib, then third-party)
2. Module-level constants (e.g. `NA_MARKERS`, `PATTERNS`)
3. Pure helper functions
4. One `main()` function that builds the `argparse` parser, loads data, runs logic, writes output
5. `if __name__ == "__main__": main()`

```python
def build_parser():
    parser = argparse.ArgumentParser(...)
    parser.add_argument("--database-csv", required=True)
    ...
    return parser

def main():
    args = build_parser().parse_args()
    ...
    output_path.write_text(json.dumps(report, indent=2), encoding="utf-8")

if __name__ == "__main__":
    main()
```

### Python package modules (`biorempp_validation/src/`)

Each module owns one concern:
- `settings.py` — `dataclass`-based config loading only
- `loaders.py` — all file I/O (JSON, CSV)
- `json_to_dataframe.py` — transforms raw JSON payloads into DataFrames for GX
- `consistency_checks.py` — cross-source consistency metrics
- `gx_context.py` — Great Expectations wiring
- `report_builder.py` — summary dict construction
- `run_validation.py` — orchestration entry point

### R scripts (`workflow/scripts/`)

Each script follows:
1. `source("workflow/lib/utils.R")` and optionally `source("workflow/lib/io_contracts.R")`
2. `load_required_packages(c(...))`
3. `parse_cli_args()` + `require_cli_args(args, c(...))`
4. Local function definitions (no global side-effects before args are parsed)
5. Data loading, transformation, output
6. `log_message(...)` call at end with level `"SUCCESS"`

---

## CLI Argument Convention

### R scripts

Arguments are always `--kebab-case`:
```r
args <- parse_cli_args()
require_cli_args(args, c("input-csv", "csv-sep", "output", "top-n"))
input_csv <- args[["input-csv"]]
```

### Python scripts

Arguments are always `--kebab-case`, declared with `argparse`, and always marked `required=True` unless optional with an explicit default:
```python
parser.add_argument("--database-csv", required=True)
parser.add_argument("--max-invalid-line-ratio", type=float, default=0.01)
```

---

## Data Handling Patterns

### R — dplyr/tidyverse style

All tabular transformations use `dplyr` pipelines with explicit namespace qualification:
```r
enzyme_frequency <- db %>%
  dplyr::group_by(enzyme_activity) %>%
  dplyr::summarise(
    frequency = dplyr::n(),
    unique_compounds = dplyr::n_distinct(cpd),
    .groups = "drop"
  ) %>%
  dplyr::arrange(dplyr::desc(frequency))
```

Selection of final column order always uses `dplyr::select(dplyr::all_of(EXPECTED_DATABASE_COLUMNS))` to enforce the contract.

### Python — pandas style

DataFrames are constructed from scratch via `pd.DataFrame([row])` where `row` is a dict, rather than incremental mutations:
```python
row = {
    "metric": ...,
    "csv_value": ...,
    "stats_value": ...,
}
return pd.DataFrame(metrics, columns=["metric", "csv_value", "stats_value"])
```

Aggregations use `groupby(...).agg(...)` with named aggregation syntax:
```python
ko_df = (
    database_df.groupby("ko")
    .agg(frequency=("ko", "size"), unique_compounds_per_ko=("cpd", "nunique"))
    .reset_index()
    .sort_values(["frequency", "ko"], ascending=[False, True])
    .head(top_n)
)
```

Deterministic sort order is enforced with secondary sort columns (e.g. `["frequency", "ko"]`, ascending `[False, True]`) to prevent tie-order drift.

### NA handling

A shared NA-marker registry is maintained in `biorempp_snakemake_version/workflow/lib/na_markers.txt` and loaded by both R (`utils.R: load_na_markers()`) and Python (`common_normalization.py: load_na_markers()`). This is the single source of truth for what constitutes a missing value (`""`, `"NA"`, `"NAN"`, `"<NA>"`, `"NONE"`, `"NULL"`, `"N/A"` and any custom additions).

R helpers: `is_na_like()`, `is_present_value()`, `normalize_na_text()` — all in `workflow/lib/utils.R`.
Python helpers: `is_na_like()` — in `workflow/scripts/validation/common_normalization.py`.

---

## I/O Contracts

All file read/write operations go through centralized helpers. Direct `readLines`, `write.csv`, `open()`, `json.dump` are only used inside these helpers, not scattered in scripts.

### R helpers (`workflow/lib/utils.R`)
- `read_database_csv(path, sep)` — standardized CSV reader with `check.names=FALSE`
- `write_database_csv(dataframe, path, sep, quote)` — standardized writer with `na="NA"`, UTF-8
- `read_json_file(path)` — with existence check; raises on missing
- `write_json_file(object, path)` — with `ensure_parent_dir()`; always `pretty=TRUE, auto_unbox=TRUE`
- `ensure_parent_dir(path)` — creates parent directory if needed

### Python helpers (`biorempp_validation/src/biorempp_validation/loaders.py`)
- `load_json(path: Path)` — opens with `encoding="utf-8"`
- `load_database_csv(path: Path, sep: str)` — `pd.read_csv`
- `resolve_required_paths(...)` / `find_missing_paths(...)` — file presence check before loading

All JSON output is written with `indent=2` and `encoding="utf-8"`.

---

## Error Handling Patterns

### R

Errors always use `stop(..., call. = FALSE)` to suppress stack trace noise in CLI output:
```r
if (length(missing_files) > 0) {
  stop("Missing required input files: ", paste(missing_files, collapse = ", "), call. = FALSE)
}
```

Missing files raise immediately — no silent fallback.

### Python (workflow scripts)

Errors use `raise RuntimeError(...)` with descriptive messages:
```python
if stats["parsed_pairs"] == 0:
    raise RuntimeError(f"No valid pairs parsed for relation {left_type}->{right_type}")
raise RuntimeError(f"Failed to fetch endpoint after {max_retries} attempts: {url} | {last_error}")
```

File existence is checked before opening:
```python
for file_path in files.values():
    if not file_path.exists():
        raise FileNotFoundError(f"Required file does not exist: {file_path}")
```

### Python (validation package)

The validation package uses exit codes (`return 1` / `return 0`) rather than exceptions to signal pass/fail to the CI layer. Exceptions surface real bugs; expected validation failures are captured in the summary JSON.

---

## Logging / Output Conventions

### R

All progress messages go to `stderr` via the shared helper:
```r
log_message(sprintf("Saved basic statistics", ...), "SUCCESS")
# Output: 2026-05-31 12:34:56 [SUCCESS] Saved basic statistics
```

Levels used: `"INFO"` (default), `"SUCCESS"`, `"WARN"` (ad hoc in Python side).

### Python (workflow scripts)

Progress and warnings use `print(f"[WARN] ...")` or `print(f"[WARNING] ...")` to stdout. No `logging` module is used in standalone scripts.

### Python (validation package)

No explicit logging. Validation results are captured entirely in structured JSON (`validation_summary.json`, `critical_checkpoint_result.json`, `warning_checkpoint_result.json`).

---

## Snakemake Rule Conventions

- All shell commands redirect stdout and stderr to a dedicated log file: `> {log} 2>&1`
- Rule parameters use `config["section"]["key"]` directly, never inlined strings
- Intermediate outputs go to `WORK_DIR`; final outputs go to `RESULTS_DIR`
- Rule names match the script they invoke (`fetch_kegg_info` → `02_fetch_kegg_info.R`)

---

## Configuration

The pipeline has two configuration systems:
1. `biorempp_snakemake_version/config/config.yaml` — Snakemake workflow config (paths, KEGG URLs, CSV options, version)
2. `biorempp_validation/config/validation.yaml` — GX validation config (expected schema, drift thresholds, policy flags)

The database column contract is declared in `biorempp_snakemake_version/workflow/lib/io_contracts.R` (`EXPECTED_DATABASE_COLUMNS`) and mirrored in `biorempp_validation/config/validation.yaml` (`database_contract.expected_columns`). These two must be kept in sync manually — there is no automated cross-check.

---

## Confidence

- HIGH: naming conventions, script structure patterns, I/O helpers, CLI arg style — directly observed in all scripts
- HIGH: NA handling registry — confirmed shared across R and Python
- HIGH: type annotations in validation package — directly observed
- MEDIUM: no linter/formatter config found — inferred from absence of `.ruff.toml`, `pyproject.toml` tool sections, `.lintr`
- MEDIUM: dplyr namespace qualification as convention — consistently observed but not enforced
