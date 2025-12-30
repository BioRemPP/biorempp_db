# Troubleshooting

This guide provides solutions to common issues encountered when running the BioRemPP Database generation pipeline.

---

## General Troubleshooting Approach

When encountering errors:

1. **Read the error message carefully** — Error messages often indicate the exact issue
2. **Check prerequisites** — Verify R version, packages, and internet connectivity
3. **Review recent changes** — Did you modify input files or update dependencies?
4. **Consult logs** — Pipeline outputs detailed progress messages
5. **Search GitHub Issues** — Others may have encountered similar problems
6. **Report new issues** — If unresolved, create a GitHub issue with full error details

---

## Pipeline Execution Issues

### Error: "Cannot open file 'generate_database.R'"

**Symptom:**

```
Error in file(filename, "r", encoding = encoding) : 
  cannot open the connection
```

**Cause:** R working directory is not set to the project root directory

**Solution:**

```r
# Check current directory
getwd()

# Set correct directory to project root
setwd("path/to/project/root")

# Verify file exists
file.exists("generate_database.R")  # Should return TRUE
```

---

### Error: "Package 'X' is not available"

**Symptom:**

```
Error in library(dplyr) : there is no package called 'dplyr'
```

**Cause:** Required R package not installed

**Solution:**

```r
# Install missing package
install.packages("dplyr")

# Install all required packages at once
install.packages(c("readxl", "dplyr", "tidyr", "stringr", "readr", "xlsx"))
```

---

### Pipeline Stops Without Error Message

**Symptom:** Pipeline execution halts silently, no output files generated

**Possible causes:**

1. **Network interruption** during KEGG API queries
2. **Memory exhaustion** (rare with default dataset)
3. **Read timeout** for slow connections

**Solutions:**

```r
# Increase timeout
options(timeout = 600)  # 10 minutes

# Re-run pipeline
source("generate_database.R")
```

If issue persists, run pipeline step-by-step:

```r
# Source only function definitions (without executing)
source("generate_database.R", local = TRUE)

# Execute stages manually to identify failure point
# Stage 1
compounds_local <- load_kegg_compounds_local()
```

---

## KEGG API Connection Issues

### Error: "Failed to fetch data from KEGG API"

**Symptom:**

```
Error in fetch_kegg_api: Failed to fetch data from KEGG API
Timeout was reached
```

**Cause:** Network connectivity issue or KEGG server unavailable

**Solutions:**

#### Check Internet Connection

```bash
# Test KEGG API access
curl -I https://rest.kegg.jp/list/pathway

# Should return: HTTP/1.1 200 OK
```

If connection fails:

- ✅ Verify internet connectivity (try accessing other websites)
- ✅ Check firewall settings (allow HTTPS on port 443)
- ✅ Test from different network (some corporate firewalls block KEGG)

#### Configure Proxy (if behind firewall)

```r
# Set proxy before running pipeline
Sys.setenv(http_proxy = "http://proxy.company.com:8080")
Sys.setenv(https_proxy = "https://proxy.company.com:8080")

# Verify settings
Sys.getenv("https_proxy")
```

#### Increase Timeout

```r
# Default timeout may be too short for slow connections
options(timeout = 300)  # 5 minutes
source("generate_database.R")
```

---

### Error: "HTTP 403 Forbidden" from KEGG API

**Symptom:**

```
Error: KEGG API returned HTTP 403 Forbidden
```

**Cause:** Temporary rate limiting or server-side restriction

**Solutions:**

1. **Wait and retry** — KEGG may temporarily limit requests; wait 5-10 minutes
2. **Check KEGG status** — Visit https://www.kegg.jp/ to verify service availability
3. **Reduce query frequency** — Pipeline already implements delays; avoid running multiple instances simultaneously

**Not a permanent block:** KEGG REST API is freely accessible; 403 errors are usually temporary.

---

## Input Data Issues

### Error: "File does not exist: input_data/X.xlsx"

**Symptom:**

