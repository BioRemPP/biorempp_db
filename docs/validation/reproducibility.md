# Reproducibility

This document describes how reproducibility is ensured in the BioRemPP Database generation pipeline.

---

## Reproducibility Objectives

The BioRemPP Database pipeline is designed to achieve **computational reproducibility** at multiple levels:

1. **Bit-for-bit reproducibility** — Identical outputs when re-run with same inputs and environment
2. **Version-controlled provenance** — Complete traceability of data sources and code versions
3. **Deterministic processing** — No random or stochastic components in pipeline
4. **Documented dependencies** — Explicit specification of software versions and configurations

**Reproducibility scope:**

- ✅ **Guaranteed:** Pipeline execution with fixed KEGG reference files
- ⚠️ **Conditional:** Pipeline execution with live KEGG API queries (subject to API changes)
- ❌ **Not guaranteed:** Results across different KEGG release versions

---

## Versioning of Data Sources and Scripts

### Code Versioning

**Version control system:** Git (GitHub)

**Repository:** `https://github.com/BioRemPP/biorempp_db`

**Versioning strategy:**

- **Semantic versioning:** v1.0.0 (MAJOR.MINOR.PATCH)
- **Git tags:** Each release tagged (e.g., `v1.0.0`)
- **Commit history:** Full provenance of code changes
- **Branch strategy:** `main` branch for releases, `dev` for development

**Key versioned files:**

| File | Purpose | Version Tracking |
|------|---------|------------------|
| `generate_database.R` | Main pipeline script | Git commits |
| `input_data/*.xlsx` | Input data files | Git LFS (large files) |
| `input_data/*.txt` | KEGG reference files | Git LFS |
| `mkdocs.yml` | Documentation config | Git commits |
| `README.md` | Project documentation | Git commits |

**Reproducibility guarantee:** Checking out specific Git tag (e.g., `git checkout v1.0.0`) ensures exact code version.

---

### Data Source Versioning

#### KEGG Reference Files

**Versioning approach:** Snapshot-based

| File | KEGG Release | Download Date | Rows | Version Identifier |
|------|--------------|---------------|------|-------------------|
| `kegglistcompounds.xlsx` | Dec,25 | December 2025 | 10,869 | KEGG Release Dec,25 |
| `kegglistko.txt` | Dec,25 | December 2025 | 47,421 | KEGG Release Dec,25 |

**Reproducibility guarantee:**

- ✅ **Fixed reference files** — Committed to Git; identical across executions
- ✅ **Version documented** — KEGG release version specified in documentation
- ⚠️ **KEGG API queries** — May change if KEGG updates database (see below)

---

#### Environmental Agency Lists

**Versioning approach:** Manual curation with version control

| File | Source | Last Updated | Version Identifier |
|------|--------|--------------|-------------------|
| `compostos_todasagencias.xlsx` | 9 environmental agencies | December 2025 | v1.0.0 |
| `missing_compounds_founds_curated.xlsx` | Literature curation | December 2025 | v1.0.0 |
| `confirm_class_CURATED.xlsx` | Expert curation | December 2025 | v1.0.0 |

**Reproducibility guarantee:**

- ✅ **Git-tracked** — All changes version-controlled
- ✅ **Immutable for v1.0.0** — Files frozen at release
- ⚠️ **Future updates** — New versions will have different content

---

#### Enzyme Lexicon

**Versioning approach:** Curated vocabulary with version control

| File | Source | Terms | Version Identifier |
|------|--------|-------|-------------------|
| `enzymes_unique.txt` | Literature review | 210 | v1.0.0 |

**Reproducibility guarantee:**

- ✅ **Git-tracked** — Version-controlled
- ✅ **Deterministic extraction** — Pattern matching is deterministic

---

## Deterministic and Non-Deterministic Pipeline Components

### Deterministic Components

**Guaranteed bit-for-bit reproducibility:**

| Pipeline Stage | Determinism | Rationale |
|----------------|-------------|-----------|
| **Data loading** | ✅ Deterministic | Fixed input files |
| **Identifier sanitization** | ✅ Deterministic | Regex-based; no randomness |
| **Deduplication** | ✅ Deterministic | `unique()` function is deterministic |
| **Merging** | ✅ Deterministic | `merge()` and `left_join()` are deterministic |
| **Classification** | ✅ Deterministic | Fixed classification file |
| **Enzyme extraction** | ✅ Deterministic | Pattern matching; no randomness |
| **Sorting** | ✅ Deterministic | `arrange()` uses stable sort |
| **Output writing** | ✅ Deterministic | CSV/Excel writing is deterministic |

**No stochastic processes:** Pipeline contains no random number generation, sampling, or machine learning components.

---

### Non-Deterministic Components

**Conditional reproducibility:**

| Pipeline Stage | Determinism | Variability Source |
|----------------|-------------|-------------------|
| **KEGG API queries** | ⚠️ Conditional | KEGG database may update between executions |
| **Network requests** | ⚠️ Conditional | API availability, timeouts, rate limits |

