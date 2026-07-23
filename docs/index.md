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

## Who This Site Is For

This documentation is written for four reader groups:

- operators who need the shortest correct execution path
- researchers who need to understand what the generated database represents
- maintainers who review input, configuration, or validation changes
- reviewers who need to confirm that outputs, validation artifacts, and release markers remain aligned

All pages are written from the current checked-in workflow, validator configuration, and observed results tree rather than from historical project prose.

## What This Pipeline Produces

Each complete Snakemake run produces four output families:

- database exports in `biorempp_snakemake_version/results/database/`
- analytical summaries in `biorempp_snakemake_version/results/analysis/`
- provenance and validation metadata in `biorempp_snakemake_version/results/metadata/`
- a run-level summary in `biorempp_snakemake_version/results/reports/workflow_summary.json`

See [Understanding Outputs](user-guide/understanding-output.md) for the complete artifact reference.

The release-scoped database contract is currently:

- `biorempp_snakemake_version/results/database/biorempp_database_v1.1.0.csv`
- `biorempp_snakemake_version/results/database/biorempp_database_v1.1.0.xlsx`

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

## Scope and Interpretation Boundaries

BioRemPP assembles functional gene-compound associations from KEGG annotations and curated regulatory agency lists. The scope of the repository and the boundaries of what the database does and does not establish are documented in [Project Scope](about/project-scope.md).

## Why This Documentation Is Structured This Way

Scientific pipeline documentation needs to do more than describe commands. It must preserve:

- exact input contracts
- exact output names
- provenance and release semantics
- validation behavior
- the boundary between generated artifacts and interpretation

For that reason, the official pages are written from executable rules, configuration files, and generated artifacts rather than from historical prose alone.

## Choose Your Starting Path

| I need to... | Start here |
|---|---|
| Understand the scientific rationale and database content | [Scientific Background](about/scientific-background.md) → [Database Statistics](database-reference/statistics.md) → [Schema](database-reference/schema.md) |
| Run the pipeline and generate the database | [Requirements](getting-started/requirements.md) → [Quick Start](getting-started/quick-start.md) |
| Review data quality and validation coverage | [FAIR Compliance](about/fair-compliance.md) → [Known Limitations](about/limitations.md) → [Pipeline Validation](pipeline-validation/overview.md) |
| Cite or reuse the database | [Data Availability and Citation](about/availability.md) |
| Review or modify the pipeline implementation | [Requirements](getting-started/requirements.md) → [Configuration And IO Contracts](pipeline-architecture/configuration-and-io.md) → [Baseline Management](validation-gx/baseline-management.md) |

## Start Here

If you are setting up BioRemPP for the first time, continue in this order:

1. [Overview](getting-started/overview.md)
2. [Requirements](getting-started/requirements.md)
3. [Installation](getting-started/installation.md)
4. [Quick Start](getting-started/quick-start.md)
