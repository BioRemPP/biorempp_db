<!--
Page status: verified
Audience: operators, researchers, maintainers, reviewers
Applies to: Snakemake and GX
Version scope: Snakemake output contract v1.1.0 and GX validator v1.1.0
Last verified on: 2026-06-24
Primary sources:
- mkdocs.yml
- biorempp_snakemake_version/Snakefile
- biorempp_snakemake_version/config/config.yaml
- biorempp_snakemake_version/workflow/rules/10_generation.smk
- biorempp_snakemake_version/workflow/rules/20_analysis.smk
- biorempp_snakemake_version/workflow/rules/30_validation.smk
- biorempp_snakemake_version/workflow/rules/90_reporting.smk
- biorempp_validation/config/validation.yaml
-->

# BioRemPP Database

BioRemPP provides a reproducible workflow for generating a biological remediation database from curated local inputs and KEGG REST data. The active implementation is the modular Snakemake pipeline in `biorempp_snakemake_version/`, with a companion Great Expectations validation layer in `biorempp_validation/`.

## What This Pipeline Produces

Each complete Snakemake run produces four output families:

- database exports in `results/database/`
- analytical summaries in `results/analysis/`
- provenance and validation metadata in `results/metadata/`
- a run-level summary in `results/reports/workflow_summary.json`

The release-scoped database contract is currently:

- `results/database/biorempp_database_v1.1.0.csv`
- `results/database/biorempp_database_v1.1.0.xlsx`

## Reproducible Workflow

The pipeline is organized into five layers declared in `Snakefile`:

1. preflight input verification
2. data generation and enrichment
3. analytical summarization
4. integrated validation
5. final reporting

This structure makes the execution order explicit and keeps generated outputs tied to versioned configuration, pinned environments, and run metadata.

## Validation Model

Validation is split into two complementary layers.

### Pipeline-integrated validation

The Snakemake workflow includes dedicated validation rules in `workflow/rules/30_validation.smk`. These rules generate:

- `results/metadata/keys_consistency_report.json`
- `results/metadata/links_groundtruth_policy_report.json`

### Standalone GX validation

The companion validator reads the Snakemake results tree and applies two active validation modes:

- `internal_consistency`
- `regression_detection`

Its configuration is defined in `biorempp_validation/config/validation.yaml`, and its outputs are written to `biorempp_validation/results/`.

## Why This Documentation Is Structured This Way

Scientific pipeline documentation needs to do more than describe commands. It must preserve:

- exact input contracts
- exact output names
- provenance and release semantics
- validation behavior
- the boundary between generated artifacts and interpretation

For that reason, the official pages are written from executable rules, configuration files, and generated artifacts rather than from historical prose alone.

## Start Here

If you are setting up BioRemPP for the first time, continue in this order:

1. [Overview](getting-started/overview.md)
2. [Requirements](getting-started/requirements.md)
3. [Installation](getting-started/installation.md)
4. [Quick Start](getting-started/quick-start.md)