```
Error in read_excel("input_data/kegglistcompounds.xlsx") :
  `path` does not exist: 'input_data/kegglistcompounds.xlsx'
```

**Cause:** Missing input file or incorrect working directory

**Solutions:**

```r
# Verify all input files exist
list.files("input_data/")

# Expected: 6 files
# [1] "compostos_todasagencias.xlsx"            
# [2] "confirm_class_CURATED.xlsx"              
# [3] "enzymes_unique.txt"                      
# [4] "kegglistcompounds.xlsx"                  
# [5] "kegglistko.txt"                          
# [6] "missing_compounds_founds_curated.xlsx"
```

If files are missing:

- ✅ Re-clone repository (files may not have been downloaded)
- ✅ Check Git LFS settings (large files may require LFS)
- ✅ Download missing files manually from GitHub

---

### Error: "Excel file format invalid"

**Symptom:**

```
Error in read_excel() : 
  Evaluation error: zip file 'input_data/X.xlsx' cannot be opened
```

**Cause:** Corrupted Excel file or wrong file format (.xls vs .xlsx)

**Solutions:**

1. **Re-download file** from repository
2. **Open and re-save** in Excel as .xlsx format
3. **Check file size** — Corrupted files often have 0 bytes

```bash
# Check file size (should be >0)
ls -lh input_data/kegglistcompounds.xlsx
```

---

### Error: "Unexpected data in input file"

**Symptom:**

```
Error: Column names do not match expected schema
```

**Cause:** Input file modified with incorrect structure

**Solution:**

Compare your file against expected schema (see [Input Data Files](input-data.md)). Common mistakes:

- ✅ Added extra columns
- ✅ Changed column order
- ✅ Added/removed header row where not expected
- ✅ Used wrong delimiter (comma instead of tab)

**Best practice:** Restore original file from Git and re-apply modifications carefully.

---

## Output Generation Issues

### Error: "Permission denied" when writing output

**Symptom:**

```
Error in write.csv() : cannot open file 'output_data/biorempp_database_v1.0.0.csv':
  Permission denied
```

**Cause:** No write permissions for `output_data/` directory

**Solutions:**

=== "Windows"
    ```powershell
    # Run PowerShell as Administrator
    # Grant write permissions
    icacls "output_data" /grant Users:F
    ```

=== "macOS/Linux"
    ```bash
    # Make directory writable
    chmod u+w output_data/
    
    # Or change ownership
    sudo chown $USER output_data/
    ```

---

### Error: "Cannot allocate vector of size X GB"

**Symptom:**

```
Error: cannot allocate vector of size 2.5 GB
```

**Cause:** Insufficient RAM

**Solutions:**

1. **Close other applications** to free memory
2. **Restart R session** to clear memory
3. **Increase memory limit** (Windows only):

```r
# Check current limit
memory.limit()

# Increase to 8 GB
memory.limit(size = 8000)
```

4. **Run on server/HPC** with more RAM

**Note:** Default dataset (~10,869 rows) requires <1 GB RAM; this error suggests other issues (infinite loop, memory leak). Report as GitHub issue if encountered with unmodified pipeline.

---

### xlsx Package Fails (Java Error)

**Symptom:**

```
Error: Java not found
Cannot load rJava package
```

**Cause:** `xlsx` package requires Java, which is not installed

**Solutions:**

#### Option A: Install Java

=== "Windows"
    1. Download Java from https://www.java.com/download/
    2. Install and restart R
    3. Re-run pipeline

=== "macOS"
    ```bash
    brew install openjdk
    sudo R CMD javareconf
    ```

=== "Linux"
    ```bash
    sudo apt install default-jre default-jdk
    sudo R CMD javareconf
    ```

#### Option B: Use writexl (No Java Required)

Replace `xlsx` with `writexl` package:

```r
# Install writexl
install.packages("writexl")

# Modify generate_database.R (line ~730)
# Replace:
library(xlsx)
write.xlsx(final_database, output_xlsx, row.names = FALSE)

# With:
library(writexl)
write_xlsx(final_database, output_xlsx)
```

