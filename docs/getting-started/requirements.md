# Requirements

This page specifies the software, hardware, and data requirements for running the BioRemPP Database generation pipeline.

---

## Software Requirements

### Core Dependencies

| Software | Minimum Version | Recommended Version | Purpose |
|----------|----------------|---------------------|---------|
| **R** | 4.0.0 | 4.3.0+ | Statistical computing environment |
| **Git** | 2.0+ | Latest | Repository cloning (optional) |

### R Package Dependencies

| Package | Version | License | Purpose |
|---------|---------|---------|---------|
| `readxl` | ≥1.3.1 | GPL-3 | Read Excel input files |
| `dplyr` | ≥1.0.0 | MIT | Data manipulation and transformation |
| `tidyr` | ≥1.1.0 | MIT | Data tidying operations |
| `stringr` | ≥1.4.0 | MIT | String processing and regex |
| `readr` | ≥2.0.0 | MIT | Fast CSV reading/writing |
| `xlsx` | ≥0.6.0 | GPL-3 | Excel file export (requires Java) |

**Alternative to `xlsx`:** `writexl` (≥1.4.0, no Java required)

### System Libraries (Linux Only)

Required for R package compilation:

=== "Ubuntu/Debian"
    ```
    - libcurl4-openssl-dev
    - libssl-dev
    - libxml2-dev
    - build-essential
    - r-base-dev
    ```

=== "CentOS/RHEL"
    ```
    - libcurl-devel
    - openssl-devel
    - libxml2-devel
    - gcc
    - gcc-c++
    - R-devel
    ```

### Optional Dependencies

| Software | Purpose | When Needed |
|----------|---------|-------------|
| **Java JRE** (≥8) | Excel export via `xlsx` package | If using `xlsx` (not `writexl`) |
| **RStudio** (any version) | Interactive development environment | For GUI-based execution |
| **Pandoc** (≥2.0) | Documentation building | If building MkDocs locally |
| **Python** (≥3.8) + MkDocs | Documentation generation | If building documentation site |

---

## Hardware Requirements

### Minimum Configuration

Suitable for pipeline execution with default input data:

| Resource | Minimum | Notes |
|----------|---------|-------|
| **RAM** | 4 GB | Sufficient for current dataset (10,869 entries) |
| **Storage** | 500 MB | Pipeline + input data + outputs |
| **CPU** | 1 core | Single-threaded execution |
| **Network** | Required | KEGG API access (HTTPS) |

**Estimated runtime:** 5 minutes on minimum configuration

### Recommended Configuration

For comfortable execution and future scalability:

| Resource | Recommended | Benefits |
|-----------|-------------|----------|
| **RAM** | 8 GB+ | Faster data processing, supports larger datasets |
| **Storage** | 2 GB+ | Space for multiple pipeline runs, analysis outputs |
| **CPU** | 2+ cores | Potential for future parallelization |
| **Network** | Stable broadband | Faster KEGG API queries |

**Estimated runtime:** 3-8 minutes on recommended configuration

### HPC/Server Configuration

For institutional compute clusters or large-scale batch processing:

| Resource | Typical | Use Case |
|----------|---------|----------|
| **RAM** | 16-32 GB | Batch runs, extended datasets |
| **Storage** | 10 GB+ | Multiple versions, analysis archives |
| **CPU** | 8+ cores | Parallel processing (future releases) |
| **Network** | Institutional | Reliable API access |

---

## Network Requirements

### Internet Connectivity

**Required for:**