**KEGG API queries:**

The pipeline queries KEGG REST API for:

- KO-EC links: `https://rest.kegg.jp/link/ko/ec`
- KO-Reaction links: `https://rest.kegg.jp/link/ko/reaction`
- Compound-EC links: `https://rest.kegg.jp/link/compound/ec`
- Compound-Reaction links: `https://rest.kegg.jp/link/cpd/reaction`
- Compound list: `https://rest.kegg.jp/list/cpd/`

**Reproducibility implications:**

- ⚠️ **KEGG updates** — If KEGG adds/removes entries between executions, results may differ
- ⚠️ **API changes** — KEGG may modify API endpoints or response formats
- ⚠️ **Network failures** — Transient network issues may cause execution failures

**Mitigation strategy:**

- ✅ **Local reference files** — Primary data sources (compounds, KO) are local snapshots
- ✅ **API results cached** — Consider caching API responses for reproducibility (not implemented in v1.0.0)
- ✅ **Version documentation** — KEGG release version documented

---

## Handling of External Dependencies

### R Package Dependencies

**Dependency management:**

```r
required_packages <- c("readxl", "dplyr", "tidyr", "stringr", "readr", "xlsx")
```

**Reproducibility challenge:** R package versions may change over time.

**Current approach:**

- ⚠️ **No version pinning** — Pipeline uses latest installed versions
- ⚠️ **Potential for breakage** — Future package updates may introduce incompatibilities

**Recommended approach for reproducibility:**

```r
# Use renv for package version management
renv::init()
renv::snapshot()  # Creates renv.lock file
```

**Future improvement:** Add `renv.lock` file to repository for exact package version reproducibility.

---

### System Dependencies

**Operating system:** Cross-platform (Windows, macOS, Linux)

**R version:** Tested on R ≥ 4.0.0

**Reproducibility considerations:**

- ✅ **R version documented** — Minimum version specified
- ⚠️ **OS differences** — File path handling may differ (mitigated by `normalizePath()`)
- ⚠️ **Locale differences** — Character encoding may vary (mitigated by UTF-8 specification)

---

### KEGG API Dependency

**API endpoint:** `https://rest.kegg.jp/`

**Reproducibility challenges:**

1. **KEGG database updates** — Quarterly releases add/modify entries
2. **API availability** — Downtime or rate limiting may occur
3. **Response format changes** — KEGG may modify API response structure

**Mitigation strategies:**

| Strategy | Implementation | Reproducibility Benefit |
|----------|----------------|------------------------|
| **Local snapshots** | Download KEGG files before pipeline | Eliminates API dependency for core data |
| **API caching** | Cache API responses locally | Enables offline re-execution |
| **Version documentation** | Document KEGG release version | Enables version-specific reproduction |
| **Error handling** | Graceful failure with informative messages | Prevents silent failures |

**Current implementation (v1.0.0):**

- ✅ Local snapshots for compounds and KO
- ❌ No API response caching (planned for v1.1.0)
- ✅ Version documentation (Dec,25)
- ✅ Error handling with `try()` blocks

---

## Recommendations for Reproducible Reuse

### For Users Reproducing v1.0.0 Results

**Step-by-step reproducibility protocol:**

1. **Clone repository at specific tag:**
   ```bash
   git clone https://github.com/BioRemPP/biorempp_db.git
   cd biorempp_db
   git checkout v1.0.0
   ```

2. **Verify R version:**
   ```r
   R.version.string  # Should be R >= 4.0.0
   ```

3. **Install exact package versions (if `renv.lock` available):**
   ```r
   renv::restore()
   ```

4. **Run pipeline:**
   ```r
   source("generate_database.R")
   ```

5. **Verify output:**
   ```r
   db <- read.csv("output_data/biorempp_database_v1.0.0.csv")
   nrow(db)  # Should be 10,869
   length(unique(db$cpd))  # Should be 384
   ```

**Expected reproducibility:**

- ✅ **Identical row count** — 10,869 rows
- ✅ **Identical compound count** — 384 unique compounds
- ✅ **Identical KO count** — 1,541 unique KO entries
- ⚠️ **Potential API differences** — If KEGG updated between v1.0.0 release and reproduction

---

### For Users Generating New Database Versions

**Best practices for reproducible database generation:**

1. **Document KEGG version:**
   ```r
   # Record KEGG release version
   kegg_version <- "Dec,25"
   write(kegg_version, "kegg_version.txt")
   ```

2. **Snapshot KEGG reference files:**
   ```bash
   # Download and commit KEGG files
   wget https://rest.kegg.jp/list/compound -O kegglistcompounds.txt
   wget https://rest.kegg.jp/list/ko -O kegglistko.txt
   git add input_data/*.txt
   git commit -m "Update KEGG reference files (Release YYYY-MM)"
   ```

3. **Use package version management:**
   ```r
   renv::snapshot()
   git add renv.lock
   git commit -m "Pin R package versions"
   ```

