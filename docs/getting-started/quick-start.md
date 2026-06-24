<!--
Page status: verified
Audience: operators, reviewers
Applies to: Snakemake and GX
Version scope: Snakemake output contract v1.1.0 and GX validator v1.1.0
Last verified on: 2026-06-24
Primary sources:
- biorempp_snakemake_version/env/docker-compose.yml
- biorempp_snakemake_version/scripts/run_snakemake.sh
- biorempp_snakemake_version/scripts/run_snakemake.bat
- biorempp_snakemake_version/Snakefile
- biorempp_snakemake_version/config/config.yaml
- biorempp_snakemake_version/workflow/lib/io_contracts.R
- biorempp_validation/config/validation.yaml
- input_data directory listing
Observed artifacts:
- biorempp_validation/results/validation_summary.json
-->

# Quick Start

This page provides the shortest verified path to a complete BioRemPP run: generate the database with Snakemake, then validate the outputs with GX.

## 1. Confirm The Curated Input Contract

The repository-root `input_data/` directory must contain:

- `kegglistcompounds.xlsx`
- `curated_regulated_compounds.xlsx`
- `curated_programatic_missing_compounds.xlsx`
- `curated_compound_classes.xlsx`
- `kegglistko.txt`
- `curated_enzyem_names_extracted.txt`

Quick check:

```powershell
Get-ChildItem input_data | Select-Object Name
```

## 2. Run The Snakemake Workflow

Choose one of the supported entry points below.

### Windows

```bat
biorempp_snakemake_version\scripts\run_snakemake.bat 2
```

### POSIX

```bash
./biorempp_snakemake_version/scripts/run_snakemake.sh 2
```

### Direct Compose Invocation

```bash
docker compose -f biorempp_snakemake_version/env/docker-compose.yml run --rm snakemake
```

The helper scripts create the expected `results/`, `work/`, and `logs/` directories before invoking the workflow.

## 3. Run The GX Validator

From the repository root:

```bash
docker compose -f biorempp_snakemake_version/env/docker-compose.yml run --rm validation
```

The validator reads the Snakemake results tree and applies both configured validation modes:

- `internal_consistency`
- `regression_detection`

## 4. Inspect The Main Outputs

After a successful run, inspect at minimum:

- `biorempp_snakemake_version/results/database/biorempp_database_v1.1.0.csv`
- `biorempp_snakemake_version/results/database/biorempp_database_v1.1.0.xlsx`
- `biorempp_snakemake_version/results/analysis/complete_analysis.json`
- `biorempp_snakemake_version/results/metadata/kegg_release.json`
- `biorempp_snakemake_version/results/reports/workflow_summary.json`
- `biorempp_validation/results/validation_summary.json`

## 5. Confirm Validation Outcome

`biorempp_validation/results/validation_summary.json` is the primary validator summary artifact. Review it immediately after each run to confirm whether any critical or warning expectations failed.

## Common First-Run Mistakes

- starting the workflow with an incomplete curated input set
- relying on stale filenames from older prose instead of the current input contract
- skipping GX validation and assuming workflow generation alone is sufficient verification
