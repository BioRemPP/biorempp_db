<!--
Page status: verified
Audience: operators, maintainers, reviewers
Applies to: Snakemake and GX
Version scope: Snakemake output contract v1.1.0 and GX validator v1.1.0
Last verified on: 2026-06-24
Primary sources:
- biorempp_snakemake_version/env/docker-compose.yml
- biorempp_snakemake_version/env/Dockerfile
- biorempp_snakemake_version/env/python-requirements.txt
- biorempp_snakemake_version/env/r-packages.txt
- biorempp_validation/env/Dockerfile
- biorempp_snakemake_version/config/config.yaml
- biorempp_snakemake_version/workflow/lib/io_contracts.R
- biorempp_snakemake_version/workflow/scripts/generation/00_check_inputs.R
- requirements.txt
- input_data directory listing
-->

# Requirements

The documented BioRemPP workflow is containerized and expects the curated input contract to be complete before execution starts.

## System Requirements

To run the Snakemake workflow and the GX validator as documented in this site, you need:

- Docker with access to the `docker compose` command
- a writable local checkout of the repository
- outbound network access to `https://rest.kegg.jp`
- the required curated input files in the repository-root `input_data/` directory

The official onboarding path assumes Docker-first execution. This keeps the workflow runtime, validator runtime, and dependency resolution aligned with the checked-in compose and Dockerfile definitions.

## Required Curated Inputs

The current workflow contract requires these exact filenames:

- `kegglistcompounds.xlsx`
- `curated_regulated_compounds.xlsx`
- `curated_programatic_missing_compounds.xlsx`
- `curated_compound_classes.xlsx`
- `kegglistko.txt`
- `curated_enzyem_names_extracted.txt`

The preflight rule `preflight_check_inputs` stops execution if any of these files is missing.

## Runtime Environment Expectations

The checked-in workflow is modest in shape but still depends on a stable local environment:

- enough free disk space for container builds, intermediate files, logs, and result artifacts
- enough memory for the R-based generation steps, the Snakemake process, and the validator container
- a stable network connection during KEGG fetch steps
- permission to create or update `biorempp_snakemake_version/results/`, `biorempp_snakemake_version/work/`, and `biorempp_snakemake_version/logs/`

If the machine is resource-constrained, prefer fewer workflow cores rather than assuming the default helper-script setting is always appropriate.

## Runtime Definition

The repository defines two containerized services in `biorempp_snakemake_version/env/docker-compose.yml`:

| Service | Role | Default command |
|---|---|---|
| `snakemake` | runs the database generation workflow | `snakemake --snakefile Snakefile --configfile config/config.yaml --cores 2 --printshellcmds` |
| `validation` | runs the GX validator against generated outputs | `biorempp-validate --config biorempp_validation/config/validation.yaml` |

## Pinned Workflow Environment

The Snakemake image is built from `biorempp_snakemake_version/env/Dockerfile` and currently pins:

- `snakemake==8.30.0`
- `pulp==2.7.0`
- the R package versions listed in `biorempp_snakemake_version/env/r-packages.txt`

The validator image is built from `biorempp_validation/env/Dockerfile` and installs the locked Python environment defined by:

- `biorempp_validation/requirements-dev.lock.txt`
- `biorempp_validation/pyproject.toml`

## Verified Prerequisite Checks

Before the first run, verify at minimum:

### Docker availability

```powershell
docker info
```

```powershell
docker compose version
```

### Curated input presence

```powershell
Get-ChildItem input_data | Select-Object Name
```

### Writable workspace expectation

The helper scripts create or reuse:

- `biorempp_snakemake_version/results/`
- `biorempp_snakemake_version/work/`
- `biorempp_snakemake_version/logs/`

If those directories cannot be created or updated, execution will fail before the run is complete.

### Network reachability

```powershell
curl.exe -I https://rest.kegg.jp/info/kegg
```

The workflow depends on KEGG REST access during generation and the integrated validation layer also relies on KEGG-linked checks.

## Offline Execution Boundary

The official workflow should be treated as network-dependent. The checked-in generation path fetches KEGG data during execution, so this documentation does not present offline execution as a supported first-run mode.

If a team later develops a controlled cached-run procedure, that procedure should be documented explicitly from the active implementation rather than inferred from historical behavior.

## Optional Documentation Tooling

If you want to build this documentation locally, install the root documentation dependencies:

- `mkdocs`
- `mkdocs-material`
- `mkdocs-minify-plugin`
- `pymdown-extensions`
- `Pygments`

These packages are defined in the repository-root `requirements.txt`.

## Platform Notes

The documentation and helper scripts assume:

- Docker can mount the repository workspace correctly
- the local shell can invoke `docker compose`
- line endings and path separators do not change the required curated filenames

Most operator-facing failures are therefore environment or runtime issues rather than schema-definition issues. Platform-specific troubleshooting belongs in [Troubleshooting](../user-guide/troubleshooting.md).

## Next Step

Continue to [Installation](installation.md) to prepare the environment and verify the input directory before the first run.
