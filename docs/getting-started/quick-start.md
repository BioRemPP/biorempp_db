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

For the role and loading rules of each file, see [Input Data Contract](../user-guide/input-data.md).

Quick check:

```powershell
Get-ChildItem input_data | Select-Object Name
```

## 2. Dry-Run The Workflow

Before the first full execution, validate that the DAG resolves from the current config:

```powershell
docker compose -f biorempp_snakemake_version/env/docker-compose.yml run --rm snakemake snakemake --snakefile Snakefile --configfile config/config.yaml --dry-run
```

This should enumerate the planned work without materializing outputs. If this step fails, fix the input or runtime issue before continuing.

On POSIX shells, the same command may also be written with line continuation, but the one-line form above is the safest cross-shell example for the official docs.

## 3. Run The Snakemake Workflow

Use one of the supported PowerShell-safe entry points below.

### PowerShell helper script

```powershell
.\biorempp_snakemake_version\scripts\run_snakemake.bat 2
```

### Direct Compose Invocation

```powershell
docker compose -f biorempp_snakemake_version/env/docker-compose.yml run --rm snakemake
```

The helper scripts create the expected `biorempp_snakemake_version/results/`, `biorempp_snakemake_version/work/`, and `biorempp_snakemake_version/logs/` directories before invoking the workflow.

The repository also contains a POSIX helper script at `biorempp_snakemake_version/scripts/run_snakemake.sh`, but the official executable examples in this site are written for PowerShell to keep shell behavior unambiguous.

## 4. Run The GX Validator

From the repository root:

```powershell
docker compose -f biorempp_snakemake_version/env/docker-compose.yml run --rm validation
```

The validator reads the Snakemake results tree and applies both configured validation modes:

- `internal_consistency`
- `regression_detection`

## 5. Confirm The Main Output Families

After a successful run, confirm that the expected output families exist:

- `biorempp_snakemake_version/results/database/`
- `biorempp_snakemake_version/results/analysis/`
- `biorempp_snakemake_version/results/metadata/`
- `biorempp_snakemake_version/results/reports/`
- `biorempp_validation/results/`

This is the first sanity check that generation, integrated validation, reporting, and GX validation all produced artifacts in their expected locations.

## 6. Inspect The Main Outputs

After a successful run, inspect at minimum:

- `biorempp_snakemake_version/results/database/biorempp_database_v1.1.0.csv`
- `biorempp_snakemake_version/results/database/biorempp_database_v1.1.0.xlsx`
- `biorempp_snakemake_version/results/analysis/complete_analysis.json`
- `biorempp_snakemake_version/results/metadata/kegg_release.json`
- `biorempp_snakemake_version/results/reports/workflow_summary.json`
- `biorempp_validation/results/validation_summary.json`

## 7. Perform A First Inspection

Use the first inspection to answer five practical questions:

- did the workflow produce the release-scoped CSV and XLSX exports
- did the analysis layer produce `complete_analysis.json`
- did metadata capture the KEGG release used by the run
- did the workflow summary materialize in `results/reports/`
- did GX finish and write `validation_summary.json`

These checks are intentionally artifact-based. They confirm that the current contract was executed without relying on frozen row counts or legacy schema assumptions.

## 8. Confirm Validation Outcome

`biorempp_validation/results/validation_summary.json` is the primary validator summary artifact. Review it immediately after each run to confirm whether any critical or warning expectations failed.

## Common First-Run Mistakes

- starting the workflow with an incomplete curated input set
- relying on stale filenames from older prose instead of the current input contract
- skipping GX validation and assuming workflow generation alone is sufficient verification

## What To Read Next

- use [Running The Snakemake Pipeline](../user-guide/run-snakemake.md) for rerun and entry-point details
- use [Understanding Outputs](../user-guide/understanding-output.md) to interpret the generated artifacts
- use [Troubleshooting](../user-guide/troubleshooting.md) if dry-run, execution, or validation behavior is unexpected
