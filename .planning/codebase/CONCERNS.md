# CONCERNS — BioRemPP DB 1.0.0

> Last mapped: 2026-05-31

---

## Summary

The pipeline is **functionally healthy** for its current dataset (~123 k rows, v1.1.0). All tests
pass and the Great Expectations validator is green under the default `strict_exact: true` mode.
However, five structural weaknesses stand out: (1) the GE validator is largely self-referential and
does not catch cross-run regression; (2) the fallback drift thresholds are an order of magnitude
below the real row count; (3) four primary analysis producers sort only by a single descending key,
making exact-match checks fragile under tie-order drift; (4) a mislabeled metadata sentinel
(`duplicate_full_rows`) reports 74 552 instead of 0, creating audit confusion; and (5) the GE
documentation still describes the old 8-column / v1.0.0 world. Below those "new" findings, the
original debt items from the March 2024 map are re-evaluated with current status.

---

## Critical Concerns

### C1 **FIXED** — `strict_exact` validator is self-referential — not a regression guard

- **File**: `biorempp_validation/src/biorempp_validation/run_validation.py:75-155`
- **Issue**: When `strict_exact: true` (the default), every numeric threshold — row count, unique
  compound count, unique KO count, unique gene symbol count, etc. — is **overwritten at runtime**
  using the same run's own `basic_statistics.json`, `compound_statistics.json`, and
  `ko_statistics.json`. The validator therefore always passes as long as the CSV and JSON produced
  by the same pipeline run are internally consistent.
- **Risk**: A materially changed pipeline (e.g., broken fallback logic, wrong join, KEGG API
  returning partial data) can still pass validation if both the CSV and the JSON are produced from
  the same broken run. There is no independent frozen baseline to detect cross-run regression.
- **Recommendation**: Decide the validator's purpose explicitly. If the goal is regression
  detection, add a frozen external baseline artifact (a reference JSON snapshot committed to the
  repo) and compare against it rather than the same run's outputs. If the goal is internal
  consistency only, document that clearly in the validation README. At minimum, add a human-readable
  note in `validation.yaml` explaining the self-referential behaviour.
- **Confidence**: HIGH (directly observed in `run_validation.py:75-155`)

### C2 **FIXED** — Fallback drift thresholds are an order of magnitude below current row count

- **File**: `biorempp_validation/config/validation.yaml:70-76`
- **Issue**: The `drift_thresholds` block sets `row_count: {min: 7000, max: 20000}`. The actual
  database now has **123 759 rows** (observed in `BASELINE_AUDIT_2026-05-31.md`). Setting
  `strict_exact: false` causes an immediate failure on the row-count expectation, making the
  non-strict mode completely unusable.
- **Risk**: Anyone toggling `strict_exact: false` (e.g., for development or pre-release runs) will
  see a false failure that obscures real drift signals. The fallback mode is broken.
- **Recommendation**: Update `drift_thresholds.row_count` to at minimum `{min: 100000, max: 150000}`
  to reflect the current scale. Widen similarly for `unique_ko`, `unique_genesymbol`,
  `unique_genename`. Re-calibrate after every major version bump.
- **Confidence**: HIGH (baseline audit contraprova confirmed failure)

---

## High Concerns

### H1 **FIXED** — Four analysis producers sort by single key — exact-match checks fragile on ties

- **Files**:
  - `biorempp_snakemake_version/workflow/scripts/analysis/02_compound_statistics.R:23-27`
  - `biorempp_snakemake_version/workflow/scripts/analysis/03_ko_statistics.R:13-22`
  - `biorempp_snakemake_version/workflow/scripts/analysis/04_enzyme_statistics.R:13-23`
  - `biorempp_snakemake_version/workflow/scripts/analysis/05_gene_statistics.R:12-24`
  - `biorempp_snakemake_version/workflow/scripts/analysis/06_crosstab_statistics.R:12-28`
- **Issue**: All five R producers sort only by `desc(frequency)` or `desc(count)` with no secondary
  tie-breaker. The Python exact recomputation in
  `biorempp_validation/src/biorempp_validation/json_to_dataframe.py:154-274` adds deterministic
  secondary sorts (`cpd asc`, `ko asc`, `enzyme_activity asc`, etc.). When two rows share the same
  frequency, the order can differ between R and Python depending on the runtime's internal hash or
  sort stability.
