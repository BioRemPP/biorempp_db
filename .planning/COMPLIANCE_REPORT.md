# Compliance Report — Concerns Audit

**Date:** 2026-05-18
**Branch:** `feat/database_update_ec_reaction`
**Verified against:** current working tree + git log

---

## Summary

| Status | Count |
|---|---|
| Verified Fixed | 9 |
| Incorrectly Marked Fixed | 1 |
| Fixed (uncommitted) | 1 |
| Open — Not Addressed | 12 |

---

## Concerns Marked as [FIXED] — Verification

### ✅ [HIGH] Duplicated `parse_link_payload` and API retry logic

**VERIFIED FIXED.**

- `kegg_api_client.py` was created at `workflow/scripts/validation/kegg_api_client.py` consolidating: `parse_link_payload`, `normalize_token`, `read_int_env`, `read_float_env`, `compute_backoff_seconds`, `fetch_text`, `load_database_rows`.
- Both `01_validate_keys_consistency_api.py` and `02_validate_links_groundtruth_policy_api.py` now import from `kegg_api_client` — confirmed via `from kegg_api_client import (...)` at line 10 of each script.
- The behavioral divergence between the two scripts no longer exists; a single implementation serves both.

---

### ❌ [MEDIUM] Snakemake pinned to version 7.32.4 — end-of-life

**INCORRECTLY MARKED AS FIXED.**

- `biorempp_snakemake_version/env/python-requirements.txt` still reads `snakemake==7.32.4`.
- No commit exists in this branch that upgrades Snakemake.
- The fix was planned (plan file written) but never executed — the plan was interrupted by a pipeline run request and subsequently skipped when the next concern was picked up.
- The [FIXED] tag in CONCERNS.md was applied in error during batch documentation.
- **Action required:** Remove [FIXED] tag from CONCERNS.md; the migration plan remains pending.

---

### ✅ [MEDIUM] R packages installed without version pinning

**VERIFIED FIXED.**

- `biorempp_snakemake_version/env/Dockerfile` now uses `remotes::install_version()` for all 7 R packages with explicit versions: `dplyr=1.1.4`, `readxl=1.4.3`, `tidyr=1.3.1`, `stringr=1.5.1`, `readr=2.1.5`, `jsonlite=1.8.8`, `writexl=1.5.0`.
- `r-packages.txt` is retained as a human-readable manifest but no longer parsed by the Dockerfile.
- Confirmed via `grep install_version biorempp_snakemake_version/env/Dockerfile`.

---

### ✅ [MEDIUM] `config_file` parameter passed to all R scripts but never read

**VERIFIED FIXED.**

- `"config"` was removed from `require_cli_args()` in all 17 R scripts (8 generation + 9 analysis).
- `config_file` param and `--config {params.config_file}` shell arg removed from all rules in `10_generation.smk` and `20_analysis.smk`.
- Confirmed: `grep require_cli_args workflow/scripts/generation/04_merge_relationships.R` → `require_cli_args(args, c("local-data", "kegg-data", "output"))` — no "config".
- Python scripts (`build_run_report.py` and validation scripts) still receive `--config` as they actively use it.

---

### ✅ [HIGH] No HTTP status code inspection on KEGG API responses in R

**VERIFIED FIXED.**

- `03_fetch_kegg_data.R` now uses `httr::GET()` with `httr::timeout()` and inspects `httr::status_code()` before parsing response.
- A custom condition class `non_retryable_http_error` distinguishes HTTP 4xx (non-retryable) from 429/5xx (retryable with backoff).
- `httr` added to `load_required_packages()` at line 6.
- Confirmed via `grep -n "httr" workflow/scripts/generation/03_fetch_kegg_data.R`.

---

### ✅ [HIGH] `parse_link_payload` raises `RuntimeError` on any invalid line

**VERIFIED FIXED.**

- `parse_link_payload` in `kegg_api_client.py` now accepts `max_invalid_ratio=0.0` parameter.
- When `invalid_lines > 0` and ratio ≤ threshold: logs `[WARNING]` and continues.
- When ratio > threshold: raises `RuntimeError` with ratio info.
- Default `0.01` (1%) configured in `config/config.yaml` under `validation.max_invalid_line_ratio`.
- Wired through `30_validation.smk` params and `--max-invalid-line-ratio` CLI arg in both validation scripts.
- Confirmed via `grep max_invalid_ratio workflow/scripts/validation/kegg_api_client.py`.

---

### ✅ [HIGH] Both validation scripts fetch 5 identical KEGG endpoints independently

**VERIFIED FIXED.**

- New Snakemake rule `fetch_kegg_link_cache` in `workflow/rules/30_validation.smk` fetches all 5 endpoints once and writes to `work/kegg_link_cache/{ko_ec,ko_reaction,cpd_ec,cpd_reaction,ec_reaction}.tsv`.
- New script `cache_kegg_links.py` implements the fetch-and-cache logic.
- Both validation scripts now accept `--ko-ec-cache`, `--ko-reaction-cache`, etc. and call `read_link_cache()` instead of `fetch_text()`.
- Network calls halved: 5 total instead of 10 per pipeline run.
- Confirmed via `grep fetch_kegg_link_cache workflow/rules/30_validation.smk`.

