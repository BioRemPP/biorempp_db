# CONCERNS
_Last updated: 2026-05-31_

## Summary

The pipeline is structurally sound and well-validated: all previously identified critical issues around retry logic, hardcoded sentinels, and unsupported-key warnings have been resolved. The main remaining risks are (1) the complete absence of structural validation on the six Excel/TXT input files loaded by `01_load_local_data.R`, which can silently corrupt the database if a column is swapped or empty, (2) two stale hardcoded path strings in validation report JSON that still reference the old `work/` cache location, and (3) a cluster of medium-weight coupling issues where top-N values are baked into both R analysis scripts and the Python validation layer, making any future parameter change a multi-file update.

---

## Critical

**C1 — No structural validation on Excel/TXT input files (H5 from baseline — still open)**
- File: `biorempp_snakemake_version/workflow/scripts/generation/01_load_local_data.R` lines 19–74
- Description: `00_check_inputs.R` verifies only that the six required files exist (`REQUIRED_INPUT_FILES` list). `01_load_local_data.R` then loads them with `readxl::read_excel(col_names = FALSE)` and immediately assigns column names by position, without checking that the expected number of columns is present or that column content matches expected types/patterns. For example, `load_agency_compounds()` at line 26–30 blindly assigns `c("cpd", "referenceAG")` to whatever two columns exist; if the user delivers a three-column file or swaps columns, the wrong data silently flows downstream.
- Risk: A single corrupted or reordered input file corrupts the entire database without any pipeline error. The failure mode is silent: the pipeline completes successfully, but compound IDs and agency codes are swapped or truncated. This would only be caught much later in validation drift checks.
- Fix approach: After each `readxl::read_excel()` call, assert `ncol(data) == N`, check that the first column matches KEGG CPD/KO patterns using the existing `KEGG_VALUE_PATTERNS` from `io_contracts.R`, and `stop()` with a descriptive message if the check fails. Mirror the canonicalization approach used in `03_fetch_kegg_data.R` lines 128–248.

---

## High

**H1 — Stale hardcoded `work/kegg_link_cache/` path in validation report JSON**
- Files:
  - `biorempp_snakemake_version/workflow/scripts/validation/01_validate_keys_consistency_api.py` line 205
  - `biorempp_snakemake_version/workflow/scripts/validation/02_validate_links_groundtruth_policy_api.py` line 295
- Description: Both validation scripts write `"cache_source": "work/kegg_link_cache/"` as a literal string into the output JSON reports. The actual cache directory was moved to `cache/kegg_link_cache/` (concern M7 was resolved), so this string now misrepresents where the cache lives. The `--output-dir` argument passed to `cache_kegg_links.py` and the Snakemake rule `KEGG_LINK_CACHE_DIR = "cache/kegg_link_cache"` in `30_validation.smk` line 3 correctly use the new location. The generated reports contain auditing metadata that is factually wrong.
- Risk: Any tooling or human reviewer using the `cache_source` field to locate or verify cache files will be misled. If regression detection or audit tooling ever uses this path programmatically, it will look in the wrong directory.
- Fix approach: Replace the hardcoded string with a variable derived from the `--output-dir` argument already available in both scripts, or at minimum update the string literal to `"cache/kegg_link_cache/"`.

**H2 — Hardcoded KEGG API base URL in `07_metadata.R`**
- File: `biorempp_snakemake_version/workflow/scripts/analysis/07_metadata.R` line 323
- Description: The metadata script hardcodes `kegg_api = "https://rest.kegg.jp/"` directly in the output JSON schema block. The `base_url` is correctly passed via CLI argument and used for all actual API calls, but this hardcoded string in the metadata output will persist even if `config.yaml` is updated to point to a different URL (e.g., a mirror or local KEGG instance).
- Risk: Database metadata artifacts would contain an incorrect API URL, breaking auditability. The field is referenced by the validation layer in `json_to_dataframe.py` `build_analysis_exact_df()` for `metadata_kegg_exact_match`.
- Fix approach: Pass `--base-url` from the rule invocation (it is already defined in `config.yaml`) and substitute it in the `data_sources` dict rather than hardcoding the URL.

