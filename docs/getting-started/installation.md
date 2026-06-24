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

## 1. Verify Docker Availability

From the repository root, confirm that the Docker daemon is reachable:

```bash
docker info
```

The helper scripts in `biorempp_snakemake_version/scripts/` stop immediately if Docker is not running.

## 2. Verify The Input Directory

The workflow configuration sets `paths.input_dir: "../input_data"`, so the required curated files must be present in the repository-root `input_data/` directory.

PowerShell check:

```powershell
Get-ChildItem input_data | Select-Object Name
```

The preflight script `workflow/scripts/generation/00_check_inputs.R` validates that the full input contract is present before generation begins.

## 3. Build The Runtime Images

From the repository root:

```bash
docker compose -f biorempp_snakemake_version/env/docker-compose.yml build snakemake validation
```

This prepares both workflow services defined in the compose file:

- `snakemake`
- `validation`

If the images are not built in advance, `docker compose run` will build them on demand.

## 4. Optional: Install Documentation Tooling

If you want to build the MkDocs site locally, install the documentation dependencies from the repository root:

```bash
python -m pip install -r requirements.txt
```

## Common Setup Issues

### Docker is unavailable

If `docker info` fails, the helper scripts and compose commands will not start.

### The curated input set is incomplete

If any required file is missing from `input_data/`, the run stops during preflight.

### Network access to KEGG is blocked

The workflow fetches KEGG data during generation, and the integrated validation layer also refreshes KEGG link cache files.

## Next Step

Continue to [Quick Start](quick-start.md) for the shortest verified path to a full pipeline run followed by GX validation.
