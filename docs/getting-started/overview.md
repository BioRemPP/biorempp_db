<!--
Page status: verified
Audience: operators, maintainers, reviewers
Applies to: Snakemake and GX
Version scope: Snakemake output contract v1.1.0 and GX validator v1.1.0
Last verified on: 2026-06-24
Primary sources:
- mkdocs.yml
- biorempp_snakemake_version/Snakefile
- biorempp_snakemake_version/config/config.yaml
- biorempp_validation/config/validation.yaml
- repository root directory listing
-->

# Overview

This section introduces the active BioRemPP execution path: the Snakemake pipeline for database generation and the standalone GX validator for post-run checks.

## Repository Layout

The main directories involved in a standard run are:

- `biorempp_snakemake_version/`
  - modular workflow, configuration, environments, helper scripts, and generated results
- `biorempp_validation/`
  - standalone validation project for the Snakemake outputs
- `input_data/`
  - canonical curated input directory used by the workflow
- `docs/`
  - source files for the official MkDocs site

The pipeline input directory is configured as `../input_data` in `biorempp_snakemake_version/config/config.yaml`, which resolves to the repository-root `input_data/`.

## Recommended Execution Path

For a first reproducible run, use the following order:

1. verify the curated inputs in `input_data/`
2. execute the Snakemake workflow
3. run the GX validator against the generated results
4. inspect the database, analysis, metadata, and reporting artifacts

This sequence matches the current repository contract and keeps validation tied to the exact outputs that were generated.

## What You Will Find In The Outputs

The Snakemake run produces:

- release-scoped database files in `results/database/`
- analysis JSON files in `results/analysis/`
- KEGG and validation metadata in `results/metadata/`
- a workflow-level summary in `results/reports/`

The GX validator then writes its own results under `biorempp_validation/results/`.

## How This Documentation Is Organized

The Getting Started section is intentionally practical:

- [Requirements](requirements.md) defines the runtime prerequisites and input contract
- [Installation](installation.md) shows how to prepare the execution environment
- [Quick Start](quick-start.md) gives the shortest verified command path for a full run