- **Risk**: Future pipeline runs on a different R version, OS, or with slightly different data can
  fail the exact-match check purely due to tie-order without any semantic change in the data.
  Currently the dataset passes; the risk is latent.
- **Recommendation**: Add explicit secondary `arrange()` keys in each producer:
  - `02_compound_statistics.R`: `arrange(desc(frequency), cpd)`
  - `03_ko_statistics.R`: `arrange(desc(frequency), ko)`
  - `04_enzyme_statistics.R`: `arrange(desc(frequency), enzyme_activity)`
  - `05_gene_statistics.R`: add `genesymbol` and `genename` secondary keys
  - `06_crosstab_statistics.R`: add lexical secondary keys matching Python recomputation
- **Confidence**: HIGH (directly observed in code; confirmed by baseline audit F5)

### H2 **FIXED** — GE validator does not cover three first-class pipeline outputs

- **Files**:
  - `biorempp_validation/config/validation.yaml:20-31` (required_files list)
  - `biorempp_snakemake_version/Snakefile:33-41` (all rule outputs)
- **Issue**: The Snakemake `all` rule treats `metadata/keys_consistency_report.json`,
  `metadata/links_groundtruth_policy_report.json`, and `reports/workflow_summary.json` as required
  outputs. The GE validator's `required_files` list does not include any of them. Removing all three
  files still results in a green validation run (confirmed by baseline audit contraprova).
- **Risk**: Silent regression in KEGG coverage reports, policy enforcement results, and run
  provenance goes undetected by the validation layer. Users can receive a "passed" badge for a
  release that is missing key validation evidence.
- **Recommendation**: Add the three missing files to `required_files` in `validation.yaml`. Create
  lightweight GE suites or custom checks:
  - `keys_consistency_report.json`: assert `all_remaining_na_justified == true`
  - `links_groundtruth_policy_report.json`: assert `policy_union_rate_percent == 100.0`
  - `workflow_summary.json`: assert hashes present and counts consistent with metadata
- **Confidence**: HIGH (contraprova confirmed)

### H3 — `duplicate_full_rows` metadata sentinel is mislabeled

- **File**: `biorempp_snakemake_version/workflow/scripts/analysis/07_metadata.R:254`
- **Issue**: `duplicate_full_rows` is computed as
  `nrow(db_norm) - nrow(dplyr::distinct(db_norm))` where `db_norm` is a 5-column reduced subset
  (`cpd, ko, ec, reaction, reaction_description`), not the full 11-column exported schema. The
  result is 74 552 for the current dataset, while the actual full-row duplicate count in the final
  CSV is 0.
- **Risk**: Anyone reading the metadata JSON — including downstream tools, automated reports, or
  data consumers — will misinterpret `duplicate_full_rows: 74552` as a data quality failure.
  Misleading metadata in a database release undermines trust.
- **Recommendation**: Either rename the field to `duplicate_link_signature_rows` (or similar) to
  reflect the actual computation, or recompute it on the full 11-column schema. Add a comment in
  `07_metadata.R` explaining the reduced subset used.
- **Confidence**: HIGH (directly observed in code + baseline audit F6)

### H4 — Silent data loss at each join boundary — no per-stage discard logging

- **File**: `biorempp_snakemake_version/workflow/scripts/generation/04_merge_relationships.R:174-254`
- **Issue**: The 6-stage fallback chain (`dense → fallback_dense → compound_bridge_dense →
  ec_only → reaction_only → unsupported`) uses `anti_join` to compute residuals at each stage.
  The final `log_message` at line 279-297 logs per-stage row counts but does **not** report how
  many rows entered each stage or what fraction was lost at each boundary.
- **Risk**: If KEGG changes its link table structure or a bug causes early stages to incorrectly
  classify rows, the silent inflation of `unsupported_rows` or deflation of `dense_rows` will not
  generate any warning. Users see only the final merged count.
- **Recommendation**: Add pre-join row counts and per-stage discard percentages to the log message.
  Optionally, add a configurable threshold that raises a warning if `unsupported_rows / total_keys`
  exceeds a ceiling (e.g., 5%). Consider adding a `completeness_stage` column to the intermediate
  RDS to preserve lineage.
