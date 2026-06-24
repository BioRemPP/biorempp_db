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

## Required Curated Inputs

The current workflow contract requires these exact filenames:

- `kegglistcompounds.xlsx`
- `curated_regulated_compounds.xlsx`
- `curated_programatic_missing_compounds.xlsx`
- `curated_compound_classes.xlsx`
- `kegglistko.txt`
- `curated_enzyem_names_extracted.txt`

The preflight rule `preflight_check_inputs` stops execution if any of these files is missing.

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

## Optional Documentation Tooling

If you want to build this documentation locally, install the root documentation dependencies:

- `mkdocs`
- `mkdocs-material`
- `mkdocs-minify-plugin`
- `pymdown-extensions`
- `Pygments`

These packages are defined in the repository-root `requirements.txt`.

## Next Step

Continue to [Installation](installation.md) to prepare the environment and verify the input directory before the first run.