---

## Data Validation Errors

### Warning: "Unmapped compounds found"

**Symptom:**

```
Warning: 12 compounds in agency lists not found in KEGG compound reference
```

**Cause:** Input file `compostos_todasagencias.xlsx` contains Compound IDs not present in `kegglistcompounds.xlsx`

**Impact:** These compounds will be **excluded** from final database

**Solutions:**

1. **Verify Compound IDs** — Ensure IDs are correct KEGG format (C#####)
2. **Update KEGG reference** — Download latest `kegglistcompounds.xlsx` from KEGG
3. **Document exclusions** — If compounds are intentionally novel, document separately

This is a **warning**, not an error. Pipeline will continue.

---

### Error: "No gene information found for KO entries"

**Symptom:**

```
Warning: 152 KO entries without gene match in kegglistko.txt
```

**Cause:** KO IDs in curated data (`missing_compounds_founds_curated.xlsx`) not found in `kegglistko.txt`

**Impact:** Entries without gene information are **excluded** during Stage 5

**Solutions:**

1. **Verify KO IDs** — Ensure format is correct (K##### or ko:K#####)
2. **Update KO reference** — Download latest `kegglistko.txt` from KEGG
3. **Remove invalid entries** — Delete rows with non-existent KO IDs from curation file

---

## R Package Version Conflicts

### Error: "Function X not found in package Y"

**Symptom:**

```
Error: could not find function "left_join"
```

**Cause:** Outdated package version missing required function

**Solution:**

```r
# Update all packages
update.packages(ask = FALSE)

# Update specific package
install.packages("dplyr", dependencies = TRUE)

# Restart R session
.rs.restartR()  # RStudio
# Or quit() and restart R
```

---

### Error: "Namespace conflict"

**Symptom:**

```
Error: objects 'filter', 'lag' are masked from 'package:stats'
```

**Cause:** Function name conflicts between packages (common with dplyr)

**Solution:** Use explicit namespace:

```r
# Instead of: filter(db, cpd == "C00001")
# Use:
dplyr::filter(db, cpd == "C00001")
```

Pipeline already uses `library(dplyr)`, so this should not occur. If it does, check for custom package loading in `.Rprofile`.

---

## Platform-Specific Issues

### Windows: Line Ending Issues

**Symptom:** Text files (`.txt`) not reading correctly, showing `^M` characters

**Cause:** Windows CRLF vs Unix LF line endings

**Solution:**

```r
# Read with universal newline handling
data <- readLines("input_data/enzymes_unique.txt", warn = FALSE)
```

Pipeline already handles this internally. If issue persists, convert files:

```bash
# Using dos2unix (if available)
dos2unix input_data/*.txt

# Or in Git
git config core.autocrlf true
```

---

### macOS: OpenSSL/SSL Certificate Errors

**Symptom:**

```
Error: SSL certificate problem: unable to get local issuer certificate
```

**Cause:** macOS certificate validation issue with HTTPS requests

**Solution:**

```r
# Temporarily disable SSL verification (not recommended for production)
options(download.file.method = "curl", download.file.extra = "-k")
```

**Better solution:** Update CA certificates:

```bash
brew install curl
brew reinstall openssl
```

---

### Linux: Missing System Libraries

**Symptom:**

```
ERROR: compilation failed for package 'curl'
```

**Cause:** Missing system development libraries

**Solution:**

=== "Ubuntu/Debian"
    ```bash
    sudo apt install -y libcurl4-openssl-dev libssl-dev libxml2-dev
    ```

=== "CentOS/RHEL"
    ```bash
    sudo yum install -y libcurl-devel openssl-devel libxml2-devel
    ```

Then reinstall R packages:

```r
install.packages(c("curl", "httr", "readr"))
```

---

## Performance Issues

### Pipeline Running Very Slowly (>30 minutes)

**Possible causes:**

1. **Slow internet connection** — KEGG API queries dominate runtime
2. **Antivirus scanning** — Real-time scanning of R processes (Windows)
3. **Low RAM** — System swapping to disk

**Solutions:**

1. **Test connection speed:**
   ```bash
   time curl https://rest.kegg.jp/list/pathway > /dev/null
   # Should complete in <5 seconds
   ```

2. **Disable antivirus temporarily** (Windows):
   - Exclude R installation directory from real-time scanning
   - Exclude project directory from scanning

3. **Monitor memory usage:**
   ```r
   # Check memory during execution
   pryr::mem_used()
   gc()  # Force garbage collection
   ```

4. **Run on server/HPC** for faster execution

---

## Getting Help

### Before Reporting an Issue

Collect the following information:

1. **R session info:**
   ```r
   sessionInfo()
   ```

2. **Package versions:**
   ```r
   installed.packages()[c("readxl", "dplyr", "tidyr", "stringr", "readr", "xlsx"), "Version"]
   ```

3. **Error message** (full text, including stack trace)

4. **Operating system:**
   ```r
   Sys.info()["sysname"]
   Sys.info()["release"]
   ```

5. **Steps to reproduce** (if not standard pipeline execution)

### GitHub Issues

**Create a new issue:** [https://github.com/BioRemPP/biorempp_db/issues/new](https://github.com/BioRemPP/biorempp_db/issues/new)

**Include:**

- Clear, concise title (e.g., "KEGG API timeout on slow connection")
- System information (OS, R version)
- Full error message
- Steps to reproduce
- What you've already tried

**Search first:** [Existing issues](https://github.com/BioRemPP/biorempp_db/issues) — your problem may already be solved

---

### Email Support

**Email:** biorempp@gmail.com

**For:**

- Conceptual questions about database usage
- Collaboration inquiries
- Data integration advice

**Not for:**

- Bug reports (use GitHub Issues instead)
- Installation support (consult [Installation Guide](../getting-started/installation.md) first)

---

## Frequently Asked Questions

### Why are some compounds missing from the final database?

**Reasons:**

1. **No chemical classification** — Compounds without entry in `confirm_class_CURATED.xlsx` are excluded
2. **No gene match** — Compounds without any associated KO entries are excluded
3. **Invalid Compound ID** — IDs not matching KEGG format (C#####) are filtered out

**Solution:** Review [Input Data Files](input-data.md) and ensure all compounds have required metadata.

---

### Can I run the pipeline offline?

**No.** Pipeline requires internet access to query KEGG REST API. Offline execution is not supported in v1.0.0.

**Future releases** may support cached KEGG data for offline use.

---

### Why do row counts differ from expected 10,869?

**Possible reasons:**

1. **Modified input files** — Changes to agency lists or curations alter output
2. **Updated KEGG data** — Re-downloading KEGG references yields different results over time
3. **Incomplete execution** — Pipeline terminated early due to error

**Verify:**

```r
# Check final row count
nrow(db)

# Compare to expected
expected <- 10869
if (nrow(db) != expected) {
  warning("Row count differs from expected: ", nrow(db), " vs ", expected)
}
```

---

### How often should I update KEGG reference files?

**Recommendation:** Annually, or when significant KEGG updates occur

**KEGG updates:**

- **Weekly:** Pathway and molecule additions
- **Monthly:** Major updates to KO groups
- **Quarterly:** Significant database restructuring

**Update protocol:** See [Input Data Files - Update Protocol](input-data.md#update-protocol)

---

## Questions Not Answered Here?

**Documentation:**

- [Installation Guide](../getting-started/installation.md)
- [User Guide Overview](overview.md)
- [Input Data Files](input-data.md)
- [Understanding Output](understanding-output.md)

**Support:**

- **GitHub Issues:** [https://github.com/BioRemPP/biorempp_db/issues](https://github.com/BioRemPP/biorempp_db/issues)
- **Email:** biorempp@gmail.com