- **Confidence**: HIGH (directly observed)

### H5 — Input Excel files have no structural validation

- **File**: `biorempp_snakemake_version/workflow/scripts/generation/01_load_local_data.R:19-74`
- **Issue**: All Excel loaders (`load_kegg_compounds`, `load_agency_compounds`,
  `load_curated_compounds`, `load_compound_classes`) call `readxl::read_excel` and immediately
  assign column names without checking row count, column count, or data types. Contrast with
  `03_fetch_kegg_data.R` which uses `canonicalize_link_endpoint()` to fully validate structure and
  orientation before accepting data.
- **Risk**: A swapped column in `compostos_todasagencias.xlsx` (e.g., agency name in the first
  column, CPD in the second) would silently load with reversed semantics, corrupting the entire
  database without an error message. Similarly, an empty file or sheet would propagate through the
  pipeline with only a late-stage cryptic error.
- **Recommendation**: Apply the same structural validation pattern from `03_fetch_kegg_data.R` to
  each local file loader: assert minimum row/column count, validate column value patterns (CPD
  regex, agency name not empty), and fail fast with a descriptive error.
- **Confidence**: HIGH (directly observed)

---

## Medium Concerns

### M1 — Documentation describes old v1.0.0 / 8-column contract

- **Files**:
  - `docs/validation-gx/data-contracts.md:11-35` and `:136-163`
  - `docs/validation-gx/expectation-suites.md:23-48` and `:84-105`
  - `biorempp_validation/README.md` (multiple sections)
- **Issue**: Documentation still references `biorempp_database_v1.0.0.csv`, an 8-column schema,
  and states that all missing values must be zero. The runtime overrides in
  `run_validation.py:61-73` compensate silently, so the code works — but users and contributors
  reading the docs get the wrong contract.
- **Risk**: Contributor confusion, incorrect data contracts in publications or downstream tools,
  erroneous expectation that `ec` and `reaction` must always be non-null.
- **Recommendation**: Update all documentation to v1.1.0 and the 11-column schema. Explicitly
  document that `ec` and `reaction` can be NA under the justified-NA policy. Remove references to
  `v1.0.0.csv`.
- **Confidence**: HIGH (directly observed in baseline audit F4)

### M2 — GE expectation suite JSON still contains old 8-column declaration

- **Files**:
  - `biorempp_validation/great_expectations/expectations/database_critical.json:5-16`
  - `biorempp_validation/great_expectations/expectations/analysis_json_critical.json:121-127`
- **Issue**: The static JSON suite files still declare 8 columns. The runtime overrides in
  `run_validation.py:61-73` patch them before execution. The code works, but the source-of-truth
  artifacts are stale — a static analysis tool or future refactor could break the override chain.
- **Risk**: If the runtime override logic is ever removed or refactored incorrectly, the validator
  silently uses the wrong column count without any warning.
- **Recommendation**: Update both JSON suite files to the current 11-column contract so the
  override becomes a safety net rather than the only correct path.
- **Confidence**: HIGH (directly observed)

### M3 — `generate_data_docs: true` produces only a placeholder HTML file

- **File**: `biorempp_validation/src/biorempp_validation/run_validation.py:208-224`
- **Issue**: The `generate_data_docs` flag writes a minimal hand-crafted placeholder page, not
  real Great Expectations Data Docs. Users enabling this flag expect GX-generated interactive HTML
  documentation.
- **Risk**: Feature name mismatch creates incorrect expectations for users and CI consumers.
- **Recommendation**: Either implement actual GX Data Docs generation, or rename the flag to
  something like `generate_summary_page` and update the docs to reflect what is actually produced.
- **Confidence**: HIGH (directly observed in baseline audit F7)

### M4 — Compound name deduplication uses `first()` without stable ordering

- **File**: `biorempp_snakemake_version/workflow/scripts/generation/04_merge_relationships.R:256-268`
- **Issue**: `add_compound_names()` groups by `cpd` and uses `dplyr::first(compoundname)` to
  deduplicate names. `first()` returns the first row in the current group order, which is not
  guaranteed to be stable across dplyr versions or re-runs unless the data is pre-sorted.
