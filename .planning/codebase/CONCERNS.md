# Codebase Concerns

**Analysis Date:** 2026-03-24

## Tech Debt

**Data Loss via Inner Joins:**
- Issue: Multiple cascading `inner_join()` operations in `04_merge_relationships.R` aggressively filter data, potentially losing valid relationships that don't meet all join conditions. Lines 103-104, 109-110, 158-162 use chained `inner_join()` with `relationship = "many-to-many"` that silently exclude unmatched rows without logging how many rows were discarded.
- Files: `biorempp_snakemake_version/workflow/scripts/generation/04_merge_relationships.R` (lines 101-240)
- Impact: Compounds, KOs, or relationships that exist in one endpoint but not all may be silently dropped from the database without user visibility. The logging at line 279-297 shows row counts but doesn't correlate to input sizes.
- Fix approach: Add pre-join row counts and log discards at each join stage. Consider using `left_join()` with explicit filtering for cases where missing data should be allowed.

**Inconsistent Data Quality Checks Across Input Types:**
- Issue: `01_load_local_data.R` does minimal validation on loaded Excel files (lines 19-43). It checks file existence but not data structure (column count, data types, non-empty content). By contrast, `03_fetch_kegg_data.R` has extensive validation. The gap creates risk if input files are corrupted.
- Files: `biorempp_snakemake_version/workflow/scripts/generation/01_load_local_data.R` (lines 19-74), `biorempp_snakemake_version/workflow/scripts/generation/03_fetch_kegg_data.R` (lines 59-162)
- Impact: Malformed input files may produce cryptic downstream errors or silent data loss. An agency file with swapped columns would load without error, corrupting the database.
- Fix approach: Apply canonical validation patterns from `03_fetch_kegg_data.R` to all loaders in `01_load_local_data.R`. Validate column counts, data types, and non-empty requirements for each file.

**Silent Fallback Mechanisms Without Visibility:**
- Issue: `04_merge_relationships.R` implements a 6-stage fallback chain (lines 174-254): dense → fallback_dense → compound_bridge_dense → partial_ec → partial_reaction → unsupported. Each stage silently feeds residuals to the next. No warning when rows proceed through fallbacks—users see only final counts, not which rows degraded.
- Files: `biorempp_snakemake_version/workflow/scripts/generation/04_merge_relationships.R` (lines 174-254)
- Impact: Database quality degrades silently. A row that reaches "partial_ec_rows" (only EC, no reaction) passes through without indicating data loss. Users cannot distinguish high-confidence from fallback entries in downstream analysis.
- Fix approach: Add a "completeness_level" or "confidence_score" column to mark which fallback stage each row passed through. Log per-stage statistics and add output metrics.

**Unversioned Archive Directory:**
- Issue: `.archive/V1.1.0/` directory contains deprecated scripts from previous pipeline versions but is committed to git. No clear deprecation markers in active codebase pointing to this. Risk that someone runs old scripts thinking they're current.
- Files: `.archive/V1.1.0/` (contains legacy validation scripts)
- Impact: Maintainer confusion, potential for accidental use of outdated pipeline logic.
- Fix approach: Add a deprecated notice in README. Consider moving archive entirely outside repo or creating a separate archive tag/branch.

## Known Bugs

**API Retry Logic with Fixed Backoff:**
- Symptoms: Network failures during KEGG API fetches hang for extended periods with predictable sleep times (`Sys.sleep(attempt)` in R, `time.sleep(attempt)` in Python).
- Files: `biorempp_snakemake_version/workflow/scripts/generation/03_fetch_kegg_data.R` (line 34), `biorempp_snakemake_version/workflow/scripts/validation/01_validate_keys_consistency_api.py` (line 50), `biorempp_snakemake_version/workflow/scripts/validation/02_validate_links_groundtruth_policy_api.py` (line 50)
- Trigger: Any network timeout or connection reset during KEGG API fetch. With 3 retries and 1-2-3 second sleeps, total wait is ~6 seconds before failure. If running on unstable network (VPN, proxy), this is insufficient.
- Workaround: Run in Docker environment with stable network; consider increasing max_retries to 5+ for production.