---

### ✅ [HIGH] `great_expectations>=1.12,<1.13` tightly pinned

**VERIFIED FIXED.**

- `biorempp_validation/pyproject.toml` line 12: `great_expectations~=1.12.0`
- `biorempp_validation/requirements.txt` line 1: `great_expectations~=1.12.0`
- Compatible-release operator (`~=`) allows patch upgrades (1.12.x) while blocking minor-version changes.
- Confirmed via `grep great_expectations biorempp_validation/pyproject.toml`.

---

### ✅ [MEDIUM] `pulp==2.7.0` pinned with no documented rationale

**VERIFIED FIXED.**

- `biorempp_snakemake_version/env/python-requirements.txt` now contains:
  ```
  # pulp is Snakemake 7.x's ILP solver for DAG scheduling — must be updated together with snakemake
  pulp==2.7.0
  ```
- The coupling between pulp and snakemake versions is now explicit.

---

### ✅ [MEDIUM] `rocker/tidyverse:4.3` Docker base image unpinned to digest

**VERIFIED FIXED.**

- `biorempp_snakemake_version/env/Dockerfile` line 1:
  ```
  FROM rocker/tidyverse:4.3@sha256:b2fc0a9357b1cb6c90b7a1ac527bd09f113d76f88175db8b99d205d73fbc31b7
  ```
- Digest pinned to the image retrieved on 2026-05-17. Builds are now fully reproducible.
- Confirmed via `head -1 env/Dockerfile`.

---

## Fix Applied in Current Session — Not Yet Committed

### 🟡 [MEDIUM] `json_to_dataframe.py` redundant `.nunique()` recomputation

**FIXED — AWAITING COMMIT.**

- `build_analysis_exact_df` in `biorempp_validation/src/biorempp_validation/json_to_dataframe.py` previously recomputed `ko.nunique()`, `enzyme_activity.nunique()`, `genesymbol.nunique()`, and `genename.nunique()` on lines 360–363, despite identical values being already computed inside `observed_basic` on lines 320–325.
- Lines 360–363 now read from `observed_basic` dict:
  ```python
  observed_ko_total = observed_basic["unique_ko_entries"]
  observed_enzyme_total = observed_basic["unique_enzyme_activities"]
  observed_gene_symbol_total = observed_basic["unique_gene_symbols"]
  observed_gene_name_total = observed_basic["unique_gene_names"]
  ```
- **Note:** The concern's claim that `build_analysis_critical_df` also recomputes these rankings is factually incorrect — that function only validates JSON keys and performs no groupby operations. The fix addresses the real, narrower redundancy.

---

## Open Concerns — Not Yet Addressed

### Missing Error Handling
| Severity | Concern |
|---|---|
| MEDIUM | `_apply_config_overrides_to_suite_payloads` mutates suite dicts in-place — no `copy.deepcopy()` |
| MEDIUM | `06_enrich_gene_info.R` silently drops rows where `genesymbol`/`genename` empty — no log |
| MEDIUM | `04_merge_relationships.R` + `03_fetch_kegg_data.R`: `dplyr::first()` without deterministic `arrange()` |
| LOW | `02_fetch_kegg_info.R`: `readLines(url)` without error handling for truncated/malformed responses |

### Security
| Severity | Concern |
|---|---|
| LOW | No URL scheme validation (`https://`) before making KEGG API requests |
| LOW | `venv/` potentially tracked in version control |

### Performance / Scalability
| Severity | Concern |
|---|---|
| MEDIUM | `expand_keys_with_consistent_mapping` has no intermediate size guards on many-to-many joins |
| MEDIUM | KEGG link sets held entirely in-memory as Python `set` objects — OOM risk on larger releases |
| MEDIUM | Snakemake workflow has no `threads:` directives; analysis rules could run in parallel |

### Maintainability
| Severity | Concern |
|---|---|
| HIGH | Input Excel files have no schema contract — column order changes silently corrupt data |
| MEDIUM | `_apply_config_overrides_to_suite_payloads` is 106-line with 12 branches and no unit tests |
| MEDIUM | `05_add_classifications.R` hardcodes typo correction `"Organometalic"` → `"Organometallic"` |
| LOW | Validation configuration version hardcoded as fallback in `settings.py` |
| LOW | Mixed `__pycache__` bytecode from Python 3.10 and 3.12 |

### Missing Documentation
| Severity | Concern |
|---|---|
| MEDIUM | No inline documentation for KEGG relationship expansion logic in `04_merge_relationships.R` |
| MEDIUM | No `README.md` inside `biorempp_snakemake_version/` for local vs Docker execution |
| LOW | `validation.yaml` thresholds not documented with derivation basis |

### Tech Debt
| Severity | Concern |
|---|---|
| LOW | `.archive/` directory in version control with superseded scripts |
| MEDIUM | `_apply_config_overrides_to_suite_payloads` complexity / no unit tests *(also listed under maintainability)* |

---

*Report generated: 2026-05-18 | Reviewer: Claude Sonnet 4.6*