- **Risk**: Compound names can change between pipeline re-runs if the input data or dplyr version
  changes, leading to different names for the same CPD with no warning.
- **Recommendation**: Add an explicit `dplyr::arrange(cpd, compoundname)` before the
  `group_by/summarise` step in `add_compound_names()` to ensure deterministic name selection.
- **Confidence**: HIGH (directly observed)

### M5 — `base_all_missing_values_zero` check incorrectly flags justified NAs as failures

- **File**: `biorempp_validation/src/biorempp_validation/json_to_dataframe.py:40-44`
- **Issue**: `all_missing_zero` is computed over all columns except `ec`, `reaction`, and
  `reaction_description`. However, `basic_statistics.json` reports non-zero missing counts for
  `ec` (961) and `reaction` (2223). The check passes today only because those three columns are
  hardcoded into the `optional_na_columns` set. If a new justified-NA column is added, it must
  be manually added to this set or the check will fail.
- **Risk**: Brittle hardcoded allowlist. Adding a new optional column (e.g., a future
  `pathway` column that is sometimes NA) will silently fail the critical check.
- **Recommendation**: Drive the optional-NA column list from `validation.yaml` (e.g., a
  `nullable_columns` list) rather than hardcoding it in the Python source.
- **Confidence**: HIGH (directly observed)

### M6 — `Dockerfile` LABEL `version` is hardcoded as `1.0.0` while pipeline is at `1.1.0`

- **File**: `biorempp_snakemake_version/env/Dockerfile:6`
- **Issue**: `LABEL version="1.0.0"` does not match the current pipeline version `1.1.0` in
  `config/config.yaml:1`. The image label is cosmetic but misleading.
- **Risk**: Anyone pulling the Docker image and checking its label will see the wrong version.
  CI/CD pipelines that parse image labels for versioning will get incorrect metadata.
- **Recommendation**: Update `LABEL version` to `1.1.0` and consider driving it from
  `config/config.yaml` via a build argument.
- **Confidence**: HIGH (directly observed)

### M7 — KEGG link cache is stored inside `work/` and may be re-fetched unnecessarily

- **File**: `biorempp_snakemake_version/workflow/rules/30_validation.smk:3-36`
- **Issue**: The shared `fetch_kegg_link_cache` rule writes all 5 KEGG link TSVs to
  `work/kegg_link_cache/`. The `work/` directory is the intermediate scratch space for the
  pipeline. Nothing prevents the cache from being cleaned by `snakemake --delete-all-output` or
  a developer clearing the work directory.
- **Risk**: Each full re-run re-fetches 5 full KEGG link tables sequentially, adding several
  minutes and network dependency to every validation run.
- **Recommendation**: Move the link cache to `results/metadata/kegg_link_cache/` or a dedicated
  `cache/` directory that is excluded from routine cleanup. Document the cache lifetime and
  staleness policy.
- **Confidence**: HIGH (directly observed)

---

## Low Concerns

### L1 — No incremental database updates — full regeneration required on any change

- **File**: `biorempp_snakemake_version/Snakefile` (entire pipeline DAG)
- **Issue**: Every pipeline run regenerates the complete database from scratch, including 7 KEGG
  HTTP fetches. There is no mechanism to update only the rows affected by a source change.
- **Risk**: High operational cost for frequent updates (new KEGG release, new agency file).
  Pipeline takes significant wall time even for minor source changes.
- **Recommendation**: Implement change-tracking. Store previous KEGG snapshots and compute diffs
  using Snakemake's checkpoint mechanism. Consider making KEGG fetch rules conditional on a
  configurable cache age.
- **Confidence**: MEDIUM (inferred from pipeline structure)

### L2 — No user-visible data provenance column in the exported CSV

- **File**: `biorempp_snakemake_version/workflow/scripts/generation/04_merge_relationships.R:233-241`
- **Issue**: Rows pass through 6 fallback stages before export, but the exported CSV contains no
  column indicating which stage produced each row. Users cannot distinguish a
  `dense` (high-confidence, both EC and reaction) row from an `unsupported` (no KEGG mapping
  found) row.