- KEGG REST API queries (https://rest.kegg.jp/)
  - KO-EC and KO-Reaction links
  - Compound-EC and Compound-Reaction links
  - Compound list with names
  - KO list with gene information

**Bandwidth requirements:**

| Operation | Data Transfer | Frequency |
|-----------|--------------|-----------|
| KEGG API queries | ~50-100 MB | Per pipeline run |
| Repository clone | ~20 MB | One-time |
| Documentation build | ~5 MB | Optional |

**Network conditions:**

- **Latency:** <500 ms to rest.kegg.jp (typical: 50-200 ms)
- **Stability:** Continuous connection for 5-15 minutes
- **Firewall:** HTTPS (port 443) outbound access required

### Offline Execution

**Limited support:** Pipeline requires KEGG API for core functionality. Offline execution is **not supported** in v1.0.0.

**Future releases** may support:

- Cached KEGG data for offline execution
- Pre-downloaded snapshot option
- Local KEGG mirror integration

**Current workaround:**

1. Run pipeline once with internet to cache API responses
2. Modify pipeline to skip API calls and use cached data (advanced users only)

---

## Data Requirements

### Input Data Files

The following files must be present in `input_data/` directory:

| File | Format | Size | Description |
|------|--------|------|-------------|
| `kegglistcompounds.xlsx` | Excel | ~425 KB | KEGG compound reference list |
| `compostos_todasagencias.xlsx` | Excel | ~30 KB | Environmental agency compound lists |
| `missing_compounds_founds_curated.xlsx` | Excel | ~38 KB | Manual curations for missing compounds |
| `confirm_class_CURATED.xlsx` | Excel | ~17 KB | Compound chemical classifications |
| `kegglistko.txt` | Text | ~1.6 MB | KEGG Orthology reference list |
| `enzymes_unique.txt` | Text | ~3 KB | Unique enzyme activity terms |

**Total input data:** ~2.2 MB

All files are included in the repository and do not require separate download.

### Expected Output

| File | Format | Approximate Size | Content |
|------|--------|------------------|---------|
| `biorempp_database_v1.0.0.csv` | CSV | ~1.3 MB | Main database (10,869 rows × 8 columns) |
| `biorempp_database_v1.0.0.xlsx` | Excel | ~460 KB | Excel-formatted database |
| `biorempp_db.csv` | CSV | ~1.1 MB | Alternative format output |

### Analysis Outputs (Optional)

Generated by `analysis/analyze_database.R`:

| File | Format | Size | Content |
|------|--------|------|---------|
| `database_metadata.json` | JSON | ~2 KB | Schema and provenance |
| `basic_statistics.json` | JSON | <1 KB | Core metrics |
| `compound_statistics.json` | JSON | ~1.5 KB | Compound analysis |
| `ko_statistics.json` | JSON | <1 KB | KO analysis |
| `enzyme_statistics.json` | JSON | ~1 KB | Enzyme analysis |
| `gene_statistics.json` | JSON | ~1.4 KB | Gene analysis |
| `crosstab_statistics.json` | JSON | ~1.8 KB | Cross-dimensional analysis |
| `executive_summary.json` | JSON | <1 KB | Summary metrics |
| `complete_analysis.json` | JSON | ~10 KB | Full analysis bundle |

**Total analysis outputs:** ~20 KB (9 JSON files)

---

## Operating System Compatibility

### Tested Platforms

| Platform | Version | Status | Notes |
|----------|---------|--------|-------|
| **Windows** | 10, 11 | ✅ Fully Tested | PowerShell, Command Prompt, Git Bash |
| **macOS** | 12 (Monterey), 13 (Ventura), 14 (Sonoma) | ✅ Fully Tested | Intel and Apple Silicon (M1/M2) |
| **Ubuntu Linux** | 20.04 LTS, 22.04 LTS | ✅ Fully Tested | Primary development platform |
| **Debian** | 10 (Buster), 11 (Bullseye) | ✅ Tested | Server deployments |
| **CentOS** | 7, 8 | ✅ Tested | HPC environments |
| **RHEL** | 8, 9 | ✅ Tested | Enterprise servers |
| **Fedora** | 36+  | ⚠️  Expected to work | Not formally tested |
| **Arch Linux** | Rolling | ⚠️  Expected to work | Community-tested |

### Unsupported Platforms

| Platform | Reason |
|----------|--------|
| Windows 7/8 | End-of-life, R compatibility issues |
| macOS < 10.14 | Incompatible with modern R versions |
| 32-bit systems | R ≥4.0 requires 64-bit architecture |

---

## Execution Environments

### Local Workstation

**Use cases:**

- Interactive exploration and development
- Initial testing and validation
- Small-scale analyses
- Documentation building

**Recommended for:**

- First-time users learning the pipeline
- Researchers running single analyses
- Developers modifying pipeline code

### Remote Server

**Use cases:**

- Production-grade database generation
- Batch processing multiple datasets
- Reproducible workflow execution
- Institutional deployments

**Recommended for:**

- Bioinformatics core facilities
- Research groups with dedicated servers
- Multi-user environments
- Scheduled/automated runs

### High-Performance Computing (HPC)

**Use cases:**

- Large-scale batch processing
- Extended/modified datasets
- Future parallelized versions
- Resource-intensive analyses

**Recommended for:**

- Institutional compute clusters
- Multi-omics integration workflows
- Computational research groups
- Production deployments at scale

### Cloud Computing

**Use cases:**

- On-demand pipeline execution
- Scalable compute resources
- Reproducible containerized workflows
- CI/CD integration

**Supported platforms:**

- AWS EC2 (Linux AMIs with R ≥4.0)
- Google Cloud Compute Engine
- Microsoft Azure Virtual Machines
- Any cloud VM with R support

---

## R Session Requirements

### Locale and Encoding

**Recommended settings:**

```r
# Check current locale
Sys.getlocale()

# Set UTF-8 encoding (if needed)
Sys.setlocale("LC_ALL", "en_US.UTF-8")
```

**Why:** Ensures proper handling of compound names with special characters (e.g., Greek letters, subscripts).

### Memory Settings

**Default (sufficient for v1.0.0):**

```r
# Check memory limit (Windows only)
memory.limit()  # Default: system-dependent
```

**For large datasets (future versions):**

```r
# Increase memory limit (Windows only)
memory.limit(size = 16000)  # 16 GB

# Unix/macOS: Set via shell before launching R
# ulimit -s unlimited
```

### Timeout Configuration

**Recommended for KEGG API:**

```r
# Set timeout to 5 minutes (300 seconds)
options(timeout = 300)
```

**Why:** KEGG API queries may timeout on slow connections. Default timeout (60s) is often insufficient.

---

## Verification Commands

Run these commands to verify your system meets requirements:

### Check R Version

```r
R.version.string
# Expected: "R version 4.3.2 (2023-10-31)" or higher
```

### Check Installed Packages

```r
installed.packages()[c("readxl", "dplyr", "tidyr", "stringr", "readr", "xlsx"), "Version"]
```

### Check System Memory

```r
# Total RAM available to R
memory.size()  # Windows
# or
system("free -h")  # Linux/macOS
```

### Check Network Connectivity

```bash
# Test KEGG API access
curl -I https://rest.kegg.jp/list/pathway

# Expected: HTTP/1.1 200 OK
```

### Complete System Check

```r
# Run this R script to check all requirements
cat("=== BioRemPP System Requirements Check ===\n\n")

cat("R Version:\n")
print(R.version.string)

cat("\nRequired Packages:\n")
packages <- c("readxl", "dplyr", "tidyr", "stringr", "readr", "xlsx")
for (pkg in packages) {
  installed <- requireNamespace(pkg, quietly = TRUE)
  cat(sprintf("  %s: %s\n", pkg, ifelse(installed, "✓ INSTALLED", "✗ MISSING")))
}

cat("\nMemory:\n")
cat(sprintf("  Available RAM: %.2f GB\n", memory.size() / 1024))

cat("\nLocale:\n")
cat(sprintf("  %s\n", Sys.getlocale()))

cat("\n=== Check Complete ===\n")
```

---

## Troubleshooting Requirements Issues

### "R version too old"

**Error:** `Error: R >= 4.0.0 required`

**Solution:** Upgrade R from [CRAN](https://cran.r-project.org/)

---

### "Package X not available"

**Error:** `Error: package 'dplyr' is not available`

**Solution:**

```r
# Update CRAN mirror
options(repos = "https://cloud.r-project.org/")

# Install missing package
install.packages("dplyr")
```

---

### "Cannot allocate memory"

**Error:** `Error: cannot allocate vector of size X GB`

**Solutions:**

1. Close other applications
2. Restart R session
3. Increase system memory or use server
4. Use HPC for larger datasets

---

### "KEGG API connection failed"

**Error:** `Error: Failed to fetch data from KEGG API`

**Solutions:**

1. Check internet connection
2. Test KEGG access: `curl https://rest.kegg.jp/list/pathway`
3. Configure proxy if behind firewall
4. Increase timeout: `options(timeout = 300)`

---

## Next Steps

After verifying requirements:

1. **Install the pipeline:** [Installation Guide](installation.md)
2. **Run first analysis:** [Quick Start Guide](quick-start.md)
3. **Understand inputs:** [Input Data Files](../user-guide/input-data.md)

---

## Questions?

**GitHub Issues:** [https://github.com/BioRemPP/biorempp_db/issues](https://github.com/BioRemPP/biorempp_db/issues)  
**Email:** biorempp@gmail.com