**Hardcoded Sentinel Cases in Validation:**
- Symptoms: Validation report includes hardcoded sentinel checks for only two specific cpd-ko pairs: `C00230-K20218` and `C00038-K00001` (line 353-355 in `01_validate_keys_consistency_api.py`). If these don't exist in current database, script silently continues with empty results.
- Files: `biorempp_snakemake_version/workflow/scripts/validation/01_validate_keys_consistency_api.py` (lines 352-356)
- Trigger: Database regeneration with different source data where these pairs don't exist.
- Workaround: Query the database first to select actual sentinel pairs, or make sentinels configurable via config file.

**Inconsistent NA/Missing Value Handling:**
- Symptoms: Multiple functions normalize NA values differently. Python uses a set of string markers (`NA_MARKERS = {"", "NA", "NAN", "<NA>", "NONE", "NULL"}`) while R filters with `is.na()` + trimmed string comparison. Leading to inconsistent behavior when spreadsheet contains variants like "na" vs "NA".
- Files: `biorempp_snakemake_version/workflow/scripts/validation/01_validate_keys_consistency_api.py` (line 15), `biorempp_snakemake_version/workflow/scripts/generation/04_merge_relationships.R` (lines 14-39), `biorempp_snakemake_version/workflow/scripts/analysis/07_metadata.R` (lines 14-38)
- Trigger: Input data with lowercase "na" or other variants.
- Workaround: Standardize NA_MARKERS definition across all scripts in a shared config or create a centralized normalization library.

## Security Considerations

**Unvalidated KEGG API URL in Configuration:**
- Risk: Base URL is hardcoded in `config/config.yaml` as `https://rest.kegg.jp`. If config is loaded from untrusted source or modified, could redirect API calls to malicious endpoint capturing database credentials or injecting data.
- Files: `biorempp_snakemake_version/config/config.yaml` (line 14), used throughout generation and validation scripts
- Current mitigation: HTTPS enforced in config, URL is public KEGG service.
- Recommendations: Add URL validation regex check in preflight rule to ensure only approved KEGG domains are used. Log all API endpoints called during pipeline. Consider pinning to specific KEGG server IPs if possible.

**No Authentication for KEGG API:**
- Risk: All KEGG API calls are unauthenticated, rate-limited only by KEGG's public quotas (10 requests/sec). If KEGG account is compromised or rate limits change, pipeline can be disrupted. No API key rotation mechanism.
- Files: All fetch/validation scripts lack authentication parameters
- Current mitigation: Public API endpoints only; KEGG provides free access.
- Recommendations: If moving to KEGG's commercial/authenticated service, implement secure key storage (environment variables, secrets manager). Add request throttling and rate-limit detection.

**CSV Output Contains No Integrity Verification:**
- Risk: Database CSV is exported without checksums or signatures. Users cannot verify data integrity after download or detect tampering.
- Files: `biorempp_snakemake_version/workflow/scripts/generation/07_extract_enzymes_export.R`, `biorempp_snakemake_version/workflow/rules/90_reporting.smk`
- Current mitigation: SHA-256 checksums computed in reporting (line 90_reporting.smk), but not embedded in CSV headers.
- Recommendations: Include row-count and column-count metadata as CSV comments. Publish checksums alongside database on distribution site. Consider GPG signing release artifacts.

## Performance Bottlenecks

