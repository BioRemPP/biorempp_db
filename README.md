# BioRemPP Database v1.1.0

BioRemPP is a reproducible, API-first data pipeline that builds a curated bioremediation knowledge base by integrating KEGG links, curated environmental compound references, and modular analytics.  
The current release (`v1.1.0`) is generated with Snakemake, exported as CSV/XLSX, validated with dual compliance layers, and published with traceable KEGG metadata.

## Current Release Status (v1.1.0)

- Active contract version: `v1.1.0`
- Canonical database outputs:
  - `biorempp_snakemake_version/results/database/biorempp_database_v1.1.0.csv`
  - `biorempp_snakemake_version/results/database/biorempp_database_v1.1.0.xlsx`
- Pipeline summary artifact:
  - `biorempp_snakemake_version/results/reports/workflow_summary.json`
- Validation status (latest generated artifacts):
  - `policy_union_rate_percent: 100.0`
  - `no_policy_support: 0`
  - Great Expectations critical failures: `0`

## Architecture At A Glance

BioRemPP uses a modular Snakemake DAG with four major blocks:

1. Generation (`workflow/rules/10_generation.smk`)
2. Analysis (`workflow/rules/20_analysis.smk`)
3. Validation (`workflow/rules/30_validation.smk`)
4. Reporting (`workflow/rules/90_reporting.smk`)

Design principles:
- API-first KEGG ingestion at runtime (`https://rest.kegg.jp`)
- Contract-driven outputs (`v1.1.0` schema)
- Traceability (`kegg_release.json`, hashes in `workflow_summary.json`)
- Reproducibility via containerized environment

## Quick Start

### Recommended (Docker)

From repository root:

```bash
cd biorempp_snakemake_version
docker compose -f env/docker-compose.yml run --rm snakemake
```

### Validate Outputs (Docker)

From repository root:

```bash
docker compose -f biorempp_snakemake_version/env/docker-compose.yml build validation
docker compose -f biorempp_snakemake_version/env/docker-compose.yml run --rm validation
```

### Dry Run (DAG check)

```bash
cd biorempp_snakemake_version
docker compose -f env/docker-compose.yml run --rm snakemake \
  snakemake -n --snakefile Snakefile --configfile config/config.yaml --cores 1
```

### Local Execution (without container)

```bash
cd biorempp_snakemake_version
snakemake --snakefile Snakefile --configfile config/config.yaml --cores 4
```

## Required Inputs

Place required files under repository-root `input_data/` (default configured input root):

- `kegglistcompounds.xlsx`
- `compostos_todasagencias.xlsx`
- `missing_compounds_founds_curated.xlsx`
- `confirm_class_CURATED.xlsx`
- `kegglistko.txt`
- `enzymes_unique.txt`

## Output Contract (v1.1.0)

### Database Files

- `biorempp_database_v1.1.0.csv`
- `biorempp_database_v1.1.0.xlsx`

CSV contract:
- delimiter: `;`
- quote enabled
- NA token: `NA`

### Database Schema (11 columns)

1. `cpd`
2. `compoundclass`
3. `ko`
4. `ec`
5. `reaction`
6. `reaction_description`
7. `referenceAG`
8. `compoundname`
9. `genesymbol`
10. `genename`
11. `enzyme_activity`

Notes:
- `reaction_description` is populated from KEGG `list/reaction`.
- Reaction equation text is preserved (including `<=>`).

### Analysis and Metadata Outputs

Generated under `biorempp_snakemake_version/results`:
- `analysis/*.json` (modular statistics + `complete_analysis.json`)
- `metadata/kegg_release.json`
- `metadata/keys_consistency_report.json`
- `metadata/links_groundtruth_policy_report.json`
- `reports/workflow_summary.json`

## Validation And Compliance

BioRemPP validation runs in two layers:

1. Pipeline-integrated API validators
- `keys_consistency` (NA consistency and key-level compliance)
- `policy-aware groundtruth` (link annotation vs KEGG API)

2. External Great Expectations project
- Located in `biorempp_validation`
- Enforces schema, analysis consistency, metadata integrity, and cross-checks
- Runs in a dedicated Docker service with pinned Python dependencies

Interpretation rule:
- `strict5` is a strict simultaneous 5-link criterion and is expected to be lower.
- Operational acceptance for dense-link compatibility is based on `policy_union`.

## Modeling Semantics

The current data model is evidence-union and policy-aware:

- `ko_complete`: dense rows supported by KO-consistent EC+reaction paths
- `ko_fallback`: KO-supported fallback when complete tuple is unavailable
- `compound_bridge`: compound-mediated linkage path

Important:
- Some `ko-ec` pairs may appear through compound-mediated evidence and may not be direct `link/ko/ec` annotations.
- This is a modeling decision, not necessarily a parse error.

## Reproducibility

Reproducibility assets are versioned:

- `biorempp_snakemake_version/env/Dockerfile`
- `biorempp_snakemake_version/env/docker-compose.yml`
- `biorempp_snakemake_version/env/python-requirements.txt`
- `biorempp_snakemake_version/env/r-packages.txt`
- `biorempp_validation/env/Dockerfile`
- `biorempp_validation/requirements.lock.txt`
- `biorempp_validation/requirements-dev.lock.txt`

KEGG traceability is captured per run:
- release endpoint: `https://rest.kegg.jp/info/kegg`
- artifact: `results/metadata/kegg_release.json`

## Project Layout

```text
BioRemPP_DB_1.0.0/
|-- README.md
|-- README_DEPRECATED.md
|-- input_data/
|-- biorempp_snakemake_version/
|   |-- Snakefile
|   |-- config/
|   |-- workflow/
|   |-- env/
|   |-- scripts/
|   `-- results/
|-- biorempp_validation/
|   |-- config/
|   |-- great_expectations/
|   |-- src/
|   `-- tests/
`-- .archive/
    `-- V1.1.0/
```

## Troubleshooting

- Missing inputs:
  - verify files in `input_data/` at repository root.
- KEGG connectivity errors:
  - check network/proxy/VPN and retry environment settings.
- Divergent local behavior:
  - prefer Docker execution for deterministic runtime.
- Validation failures:
  - inspect:
    - `biorempp_snakemake_version/results/metadata/*.json`
    - `biorempp_validation/results/validation_summary.json`
  - rerun the validator in the `validation` Docker service to reproduce the pinned runtime

## Documentation Map

- Pipeline technical README: `biorempp_snakemake_version/README.md`
- Historical context and backlog: `.archive/V1.1.0/docs/00_INDEX.md`
- Validation framework guide: `biorempp_validation/README.md`

Legacy note:
- `README_DEPRECATED.md` is kept as historical material and changelog input, not as active contract documentation.