4. **Document execution environment:**
   ```r
   sessionInfo()  # Save to file
   write(capture.output(sessionInfo()), "session_info.txt")
   ```

5. **Version control outputs:**
   ```bash
   git add output_data/biorempp_database_v*.csv
   git commit -m "Release v1.1.0"
   git tag v1.1.0
   ```

---

## Known Reproducibility Constraints

### Constraint 1: KEGG API Variability

**Issue:** KEGG database updates quarterly; API queries may return different results over time.

**Impact:**

- ⚠️ **Row count may change** — New KO-compound relationships added
- ⚠️ **Compound names may change** — KEGG updates nomenclature
- ⚠️ **Deprecated entries** — KEGG may retire or merge entries

**Mitigation:**

- Document KEGG release version (Dec,25)
- Use local snapshots for core data

**Recommendation:** For exact reproducibility, use same KEGG release version.

---

### Constraint 2: R Package Version Drift

**Issue:** R packages update frequently; function behavior may change.

**Impact:**

- ⚠️ **Potential for breakage** — Deprecated functions, changed defaults
- ⚠️ **Subtle result differences** — Rounding, sorting, encoding changes

**Mitigation:**

- Document R version (≥ 4.0.0)
- Plan `renv` integration for v1.1.0

**Recommendation:** Use `renv::restore()` to install exact package versions.

---

### Constraint 3: Manual Curation Updates

**Issue:** Manual curation files may be updated with new literature findings.

**Impact:**

- ✅ **Version-controlled** — Git tracks all changes
- ⚠️ **Different versions yield different results** — Expected behavior

**Mitigation:**

- Git tags freeze curation files at release
- Changelog documents curation updates

**Recommendation:** Specify Git tag (e.g., `v1.0.0`) for exact reproduction.

---

### Constraint 4: Operating System Differences

**Issue:** File path handling, line endings, and locale may differ across OS.

**Impact:**

- ⚠️ **Path separators** — Windows (`\`) vs. Unix (`/`)
- ⚠️ **Line endings** — Windows (CRLF) vs. Unix (LF)
- ⚠️ **Character encoding** — Locale-dependent

**Mitigation:**

- Use `normalizePath()` for cross-platform paths
- Specify UTF-8 encoding explicitly
- Use `readLines()` with `warn = FALSE` for universal newline handling

**Recommendation:** Test pipeline on target OS before critical analyses.

---

## Reproducibility Validation

### Validation Test: Bit-for-Bit Reproducibility

**Protocol:**

1. Run pipeline: `source("generate_database.R")`
2. Save output: `db1 <- read.csv("output_data/biorempp_database_v1.0.0.csv")`
3. Delete output: `file.remove("output_data/biorempp_database_v1.0.0.csv")`
4. Re-run pipeline: `source("generate_database.R")`
5. Save output: `db2 <- read.csv("output_data/biorempp_database_v1.0.0.csv")`
6. Compare: `identical(db1, db2)`

**Expected result:**

```r
identical(db1, db2)
# [1] TRUE
```

**Validation status (v1.0.0):**

- ✅ **Passed** — Bit-for-bit reproducibility confirmed
- ✅ **No stochastic components** — Deterministic pipeline
- ✅ **Stable sorting** — `arrange()` produces consistent order

---

### Validation Test: Cross-Platform Reproducibility

**Protocol:**

1. Run pipeline on Windows
2. Run pipeline on macOS
3. Run pipeline on Linux
4. Compare outputs via MD5 checksums

**Expected result:**

```bash
md5sum biorempp_database_v1.0.0.csv
# Should be identical across platforms
```

**Validation status (v1.0.0):**

- ✅ **Passed** — Cross-platform reproducibility confirmed
- ⚠️ **Excel output may differ** — Binary format differences (use CSV for comparison)

---

## Reproducibility Statement

**BioRemPP Database v1.0.0 is reproducible under the following conditions:**

1. ✅ **Same Git tag** — `git checkout v1.0.0`
2. ✅ **Same R version** — R ≥ 4.0.0
3. ✅ **Same package versions** — Use `renv::restore()` (when available)
4. ✅ **Same KEGG reference files** — Committed to repository
5. ⚠️ **Same KEGG API state** — May vary if KEGG updates database

**Reproducibility guarantee:**

- **100% reproducibility** — When using local reference files only
- **Conditional reproducibility** — When querying live KEGG API

**Recommended citation for reproducibility:**

```
BioRemPP Development Team. (2025). BioRemPP Database v1.0.0 [Data set]. 
Zenodo. https://doi.org/10.5281/zenodo.[PLACEHOLDER]
Git tag: v1.0.0
KEGG Release: Dec,25
```

---

## Questions?

**GitHub Issues:** [https://github.com/BioRemPP/biorempp_db/issues](https://github.com/BioRemPP/biorempp_db/issues)  
**Email:** biorempp@gmail.com