**Inefficient Cartesian Products in Data Merging:**
- Problem: `04_merge_relationships.R` uses `relationship = "many-to-many"` joins extensively (lines 103, 109, 160, etc.), which compute full Cartesian products before filtering. If a single compound links to 100 KOs and 50 reactions, join produces 5,000 intermediate rows before deduplication.
- Files: `biorempp_snakemake_version/workflow/scripts/generation/04_merge_relationships.R` (lines 101-240)
- Cause: dplyr's `inner_join()` with `relationship = "many-to-many"` is designed for flexibility but is inefficient for large fanout ratios.
- Improvement path: Pre-aggregate source tables before joins. Filter to relevant compound/KO subsets first. Use `relationship = "many-to-one"` where directionality is known. Monitor peak memory usage with large datasets.

**Validation Scripts Fetch All Endpoints Sequentially:**
- Problem: `01_validate_keys_consistency_api.py` and `02_validate_links_groundtruth_policy_api.py` make 5 sequential HTTP calls to KEGG (lines 299-309 in validation/01). Each call waits for response before next. With 60-second timeout and 3 retries, worst case is 15 minutes if network is slow.
- Files: `biorempp_snakemake_version/workflow/scripts/validation/01_validate_keys_consistency_api.py` (lines 299-309), `workflow/scripts/validation/02_validate_links_groundtruth_policy_api.py`
- Cause: No parallel HTTP request library used; blocking I/O.
- Improvement path: Use `concurrent.futures` or `aiohttp` for parallel endpoint fetches. Cache responses to disk to skip refetch if pipeline re-runs. Implement connection pooling.

**RDS Serialization for Large Intermediate Data:**
- Problem: All intermediate pipeline data (kegg_data.rds, merged_compounds.rds) are serialized as RDS format, which is R-specific and may be inefficient for large datasets (10k+ rows). Each rule reads/writes full RDS files.
- Files: All generation scripts use `saveRDS()` and `readRDS()`
- Cause: RDS is convenient but adds serialization overhead; parquet or arrow would be faster.
- Improvement path: Consider switching to Apache Arrow or Parquet for intermediate storage if datasets scale beyond 100k rows. Benchmark serialization times.

## Fragile Areas

