# Configuration Reference

This document provides a complete reference for the `config/config.yaml` file that drives the BioRemPP Snakemake pipeline.

---

## Overview

All pipeline behavior is parameterized through a single YAML configuration file located at `biorempp_snakemake_version/config/config.yaml`. The Snakefile loads this file and derives all path variables, output filenames, KEGG API URLs, and analysis parameters from it.

**No hardcoded values exist in any script** — every path, URL, and threshold is controlled by this configuration.

---

## Configuration Structure

```yaml
# config/config.yaml — full structure
version: "1.0.0"

paths:
  input_dir: "../input_data"
  results_dir: "results"
  work_dir: "work"
  logs_dir: "logs"

outputs:
  database_csv: "biorempp_database_v1.0.0.csv"
  database_xlsx: "biorempp_database_v1.0.0.xlsx"

kegg:
  base_url: "https://rest.kegg.jp"
  endpoints:
    ko_ec_links: "link/ko/ec"
    ko_reaction_links: "link/ko/reaction"
    compound_ec_links: "link/compound/ec"
    compound_reaction_links: "link/cpd/reaction"
    compound_list: "list/cpd/"
  info_endpoint: "info/kegg"

analysis:
  top_n_compounds: 20
  top_n_ko: 20
  top_n_enzymes: 30
```

---

## Key-by-Key Reference

### `version`

| Property | Value |
|----------|-------|
| **Type** | String |
| **Default** | `"1.0.0"` |
| **Used by** | Output filenames, metadata reports |

The database version string. Embedded in output filenames (e.g., `biorempp_database_v1.0.0.csv`) and metadata JSON files.

---

### `paths`

Controls where the pipeline reads inputs and writes outputs. All paths are relative to the Snakemake working directory (`biorempp_snakemake_version/`).

#### `paths.input_dir`

| Property | Value |
|----------|-------|
| **Type** | String (relative path) |
| **Default** | `"../input_data"` |
| **Used by** | Preflight check, `load_local_data` |

Directory containing the 6 mandatory input files. The default `../input_data` points to the repository root's `input_data/` folder.

#### `paths.results_dir`

| Property | Value |
|----------|-------|
| **Type** | String (relative path) |
| **Default** | `"results"` |
| **Used by** | All output rules |

Root directory for all final outputs. Contains subdirectories: `database/`, `metadata/`, `analysis/`, `reports/`.

#### `paths.work_dir`

| Property | Value |
|----------|-------|
| **Type** | String (relative path) |
| **Default** | `"work"` |
| **Used by** | All generation rules producing `.rds` intermediates |

Directory for intermediate artifacts (`.rds` files, `preflight_ok.json`). These files are ephemeral and can be safely deleted after a successful run.

#### `paths.logs_dir`

| Property | Value |
|----------|-------|
| **Type** | String (relative path) |
| **Default** | `"logs"` |
| **Used by** | Snakemake log directives |

Directory for log files produced by each rule.

---

### `outputs`

Controls the filenames of the final database files.

#### `outputs.database_csv`

| Property | Value |
|----------|-------|
| **Type** | String |
| **Default** | `"biorempp_database_v1.0.0.csv"` |

Filename for the CSV database output, placed under `{results_dir}/database/`.

#### `outputs.database_xlsx`

| Property | Value |
|----------|-------|
| **Type** | String |
| **Default** | `"biorempp_database_v1.0.0.xlsx"` |

Filename for the Excel database output, placed under `{results_dir}/database/`.

---

### `kegg`

Controls KEGG REST API interaction.

#### `kegg.base_url`

| Property | Value |
|----------|-------|
| **Type** | String (URL) |
| **Default** | `"https://rest.kegg.jp"` |

Base URL for all KEGG REST API queries. Change this only if using a local KEGG mirror.

#### `kegg.endpoints`

Five endpoint paths appended to `base_url`:

| Key | Default Value | HTTP Target | Description |
|-----|--------------|-------------|-------------|
| `ko_ec_links` | `link/ko/ec` | `rest.kegg.jp/link/ko/ec` | KO ↔ EC number relationships |
| `ko_reaction_links` | `link/ko/reaction` | `rest.kegg.jp/link/ko/reaction` | KO ↔ Reaction relationships |
| `compound_ec_links` | `link/compound/ec` | `rest.kegg.jp/link/compound/ec` | Compound ↔ EC relationships |
| `compound_reaction_links` | `link/cpd/reaction` | `rest.kegg.jp/link/cpd/reaction` | Compound ↔ Reaction relationships |
| `compound_list` | `list/cpd/` | `rest.kegg.jp/list/cpd/` | Full compound list with names |

#### `kegg.info_endpoint`

| Property | Value |
|----------|-------|
| **Type** | String |
| **Default** | `"info/kegg"` |

Endpoint for fetching the KEGG release version. Used by `fetch_kegg_info` rule.

---

### `analysis`

Controls thresholds for the statistical analysis layer.

#### `analysis.top_n_compounds`

| Property | Value |
|----------|-------|
| **Type** | Integer |
| **Default** | `20` |
| **Used by** | `compound_statistics` rule |

Number of top compounds to include in compound statistics rankings.

#### `analysis.top_n_ko`

| Property | Value |
|----------|-------|
| **Type** | Integer |
| **Default** | `20` |
| **Used by** | `ko_statistics` rule |

Number of top KO entries to include in KO statistics rankings.

#### `analysis.top_n_enzymes`

| Property | Value |
|----------|-------|
| **Type** | Integer |
| **Default** | `30` |
| **Used by** | `enzyme_statistics` rule |

Number of top enzyme activities to include in enzyme statistics rankings.

---

## Customization Scenarios

### Changing Output Version

To generate a database tagged as v1.1.0:

```yaml
version: "1.1.0"
outputs:
  database_csv: "biorempp_database_v1.1.0.csv"
  database_xlsx: "biorempp_database_v1.1.0.xlsx"
```

### Using a Different Input Directory

To point to a custom input location:

```yaml
paths:
  input_dir: "/data/biorempp/custom_inputs"
```

### Increasing Analysis Depth

To show top-50 compounds and top-50 enzymes in reports:

```yaml
analysis:
  top_n_compounds: 50
  top_n_ko: 50
  top_n_enzymes: 50
```

### Using a Local KEGG Mirror

If running behind a firewall with a local KEGG mirror:

```yaml
kegg:
  base_url: "http://localhost:8080/kegg"
```

---

## How Config is Loaded

The `Snakefile` loads the configuration and derives variables:

```python
configfile: "config/config.yaml"

# Derived variables
INPUT_DIR     = config["paths"]["input_dir"]
RESULTS_DIR   = config["paths"]["results_dir"]
WORK_DIR      = config["paths"]["work_dir"]
DATABASE_CSV  = f"{RESULTS_DIR}/database/{config['outputs']['database_csv']}"
DATABASE_XLSX = f"{RESULTS_DIR}/database/{config['outputs']['database_xlsx']}"
# ... etc
```

These variables are then referenced in rule definitions, ensuring that all rules use consistent path resolution driven by a single configuration source.
