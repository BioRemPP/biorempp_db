<!--
Page status: verified
Audience: operators, maintainers
Applies to: Snakemake and GX
Version scope: Snakemake output contract v1.1.0 and GX validator v1.1.0
Last verified on: 2026-06-24
Primary sources:
- biorempp_snakemake_version/env/docker-compose.yml
- biorempp_snakemake_version/scripts/run_snakemake.sh
- biorempp_snakemake_version/scripts/run_snakemake.bat
- biorempp_snakemake_version/config/config.yaml
- biorempp_snakemake_version/workflow/scripts/generation/00_check_inputs.R
- requirements.txt
-->

# Installation

This page prepares the execution environment for the active BioRemPP workflow.

The documented installation path is Docker-first. That is the only path this page treats as an official onboarding default, because it matches the checked-in compose services, helper scripts, and validator runtime.

## 1. Verify Docker Availability

From the repository root, confirm that the Docker daemon is reachable:

```powershell
docker info
```

The helper scripts in `biorempp_snakemake_version/scripts/` stop immediately if Docker is not running.

You may also confirm that Compose is available:

```powershell
docker compose version
```

## 2. Verify The Input Directory

The workflow configuration sets `paths.input_dir: "../input_data"`, so the required curated files must be present in the repository-root `input_data/` directory.

PowerShell check:

```powershell
Get-ChildItem input_data | Select-Object Name
```

The preflight script `workflow/scripts/generation/00_check_inputs.R` validates that the full input contract is present before generation begins.

## 3. Build The Runtime Images

From the repository root:

```powershell
docker compose -f biorempp_snakemake_version/env/docker-compose.yml build snakemake validation
```

This prepares both workflow services defined in the compose file:

- `snakemake`
- `validation`

If the images are not built in advance, `docker compose run` will build them on demand.

## 4. Verify The Expected Workspace Shape

The repository-root documentation perspective maps to these runtime areas:

- curated inputs in `input_data/`
- workflow code in `biorempp_snakemake_version/`
- workflow outputs in `biorempp_snakemake_version/results/`
- workflow intermediates in `biorempp_snakemake_version/work/`
- workflow logs in `biorempp_snakemake_version/logs/`
- validator outputs in `biorempp_validation/results/`

The helper scripts create the workflow result, work, and log directories before invoking Snakemake. If your environment prevents those directories from being created, fix that before attempting a full run.

## 5. Run A Post-Setup Validation Checklist

Before the first real execution, confirm:

- `docker info` succeeds
- `docker compose -f biorempp_snakemake_version/env/docker-compose.yml build snakemake validation` completes
- `input_data/` contains the full curated contract
- the repository workspace is writable

At that point you are ready for the dry-run and first full execution described in [Quick Start](quick-start.md).

## 6. Optional: Install Documentation Tooling

If you want to build the MkDocs site locally, install the documentation dependencies from the repository root:

```powershell
python -m pip install -r requirements.txt
```

## Common Setup Issues

### Docker is unavailable

If `docker info` fails, the helper scripts and compose commands will not start.

### The curated input set is incomplete

If any required file is missing from `input_data/`, the run stops during preflight.

### Network access to KEGG is blocked

The workflow fetches KEGG data during generation, and the integrated validation layer also refreshes KEGG link cache files.

### The workspace is mounted but not writable

If Docker can see the repository but the run cannot create files inside `biorempp_snakemake_version/results/`, `work/`, or `logs/`, fix the local filesystem or Docker Desktop sharing configuration before retrying.

## Next Step

Continue to [Quick Start](quick-start.md) for the shortest verified path to a full pipeline run followed by GX validation.