**Compound-Bridge Fallback Logic (Complex Multi-Stage Join Chain):**
- Files: `biorempp_snakemake_version/workflow/scripts/generation/04_merge_relationships.R` (lines 157-172)
- Why fragile: `build_compound_bridge_dense()` uses nested `inner_join()` chains to cross-reference compounds across EC and reaction links. The logic is correct but difficult to trace. A single change to join order or filter logic could silently corrupt results.
- Safe modification: Add detailed unit tests for this function with known input/output pairs. Add intermediate assertions checking row counts at each join step. Document join intent (why this order, what's being excluded).
- Test coverage: No unit tests currently exist for this function. Function is tested only by final database smoke tests.

**KEGG Value Pattern Validation:**
- Files: `biorempp_snakemake_version/workflow/lib/io_contracts.R` (lines 34-39), used in `03_fetch_kegg_data.R` (lines 47-149)
- Why fragile: Regex patterns for KEGG IDs are hardcoded and must match exactly. Pattern for EC: `^(ec:)?[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9A-Za-z\\-]+$` allows hyphens and letters in last segment, matching KEGG's wildcard notation (e.g., "1.1.1.-"). If KEGG ever changes ID format, validation will fail cryptically.
- Safe modification: Parameterize patterns in config file. Add validation tests comparing patterns against live KEGG response samples. Create version-specific pattern sets.
- Test coverage: Patterns tested only implicitly through integration tests. No unit tests for pattern validity.

**Analysis Rule Dependencies (Linear Chain):**
- Files: `biorempp_snakemake_version/workflow/rules/20_analysis.smk` - all 9 analysis rules depend on single merged_compounds.rds
- Why fragile: If any single analysis script fails (e.g., basic_statistics.R), the entire analysis batch is marked as failed and `09_merge_complete_analysis.R` cannot proceed. No graceful degradation to produce partial reports.
- Safe modification: Add error handling in each analysis script to write empty/stub outputs on failure, allowing pipeline to continue. Add a validation rule that checks all analysis outputs exist before merging.
- Test coverage: Only full integration tests exist. No unit tests for individual analysis scripts.

**Monolithic Python Validation Scripts:**
- Files: `biorempp_snakemake_version/workflow/scripts/validation/01_validate_keys_consistency_api.py` (365 lines), `02_validate_links_groundtruth_policy_api.py` (455 lines)
- Why fragile: Both scripts are single Python files with multiple responsibilities: API fetching, data loading, parsing, analysis, JSON report generation. High cyclomatic complexity in analysis loops (lines 139-263 in 01_validate_keys_consistency_api.py). Difficult to unit test or modify without side effects.
- Safe modification: Refactor into modules: api_client.py, csv_loader.py, link_parser.py, consistency_analyzer.py. Test each module independently.
- Test coverage: Only full integration tests. No unit tests for parser, analyzer, or API client functions.

## Scaling Limits

**In-Memory Data Consolidation:**
- Current capacity: Pipeline handles ~10k database rows (current v1.0.0 size) comfortably in R/Python memory.
- Limit: When compounds scale to 500+ with 5,000+ KOs, Cartesian products in join chains will exceed available RAM on typical machines (~4GB). Intermediate kegg_data.rds alone could reach 500MB.
- Scaling path: Implement chunked processing for large datasets. Use database (SQLite/DuckDB) for intermediate storage instead of in-memory data frames. Parallelize analysis rules using Snakemake's `--jobs` flag to process chunks independently.

**KEGG API Rate Limiting:**
- Current capacity: KEGG API allows 10 requests/second for public users. Pipeline makes 5-6 requests per validation run.
- Limit: If adding new endpoints or validation rules, rate limiting could cause timeouts. No backoff beyond simple retry.
- Scaling path: Implement adaptive rate limiting with exponential backoff. Cache KEGG responses locally (24-hour TTL). Use KEGG REST API batching features if available. Consider commercial KEGG access for guaranteed throughput.

**Workflow DAG Complexity:**
- Current capacity: 18 rules, 4 layers, easily managed by Snakemake 7.32.4 on single machine.
- Limit: If adding species-specific pipelines, per-compound sub-workflows, or dynamic rules, DAG could exceed 100+ rules, making debugging difficult and cache invalidation complex.
- Scaling path: Split into separate Snakemake files for independent modules. Use modular rule imports. Implement caching strategy for stable intermediate outputs (KEGG data) so reruns don't refetch.

## Dependencies at Risk

**readxl R Package (Excel I/O):**
- Risk: `readxl` is used for all Excel input file loading. Package is in maintenance mode with few recent updates. If Excel format changes or bugs emerge, fixes may be slow.
- Impact: Cannot read input files; pipeline fails at preflight.
- Migration plan: Add CSV import as alternative to Excel files. Consider `openxlsx` (more actively maintained) as replacement if readxl becomes unsupported.

**Snakemake 7.32.4 (Workflow Manager):**
- Risk: Pinned to specific version. Snakemake 8+ may have breaking changes in rule syntax or API. Version is from 2023; security updates may lag in new versions.
- Impact: Compatibility issues with future Python versions; missed security fixes.
- Migration plan: Regularly review Snakemake release notes. Test pipeline on new major versions quarterly. Create CI job to verify compatibility.

**R dplyr many-to-many Joins:**
- Risk: `relationship = "many-to-many"` behavior is recent in dplyr (v1.1.0+). Future dplyr may deprecate or change semantics.
- Impact: Merge logic in `04_merge_relationships.R` relies on this parameter; changing dplyr could silently alter join behavior.
- Migration plan: Pin dplyr version in docker-compose and r-packages.txt. Add explicit test cases for join behavior to detect changes early.

## Missing Critical Features

**No Incremental Database Updates:**
- Problem: Pipeline regenerates entire database from scratch each run. No mechanism to update only changed compounds or relationships.
- Blocks: Frequent database updates with fresh KEGG data; pipeline takes hours even for minor source changes.
- Fix approach: Implement change-tracking. Store previous KEGG snapshots. Compute diffs and merge only changed entries. Requires versioning of intermediate data.

**No User-Facing Data Provenance Tracking:**
- Problem: While metadata reports exist, there's no clear per-row lineage (e.g., "this cpd-ko pair came from curated source" vs "KEGG bridge").
- Blocks: Users cannot assess confidence in individual database entries or filter by source.
- Fix approach: Add "source_origin" and "derivation_path" columns to database CSV. Track lineage through fallback stages in `04_merge_relationships.R`.

**No Configuration for Data Quality Thresholds:**
- Problem: All validation rules are hardcoded. No configurable thresholds for pass/fail criteria (e.g., minimum EC coverage, maximum unsupported rows).
- Blocks: Cannot tune pipeline rigor for different use cases (strict research vs relaxed screening).
- Fix approach: Add validation policy config section with thresholds. Make each validation rule exit code based on configurable criteria.

## Test Coverage Gaps

**Generation Scripts (04_merge_relationships.R) - Complex Logic Untested:**
- What's not tested: The fallback chain in `expand_keys_with_consistent_mapping()` function. Cartesian product behavior of many-to-many joins. Data loss at each join boundary.
- Files: `biorempp_snakemake_version/workflow/scripts/generation/04_merge_relationships.R` (lines 174-254)
- Risk: Silent data corruption during pipeline runs. Users see only final counts; intermediate filtering is invisible.
- Priority: **High** — This is the core ETL logic. Should have comprehensive unit tests with synthetic data covering edge cases: empty inputs, single-element sets, high-fanout joins.

**Validation Script Parsing (01/02_validate_*.py) - Token Normalization:**
- What's not tested: The `normalize_token()` function and pattern matching. Different input variants (prefixed, lowercase, with spaces).
- Files: `biorempp_snakemake_version/workflow/scripts/validation/01_validate_keys_consistency_api.py` (lines 25-37, 54-101), `02_validate_links_groundtruth_policy_api.py` (lines 25-101)
- Risk: Subtle normalization bugs causing mismatches between database and validation report (e.g., case sensitivity).
- Priority: **High** — Validation results are used to assess database quality. Parsing errors invalidate reports.

**Input File Validation (00_preflight.smk, 01_load_local_data.R):**
- What's not tested: File format validation, column checks, data type validation. Whether loading handles corrupted files gracefully.
- Files: `biorempp_snakemake_version/workflow/rules/00_preflight.smk`, `biorempp_snakemake_version/workflow/scripts/generation/01_load_local_data.R`
- Risk: Corrupted input files silently corrupt database (e.g., swapped columns).
- Priority: **Medium** — Defensive programming issue. Could prevent entire classes of user errors.

**API Resilience (retry logic, timeout handling):**
- What's not tested: Network failures, partial responses, timeout scenarios. Whether retry logic actually recovers or just delays failure.
- Files: `biorempp_snakemake_version/workflow/scripts/generation/02_fetch_kegg_info.R`, `03_fetch_kegg_data.R` (lines 14-45), validation scripts
- Risk: Pipeline hangs or fails silently on network issues. Users don't know if KEGG is down or data is stale.
- Priority: **Medium** — Resilience issue. Most visible to end users but rare in practice if KEGG is stable.

**Analysis Output Format Consistency:**
- What's not tested: All 9 analysis scripts produce JSON. No schema validation that outputs match expected structure.
- Files: `biorempp_snakemake_version/workflow/scripts/analysis/*.R`
- Risk: Downstream tools expecting specific JSON schema could break silently if an analysis script changes output format.
- Priority: **Low** — Primarily a forward-compatibility concern.

---

*Concerns audit: 2026-03-24*
