# Coding Conventions

**Analysis Date:** 2026-05-17

## Languages

This codebase uses two primary languages:

- **Python** — `biorempp_validation/` package (validation logic, GE integration, CLI)
- **R** — `biorempp_snakemake_version/workflow/scripts/` and `workflow/lib/` (database generation and analysis pipeline)
- **Snakemake** — `biorempp_snakemake_version/workflow/rules/*.smk` (workflow orchestration)

Conventions below are organized by language.

---

## Python Conventions

### Naming Patterns

**Files:**
- Module files: `snake_case.py` — e.g., `run_validation.py`, `consistency_checks.py`, `json_to_dataframe.py`
- Test files: `test_<subject>.py` — e.g., `test_happy_path.py`, `test_missing_files.py`, `test_schema_break.py`

**Functions:**
- Public functions: `snake_case` — e.g., `load_settings()`, `build_cross_consistency_df()`, `run_suite_on_dataframe()`
- Private/internal helpers: prefixed with `_` — e.g., `_safe_nunique()`, `_run_checkpoint()`, `_write_json()`, `_extract_failed_expectations()`
- CLI entrypoints: `main()` / `main_cli()` pattern (both present in `run_validation.py`)

**Variables:**
- `snake_case` throughout — e.g., `analysis_payloads`, `suite_payloads`, `output_dir`

**Classes:**
- `PascalCase` — e.g., `ValidationSettings` (frozen dataclass in `settings.py`)
- Only one public class exists in the package; dataclasses are used instead of plain classes

**Type Annotations:**
- All public function signatures carry full type annotations with `from __future__ import annotations` at top of every module
- Uses `list[str]`, `dict[str, Any]`, `Path` — modern union syntax (`X | Y`)
- Return types annotated on all public functions

### Code Style

**Formatting:**
- No `pyproject.toml` formatter config is present (Black/Ruff not declared)
- Indentation: 4 spaces (PEP 8 standard)
- Line length: up to ~130 characters observed (long `elif` chains in `run_validation.py`)
- String quotes: double quotes used exclusively (`"utf-8"`, `"biorempp_validation"`)

**Linting:**
- No `.flake8`, `.pylintrc`, or `ruff.toml` detected
- `pyproject.toml` has no `[tool.ruff]` or `[tool.black]` sections

### Import Organization

**Pattern:**
1. `from __future__ import annotations` — always first line
2. Standard library imports (alphabetical within group)
3. Third-party imports (pandas, great_expectations, yaml)
4. Relative package imports using `.module` syntax

**Example from `run_validation.py`:**
```python
from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any

from great_expectations.core.expectation_suite import ExpectationSuite

from .consistency_checks import build_cross_consistency_df
from .gx_context import (
    create_context,
    create_pandas_datasource,
    ...
)
from .loaders import (
    find_missing_paths,
    load_analysis_payloads,
    ...
)
```

**Path handling:**
- `pathlib.Path` used exclusively — no `os.path` string concatenation in the validation package
- File I/O always with explicit `encoding="utf-8"`

### Error Handling

**Patterns:**
- Functions that cannot continue raise `RuntimeError` with descriptive messages: `raise RuntimeError(f"Failed to fetch endpoint after {max_retries} attempts: {url} | {last_error}")`
- File-not-found conditions raise `FileNotFoundError` with the path included
- `KeyError` and `ValueError` raised for contract violations (e.g., missing/multiple CSV declarations)
- No bare `except:` clauses — exceptions are caught by specific type: `except (urllib.error.URLError, TimeoutError) as err:`
- Sentinel value `-1` used for missing numeric stats (avoids None propagation into DataFrames)
- Boolean guards pattern: `if missing_files: ... return 1` (early return rather than deep nesting)

**Exit codes:**
- `run()` in `run_validation.py` returns `0` (success) or `1` (failure) — standard Unix convention
- `main_cli()` wraps with `raise SystemExit(main())`

### Logging

**Framework:** `print()` for warnings in script-level code; no structured logger in the validation package
- Example: `print(f"[WARN] Fetch failed for {url} at attempt {attempt}/{max_retries} ...")`
- No logging module configured

### Comments and Documentation

**Docstrings:** Not used — zero docstrings found in the validation package source files
**Inline comments:** Rarely used; code is written to be self-documenting via descriptive function/variable names
**Module docstring:** One-liner only in `__init__.py`: `"""BioRemPP Great Expectations validation package."""`

### Function Design

**Size:** Functions are medium-length; `_apply_config_overrides_to_suite_payloads()` in `run_validation.py` is the longest (~100 lines) and handles all suite patching in one place
**Parameters:** Explicit named parameters; no `*args` or `**kwargs` in public API
**Return values:** Always explicitly typed; functions returning DataFrames do so via `pd.DataFrame([row])`

### Module Design

**Exports:** Flat module layout within `biorempp_validation/`; no `__all__` defined in sub-modules (only in `__init__.py`)
**Barrel files:** `__init__.py` is minimal — exposes only `__version__`
**Relative imports:** All internal imports use relative syntax (`.module`)

---

## R Conventions

### Naming Patterns