- **Risk**: Downstream analyses treat all rows equally. Studies based on `unsupported` rows may
  draw unsupported conclusions without realising the data confidence difference.
- **Recommendation**: Add a `support_stage` or `completeness_level` column to the exported CSV
  and XLSX. Values: `dense`, `fallback_dense`, `compound_bridge`, `ec_only`,
  `reaction_only`, `unsupported`.
- **Confidence**: MEDIUM (inferred from pipeline design)

### L3 — Analysis scripts re-derive normalization functions already in `utils.R`

- **File**: `biorempp_snakemake_version/workflow/scripts/analysis/07_metadata.R:14-39`
- **Issue**: `07_metadata.R` re-implements `normalize_cpd`, `normalize_ko`, `normalize_ec`, and
  `normalize_reaction` locally, identical to the implementations in
  `04_merge_relationships.R:14-39`. The shared library `utils.R` provides NA handling but not
  these ID normalizers.
- **Risk**: If the normalization logic ever needs updating (e.g., KEGG changes ID format), it must
  be changed in multiple places with no compiler enforcing consistency.
- **Recommendation**: Move the four normalizer functions into `workflow/lib/utils.R` or a new
  `workflow/lib/kegg_normalizers.R` and source that file from both `04_merge_relationships.R` and
  `07_metadata.R`.
- **Confidence**: HIGH (directly observed)

### L4 — RDS intermediate format is R-only; limits future language interoperability

- **Files**: All generation scripts use `saveRDS()` / `readRDS()` for intermediate data
- **Issue**: Intermediate pipeline data (`local_data.rds`, `kegg_data.rds`, `merged_compounds.rds`,
  `classified_compounds.rds`, `enriched_compounds.rds`) are stored in R's native binary format.
  Python scripts cannot read them directly.
- **Risk**: Future pipeline changes that add a Python rule in the generation layer would require
  an R-to-Python conversion step. RDS is also inefficient for large datasets (no column pruning,
  no zero-copy reads).
- **Recommendation**: Not urgent at current scale (~10k rows, fast R serialization). Consider
  migrating to Apache Arrow/Parquet if datasets scale beyond 100k rows or if Python generation
  rules are added.
- **Confidence**: MEDIUM (inferred from scale projection)

### L5 — `httr` R package used for KEGG fetch but not listed in `r-packages.txt`

- **File**:
  - `biorempp_snakemake_version/workflow/scripts/generation/03_fetch_kegg_data.R:6`
  - `biorempp_snakemake_version/env/r-packages.txt`
- **Issue**: `03_fetch_kegg_data.R` loads `httr` (`load_required_packages(c("httr", "stringr"))`),
  but `httr` does not appear in `r-packages.txt` or the Dockerfile `install_version` block. It is
  available as a transitive dependency of `readxl` or the rocker base image but is not explicitly
  pinned.
- **Risk**: A future base image update that drops `httr` (e.g., if the rocker image migrates to
  `httr2`) will break the KEGG fetch silently at runtime.
- **Recommendation**: Add `httr` with a pinned version to `r-packages.txt` and the Dockerfile
  `install_version` block.
- **Confidence**: HIGH (directly observed)

### L6 — `.archive/` directory committed to git contains deprecated scripts without deprecation markers

- **Files**: `.archive/V1.1.0/` and `.archive/.planning/`
- **Issue**: The `.archive/` directory contains old validation scripts (e.g.,
  `.archive/V1.1.0/na_compliance_audit.py`, `validate_keys_consistency.py`) and outdated pipeline
  docs. There are no deprecation markers in the active codebase pointing to this directory, so
  developers may accidentally run or reference these scripts.
- **Risk**: Maintainer confusion, potential for accidental use of outdated pipeline logic.
- **Recommendation**: Add a `DEPRECATED.md` or `README.md` at the root of `.archive/` clearly
  stating the directory is historical only. Consider adding a CI check that prevents scripts from
  `.archive/` being imported.
- **Confidence**: HIGH (directly observed)

---

## Resolved / Previously Known

The following items were identified in the prior codebase map (2026-03-24) and have been addressed
in subsequent commits (`b046de5`, `0a3a2f6`, `d99fee3`, `15f620c`, `73ffbbd`, `7747b2e`):