**H3 — `top_n` values are duplicated between R analysis scripts and Python validation layer**
- Files:
  - `biorempp_snakemake_version/workflow/scripts/analysis/02_compound_statistics.R` (uses `top_n` from CLI, emits key `top_20_compounds`)
  - `biorempp_snakemake_version/workflow/scripts/analysis/04_enzyme_statistics.R` (uses `top_n` from CLI, emits key `top_30_enzymes`)
  - `biorempp_snakemake_version/config/config.yaml` lines 27–30 (`top_n_compounds: 20`, `top_n_ko: 20`, `top_n_enzymes: 30`)
  - `biorempp_validation/src/biorempp_validation/json_to_dataframe.py` lines 387–390 (hardcodes `top_n=20`, `top_n=30`)
  - `biorempp_validation/src/biorempp_validation/json_to_dataframe.py` lines 52–62 (hardcodes key names `top_20_compounds`, `top_30_enzymes`)
- Description: The number 20 (for compounds, KO, genes) and 30 (for enzymes) appears in `config.yaml`, in the R analysis scripts' CLI-driven logic, and independently in `build_analysis_exact_df()` and `build_analysis_critical_df()` in the Python validation package. Changing `top_n_compounds` in `config.yaml` to 25 would change the JSON key emitted by the R script to `top_25_compounds`, breaking the Python validator which still looks for `top_20_compounds` by name.
- Risk: Any change to the top-N configuration parameters in `config.yaml` silently causes exact-match validation failures without a clear error message pointing to the config mismatch.
- Fix approach: Pass `top_n` values into `build_analysis_exact_df()` via the `ValidationSettings` object (which already reads `drift_thresholds` from `validation.yaml`). Add corresponding `top_n_compounds`, `top_n_ko`, `top_n_enzymes` fields to `validation.yaml` and wire them through `settings.py`.

---

## Medium

**M1 — `UNSUPPORTED_KEY_WARN_THRESHOLD` hardcoded in merge script, not configurable**
- File: `biorempp_snakemake_version/workflow/scripts/generation/04_merge_relationships.R` line 287
- Description: `UNSUPPORTED_KEY_WARN_THRESHOLD <- 5.0` is a module-level constant with no corresponding config entry. The warning at line 336 uses this literal. The value is meaningful (a 5% unsupported rate triggers a warning) but cannot be tuned without modifying source code.
- Risk: Low risk of silent data error, but operators cannot adjust strictness without editing R source. Mismatched with the configurable `max_invalid_line_ratio` pattern already established in `config.yaml` line 32.
- Fix approach: Add `unsupported_key_warn_threshold_pct: 5.0` under `validation:` in `config/config.yaml` and pass it to the script via a `--unsupported-threshold` CLI argument.

**M2 — `common_normalization.py` loads NA markers via relative path, breaks when CWD is not pipeline root**
- File: `biorempp_snakemake_version/workflow/scripts/validation/common_normalization.py` line 7
- Description: `NA_MARKERS_FILE = Path("workflow/lib/na_markers.txt")` is a relative path that is resolved against `os.getcwd()` at import time. The Snakemake shell commands run with the pipeline working directory set to `biorempp_snakemake_version/`, so the path resolves correctly in normal pipeline execution. However, if any validation script is invoked directly from a different directory (e.g., debugging, CI), the file silently fails to load and `load_na_markers()` falls back to the default set, potentially missing project-specific markers.
- Risk: NA normalization in validation scripts silently uses fewer markers than the R pipeline if the scripts are invoked outside the standard pipeline working directory. The mismatch could cause discrepancies between R-side and Python-side NA handling.
- Fix approach: Use `Path(__file__).parent.parent.parent / "lib" / "na_markers.txt"` (relative to the script file, not CWD), matching the pattern that would be robust to arbitrary invocation directories.

**M3 — `07_metadata.R` duplicates all five KEGG normalization functions already defined in `04_merge_relationships.R`**
- Files:
  - `biorempp_snakemake_version/workflow/scripts/analysis/07_metadata.R` lines 14–39 (`normalize_cpd`, `normalize_ko`, `normalize_ec`, `normalize_reaction`)
  - `biorempp_snakemake_version/workflow/scripts/generation/04_merge_relationships.R` lines 14–39 (identical functions)
- Description: Both scripts define identical or near-identical normalization functions. These functions are not sourced from a shared library; each file contains its own copy. Any fix or enhancement applied to one will not propagate to the other.
- Risk: If KEGG ever changes its ID format and the patterns in `io_contracts.R` `KEGG_VALUE_PATTERNS` are updated, these private copies in individual scripts may be missed.
- Fix approach: Move the normalization functions into `workflow/lib/utils.R` (or a dedicated `workflow/lib/normalization.R`) and source them. The `io_contracts.R` pattern constants are already centralized; the normalization functions should be too.

