# Coding Conventions

**Analysis Date:** 2026-03-24

## Naming Patterns

**Files:**
- Lowercase with underscores: `loaders.py`, `consistency_checks.py`, `json_to_dataframe.py`
- Script files use shebang: `#!/usr/bin/env python3`
- Test files use `test_<module>.py` naming convention

**Functions:**
- Lowercase with underscores (snake_case): `normalize_token()`, `_safe_nunique()`, `load_database_csv()`, `parse_args()`
- Private/internal functions prefixed with underscore: `_safe_nunique()`, `_run_checkpoint()`, `_apply_config_overrides_to_suite_payloads()`
- Type hints in function signatures are mandatory

**Variables:**
- Lowercase with underscores: `database_csv`, `analysis_payloads`, `checkpoint_name`, `missing_values`
- Constants use UPPERCASE: `NA_MARKERS`, `PATTERNS`
- Dictionary keys use lowercase with underscores: `"total_entries"`, `"parsed_pairs"`, `"expectation_type"`

**Types:**
- Classes use PascalCase: `ValidationSettings`, `ExpectationSuite`
- Type hints use modern syntax from `__future__ import annotations`

## Code Style

**Formatting:**
- 4-space indentation (Python standard)
- Maximum line length approximately 120 characters (observed in practice)
- No linting/formatting tool configured (no `.flake8`, `.pylintrc`, or `.ruff.toml` found)

**Import Headers:**
- Files start with `from __future__ import annotations` on line 1
- Blank line after imports before first definition
- Imports in standard order: stdlib, third-party, local

**Line Continuations:**
- Function signatures break naturally across lines for readability
- Dictionary/list values aligned for clarity

Example from `run_validation.py`:
```python
from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any

from great_expectations.core.expectation_suite import ExpectationSuite

from .consistency_checks import build_cross_consistency_df
```

## Import Organization

**Order:**
1. `__future__` imports (always first)
2. Standard library imports (e.g., `json`, `pathlib`, `argparse`)
3. Third-party imports (e.g., `pandas`, `yaml`, `great_expectations`)
4. Local imports using relative dots (e.g., `from .settings import ValidationSettings`)

**Path Aliases:**
- Not used; imports use relative imports within packages and absolute module paths for cross-package imports

## Error Handling

**Patterns:**
- Exceptions raised with descriptive messages using f-strings
- Example from `loaders.py`: Raises `FileNotFoundError` with full path for debugging
- Example from validation scripts: `RuntimeError` for API fetch failures with retry context
- Custom error messages include context about what failed and why

```python
# Example pattern from build_run_report.py
if not file_path.exists():
    raise FileNotFoundError(f"Required file does not exist: {file_path}")
```

**Return Patterns:**
- Functions return `int` exit codes: 0 for success, 1 for failure
- Functions return dictionaries for structured results
- Functions may return None implicitly where not meaningful to return

## Logging

**Framework:** `print()` statements and JSON output files

**Patterns:**
- No structured logging library used
- Results written as JSON files to disk with `json.dump()` with `indent=2` for readability
- Timestamps in ISO 8601 format with UTC timezone: `datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")`
- Example from `report_builder.py`: `"generated_at_utc": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")`

## Comments

**When to Comment:**
- Sparse commenting; code is self-documenting through clear naming
- No docstrings observed in the codebase
- Inline comments used for regex pattern explanation

**JSDoc/TSDoc:**
- Not used; Python docstrings not applied

## Function Design

**Size:** Functions are small and focused
- Helper functions typically 5-15 lines
- Main orchestration functions (like `run()`) may be 40-90 lines but logically segmented

**Parameters:**
- Use explicit parameters over *args/**kwargs
- Type hints are mandatory for function parameters and returns
- Example: `def build_analysis_critical_df(analysis_payloads: dict[str, dict[str, Any]], expected_columns: list[str]) -> pd.DataFrame:`

**Return Values:**
- Explicit return types using type hints
- Functions return domain objects (DataFrames, dicts) not primitives
- Boolean-returning functions use `bool()` cast for clarity: `bool(result.get("success", False))`

## Module Design

**Exports:**
- No `__all__` declarations observed
- All public functions are implicitly exported
- Example structure in `loaders.py`: Multiple small functions each with single responsibility

**Barrel Files:**
- No barrel files (index.py with re-exports) used
- Package `__init__.py` contains minimal content (often just version or empty)

## Type Hints

**Modern Python Type Annotations:**
- `list[str]` instead of `List[str]`
- `dict[str, Any]` instead of `Dict[str, Any]`
- Union types: `str | Path` instead of `Union[str, Path]`
- Optional implied by default: `config_path: str | Path` returns validation settings

**Example from settings.py:**
```python
def load_settings(config_path: str | Path) -> ValidationSettings:
    config_path = Path(config_path).resolve()
    # ...
    return ValidationSettings(...)
```

## Dictionary Patterns

**Serialization:**
- Dictionaries serialized as JSON with `json.dump(payload, handle, indent=2)` for readable output
- All keys are strings; values are primitives or nested dicts/lists
- YAML used for configuration files with `yaml.safe_load()` and `yaml.safe_dump()`

## Data Processing Patterns

**DataFrame Handling:**
- Pandas DataFrames used for tabular data validation
- Column access by string name: `df[column].nunique()`
- Safe checks before column access: `if column not in df.columns: return -1`
- Type casting: `int(value)` for numeric conversions

Example from `consistency_checks.py`:
```python
def _safe_nunique(df: pd.DataFrame, column: str) -> int:
    if column not in df.columns:
        return -1
    return int(df[column].nunique())
```

---

*Convention analysis: 2026-03-24*