| Prior Item | Resolution | Commit(s) |
|---|---|---|
| API retry with fixed linear backoff (`Sys.sleep(attempt)`) | Replaced with exponential backoff + jitter in both R and Python; configurable via env vars | `0a3a2f6` |
| Hardcoded sentinel cpd-ko pairs in validation | Removed; validation now uses KEGG link cache without hardcoded sentinels | `b046de5`, `d99fee3` |
| Validation scripts fetch all endpoints sequentially (blocking I/O) | Replaced by shared `fetch_kegg_link_cache` Snakemake rule that runs once and caches all 5 endpoints to disk | `15f620c` |
| Monolithic Python validation scripts (365 / 455 lines, one file) | Refactored into `kegg_api_client.py` and `common_normalization.py` shared modules | `d99fee3` |
| R packages unpinned in Dockerfile | All 7 R packages now pinned via `remotes::install_version()` | `d99fee3`, `73ffbbd` |
| `read.delim(url)` direct URL reads in `03_fetch_kegg_data.R` | Replaced with `httr::GET()` for proper HTTP error handling and retry support | `ef57a8e` |
| Redundant `nunique()` recomputation in `build_analysis_exact_df` | Removed dead recomputation | `7747b2e` |
| Snakemake pinned to 7.32.4 with Python 3.10 base | Upgraded to Snakemake 8.30.0 with Python 3.12 base | `4a2dac7` |

---

## Hardcoded Values That Should Be Config

| Value | Location | Recommendation |
|---|---|---|
| `top_n_compounds: 20`, `top_n_ko: 20`, `top_n_enzymes: 30` | `config/config.yaml:27-29` | Already in config — confirm analysis scripts consume these values correctly |
| `200` (max incorrect examples) | `01_validate_keys_consistency_api.py:128` | Make configurable in `validation.yaml` |
| `50` (max false_na_pairs examples in metadata) | `07_metadata.R:287` | Make configurable in `config.yaml` analysis section |
| `"Organometalic"` → `"Organometallic"` typo fix | `05_add_classifications.R:19` | Move to a lookup table in config or input data rather than hardcoded string replacement |
| `optional_na_columns = {"ec", "reaction", "reaction_description"}` | `json_to_dataframe.py:29` | Drive from `validation.yaml` nullable_columns list |

---

## Missing Error Handling in Critical Paths

| Location | Missing Handling |
|---|---|
| `01_load_local_data.R:20-65` — all `readxl::read_excel()` calls | No column count or data type validation; no check that the sheet is non-empty |
| `05_add_classifications.R:15-26` — `tidyr::separate_rows()` on `compoundclass` | If `compoundclass` column is missing or wrongly named in the Excel file, produces a silent empty result |
| `06_enrich_gene_info.R:27-36` — `dplyr::left_join()` then immediate filter for non-NA gene info | KOs that do not appear in `kegglistko.txt` are silently dropped with no warning or count log |
| `cache_kegg_links.py:44-48` — sequential fetches with no individual retry abort control | A single failed endpoint aborts all subsequent fetches; no partial-success recovery |

---

## Performance Bottlenecks

| Area | Issue | Impact | Path |
|---|---|---|---|
| Many-to-many joins in `04_merge_relationships.R:101-172` | Full Cartesian products before filtering; a compound with 100 KOs and 50 reactions generates 5 000 intermediate rows | Manageable at current scale (~384 compounds, ~1 543 KOs); could hit RAM limits at 10× scale | Pre-aggregate source tables; use `many-to-one` joins where directionality is known |
| Loading full `kegg_data.rds` in `07_metadata.R` and `07_extract_enzymes_export.R` | Both scripts load the full kegg_data bundle including all link tables for normalization lookups | Doubled memory peak at export stage | Extract only the needed link tables in a helper; avoid loading full bundle just for reaction descriptions |
| All 9 analysis scripts read the full CSV independently | Each of the 9 analysis rules re-reads the 123 k-row CSV from disk | 9× I/O overhead on shared filesystems | Pipeline already parallelises these; acceptable at current size; review if CSV grows >10 MB |

---

*Concerns audit: 2026-05-31*