**M4 — Analysis scripts do not validate that the loaded CSV matches `EXPECTED_DATABASE_COLUMNS` before computing statistics**
- Files: `biorempp_snakemake_version/workflow/scripts/analysis/01_basic_statistics.R` through `09_merge_complete_analysis.R`
- Description: Each analysis script calls `read_database_csv()` and immediately accesses specific columns (e.g., `db$cpd`, `db$enzyme_activity`). There is no check that `colnames(db)` matches `EXPECTED_DATABASE_COLUMNS` from `io_contracts.R` before computing statistics. If a CSV is produced with a missing or renamed column, the script fails with an unhelpful error like `Error in '$': object of type 'NULL' is not subsettable` rather than a clear contract violation message.
- Risk: Hard-to-diagnose failures when the database schema changes but analysis scripts are not updated simultaneously.
- Fix approach: Add a guard at the top of each analysis script (or as a utility function in `utils.R`): `stopifnot("Database missing required columns" = all(EXPECTED_DATABASE_COLUMNS %in% colnames(db)))`.

---

## Low

**L1 — `.archive/V1.1.0/` is gitignored but still present locally; no deprecation notice in active code**
- Description: The `.archive/` directory is excluded from git via `.gitignore` but exists on disk with deprecated pipeline scripts from v1.0.0. The active `README.md` does not reference it. New contributors have no indication the directory exists or that its contents are historical.
- Risk: Very low — gitignored and unreachable in CI. Primarily a local developer confusion risk.
- Fix approach: Add a one-line comment to `biorempp_snakemake_version/README.md` noting that deprecated scripts are archived locally under `.archive/` and should not be used.

**L2 — Validation HTML summary page is minimal (no per-suite drill-down)**
- File: `biorempp_validation/src/biorempp_validation/run_validation.py` lines 237–252
- Description: `_write_summary_page()` produces a bare-bones HTML page with only four aggregate counts. Failures at the suite or expectation level are not surfaced. The raw JSON result files contain full detail but are not linked from the HTML.
- Risk: No functional risk. Purely a usability concern when reviewing validation outputs in a browser.
- Fix approach: Add links to `critical_checkpoint_result.json` and `warning_checkpoint_result.json` and a per-suite pass/fail table to the HTML output.

**L3 — `cache/kegg_link_cache/` TSV files have no freshness/staleness timestamp**
- File: `biorempp_snakemake_version/workflow/scripts/validation/cache_kegg_links.py`
- Description: The cache script writes raw TSV content to disk but does not record when each file was fetched. If a `cache/` file is left on disk from a previous run and Snakemake's output tracking is bypassed (e.g., `--rerun-triggers mtime`), the validation step uses stale KEGG data without any warning.
- Risk: Validation against outdated KEGG links is silent. The risk is low because Snakemake's DAG-based dependency tracking normally handles re-runs, but it becomes relevant when the cache is manually preserved across runs.
- Fix approach: Write a sidecar `{name}_meta.json` file alongside each TSV with `fetched_at_utc` and source URL, and have the validation scripts log this timestamp.

---

## Resolved (reference only)

The following concerns from the March 2026 baseline audit were fixed in branch `feat/database_update_ec_reaction`:

- **M5** — `nullable_columns` moved from hardcoded Python list to `validation.yaml` under `database_contract.nullable_columns`
- **M6** — Dockerfile `version` label updated to `1.1.0`
- **M7** — KEGG link cache directory moved from `work/kegg_link_cache/` to `cache/kegg_link_cache/` in `30_validation.smk`
- **L2** (original baseline ID) — `support_stage` provenance column added to `EXPECTED_DATABASE_COLUMNS` in `io_contracts.R` and exported in `07_extract_enzymes_export.R`
- **L5** — `httr 1.4.7` pinned in both `r-packages.txt` and the Dockerfile `RUN` block
- **L6** — `.archive/README.md` created locally (not committed; `.archive` is gitignored)

Additionally resolved since baseline (not previously tracked):
- **API retry logic** — Both R (`03_fetch_kegg_data.R`) and Python (`kegg_api_client.py`) now implement full exponential backoff with configurable env vars (`BIOREMPP_API_MAX_RETRIES`, `BIOREMPP_API_BACKOFF_BASE_SECONDS`, etc.); the old fixed `Sys.sleep(attempt)` pattern is gone.
- **Hardcoded validation sentinels** — The `C00230-K20218` / `C00038-K00001` hardcoded sentinel pairs referenced in the baseline are no longer present in `01_validate_keys_consistency_api.py`.
- **Inconsistent NA handling** — R and Python NA marker sets are both sourced from `workflow/lib/na_markers.txt`; Python uses `common_normalization.load_na_markers()` and R uses `utils.load_na_markers()`.
