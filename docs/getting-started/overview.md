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

This section introduces the active BioRemPP execution path: the Snakemake pipeline for database generation and the standalone GX validator for post-run checks. Its purpose is to help first-time readers choose the right starting path before they run or review anything.

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

## Path Convention Used In This Site

Unless a page explicitly says otherwise, commands and paths are described from the repository root.

That means:

- curated inputs live in `input_data/`
- workflow outputs live in `biorempp_snakemake_version/results/`
- GX outputs live in `biorempp_validation/results/`

Some runtime commands enter `biorempp_snakemake_version/` internally, but the docs keep the reader-facing path convention at the repository root to avoid ambiguity.

## Recommended Execution Path

For a first reproducible run, use the following order:

1. verify the curated inputs in `input_data/`
2. execute the Snakemake workflow
3. run the GX validator against the generated results
4. inspect the database, analysis, metadata, and reporting artifacts

This sequence matches the current repository contract and keeps validation tied to the exact outputs that were generated.

Snakemake comes first because it is the surface that materializes the database, metadata, and workflow summary. GX comes second because it validates the already-generated result tree and compares it against the checked-in expectation and baseline contract.

## Reader Paths

Choose the rest of the documentation based on what you need to do:

- operator: continue through [Requirements](requirements.md), [Installation](installation.md), and [Quick Start](quick-start.md)
- researcher: continue through [Quick Start](quick-start.md) and then [Understanding Outputs](../user-guide/understanding-output.md)
- maintainer: continue through [Requirements](requirements.md) and then [Configuration And IO Contracts](../pipeline-architecture/configuration-and-io.md)
- reviewer: continue through [Requirements](requirements.md), [Pipeline Validation Overview](../pipeline-validation/overview.md), and [Project Scope](../about/project-scope.md)

## What You Will Find In The Outputs

The Snakemake run produces:

- release-scoped database files in `biorempp_snakemake_version/results/database/`
- analysis JSON files in `biorempp_snakemake_version/results/analysis/`
- KEGG and validation metadata in `biorempp_snakemake_version/results/metadata/`
- a workflow-level summary in `biorempp_snakemake_version/results/reports/`

The GX validator then writes its own results under `biorempp_validation/results/`.

## How This Documentation Is Organized

The Getting Started section is intentionally practical:

- [Requirements](requirements.md) defines the runtime prerequisites and input contract
- [Installation](installation.md) shows how to prepare the execution environment
- [Quick Start](quick-start.md) gives the shortest verified command path for a full run