**Files:**
- Numbered scripts: `NN_descriptive_name.R` — e.g., `00_check_inputs.R`, `03_fetch_kegg_data.R`, `07_metadata.R`
- Library files: lowercase descriptive — `utils.R`, `io_contracts.R`
- Analysis scripts: `NN_<topic>_statistics.R` — e.g., `01_basic_statistics.R`, `02_compound_statistics.R`

**Functions:**
- `snake_case` throughout — e.g., `load_required_packages()`, `parse_cli_args()`, `write_json_file()`, `canonicalize_link_endpoint()`
- Private helpers: no underscore prefix convention; scope is implicitly per-script since scripts are sourced
- Predicate functions: `is_na_like()`, `is_present_value()`, `all_values_match()`

**Variables:**
- `snake_case` for local variables — e.g., `db_rows`, `output_file`, `base_url`
- `SCREAMING_SNAKE_CASE` for module-level constants — e.g., `REQUIRED_INPUT_FILES`, `EXPECTED_DATABASE_COLUMNS`, `KEGG_ENDPOINTS`, `NA_MARKERS`, `RETRY_MAX`

**Lists/structures:**
- Named lists used as return types — `list(status = "ok", input_dir = ..., ...)`

### Code Style

**Formatting:**
- Indentation: 2 spaces (standard R convention)
- Line length: reasonable (~100 chars); long strings broken with continuation
- Assignment: `<-` for all assignments (not `=`)
- String quotes: double quotes only

**Shebangs:** All R scripts begin with `#!/usr/bin/env Rscript`

### Imports and Dependencies

**Pattern in each script:**
```r
#!/usr/bin/env Rscript

source("workflow/lib/utils.R")           # always sourced first
source("workflow/lib/io_contracts.R")    # sourced when constants needed

load_required_packages(c("jsonlite", "dplyr", "stringr"))  # explicit deps
```

- All scripts source `workflow/lib/utils.R` first
- `io_contracts.R` sourced when `REQUIRED_INPUT_FILES`, `EXPECTED_DATABASE_COLUMNS`, or `KEGG_ENDPOINTS` constants are needed
- `suppressPackageStartupMessages()` used inside `load_required_packages()` for clean output

### CLI Pattern (R)

All R scripts use the custom `parse_cli_args()` + `require_cli_args()` pattern from `utils.R`:

```r
args <- parse_cli_args()
require_cli_args(args, c("input-dir", "output", "config"))
```

- Arguments passed as `--key value` pairs
- Keys use `kebab-case` (not underscores)
- Required args validated immediately after parsing — script fails early with a clear message

### Error Handling (R)

- `stop(..., call. = FALSE)` used throughout — suppresses the `Error in <function>:` prefix for cleaner messages
- `tryCatch()` used for API fetch retries in `03_fetch_kegg_data.R`
- `suppressWarnings()` used for type coercions where `NA` is expected fallback
- Early validation: directory existence, file existence, column presence — checked before any processing

### Logging (R)

**Function:** `log_message()` from `utils.R`
```r
log_message <- function(msg, level = "INFO") {
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  message(sprintf("%s [%s] %s", timestamp, level, msg))
}
```
- Levels used: `"INFO"`, `"SUCCESS"`, `"WARN"`
- `log_message()` called at end of every script with `"SUCCESS"` level
- Warnings during retries use `"WARN"` level

### Comments and Documentation (R)

- No roxygen2 (`#'`) documentation
- Inline `#` comments used sparsely for non-obvious logic
- Scripts are self-documenting via function and variable naming

---

## Snakemake Conventions

**Rule naming:** lowercase with underscores — e.g., `preflight_check_inputs`, `fetch_kegg_info`, `merge_relationships`

**File numbering:** Rules files are numbered by phase: `00_preflight.smk`, `10_generation.smk`, `20_analysis.smk`, `30_validation.smk`, `90_reporting.smk`

**Shell commands:** Each rule uses a single multi-line shell string formatted with explicit flags — e.g.:
```python
shell: (
    "Rscript workflow/scripts/generation/02_fetch_kegg_info.R "
    "--output {output} "
    "--config {params.config_file} "
    "--base-url {params.base_url} "
    "> {log} 2>&1"
)
```

**Logging:** Every rule redirects stdout and stderr to a log file via `> {log} 2>&1`

---

## Cross-Language Shared Conventions

**NA normalization:** Both Python (`common_normalization.py`) and R (`utils.R`) implement identical `load_na_markers()` and `is_na_like()` functions, reading from the same `workflow/lib/na_markers.txt` file.

**KEGG identifier patterns:** Both languages define identical regex patterns for `ko`, `cpd`, `reaction`, `ec` — validated in `io_contracts.R` and `common_normalization.py`.

**JSON output:** Both languages write JSON with `indent=2` (Python) or `pretty = TRUE` (R jsonlite).

**UTC timestamps:** Both use `datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")` (Python) and equivalent R format.

**File path handling:**
- Python: `pathlib.Path` exclusively
- R: `file.path()` and `dirname()` / `dir.create(recursive = TRUE)` via `ensure_parent_dir()`

---

*Convention analysis: 2026-05-17*
