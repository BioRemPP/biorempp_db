<!--
Page status: verified
Audience: researchers, operators, maintainers, reviewers
Applies to: Snakemake and GX
Version scope: repository contract v1.1.0
Last verified on: 2026-06-24
Primary sources:
- repository root directory listing
- biorempp_snakemake_version/Snakefile
- biorempp_snakemake_version/config/config.yaml
- biorempp_validation/config/validation.yaml
- biorempp_validation/pyproject.toml
- mkdocs.yml
-->

# Project Scope

BioRemPP assembles a knowledge integration resource linking regulated environmental compounds to KEGG-annotated genes, enzymes, and biochemical reactions relevant to bioremediation. The database supports functional annotation of bioremediation potential in genomic and metagenomic contexts. The scope below defines what the repository generates, validates, and documents as part of its official release contract.

The current implementation boundary covers the modular Snakemake workflow, the companion GX validator, and the documentation required to operate and review both surfaces.

## In Scope

The active repository contract covers four surfaces:

| Surface | Location | Current purpose |
|---|---|---|
| Database generation | `biorempp_snakemake_version/` | assemble release outputs from curated local inputs plus KEGG REST data |
| Pipeline-integrated validation | `biorempp_snakemake_version/workflow/rules/30_validation.smk` | generate KEGG-linked validation reports as part of the Snakemake DAG |
| Standalone data validation | `biorempp_validation/` | run Great Expectations checks and regression detection against pipeline outputs |
| Official documentation | `docs/`, `mkdocs.yml` | publish the verified contract, workflow behavior, and validation model |

At the scientific data level, the repository currently covers:

- curated regulated compounds and agency labels
- curated compound-KO supplementation
- curated compound classes
- curated enzyme-term extraction rules
- KEGG-derived compound, KO, EC, and reaction relationships
- release-scoped database exports, analysis artifacts, metadata, and validation outputs

## What The Repository Is Not

The current implementation does not present itself as:

- a general-purpose ETL framework for arbitrary biological datasets
- a full local mirror of KEGG
- an interactive data entry application
- a public API service for serving BioRemPP records
- a substitute for domain review of biological meaning beyond the encoded pipeline and validation contracts

Those boundaries matter because the official documentation describes what the repository actually executes and verifies, not every possible downstream interpretation.

## Official Execution Path

The current official path is:

1. stage curated files in repository-root `input_data/`
2. run the Snakemake workflow in `biorempp_snakemake_version/`
3. validate the generated outputs with GX in `biorempp_validation/`
4. review the database, metadata, and validation artifacts together

This site is written around that path. Other files in the repository root should not be treated as the primary operational contract unless a dedicated documentation page explicitly promotes them.

## Scope Boundaries For Changes

A change is inside the official project scope when it affects one or more of the following:

- curated input filenames or column assumptions
- KEGG fetch behavior or identifier normalization
- exported database schema or output names
- analysis, metadata, or workflow summary artifacts
- integrated validation behavior
- GX suites, baseline expectations, or test coverage
- documentation that explains the active pipeline contract

## Current Governance Note

The repository exposes a clear execution contract, but some governance surfaces remain lightweight:

- there is no root `CONTRIBUTING.md`
- there is no dedicated root `CHANGELOG.md`
- release interpretation currently depends on version markers in config, package metadata, baselines, and git history

Those gaps do not change the pipeline contract, but they do affect how maintainers should review and communicate change.

## Related Pages

- [Overview](../index.md)
- [Pipeline Architecture Overview](../pipeline-architecture/overview.md)
- [Contributing](contributing.md)
- [Changelog And Releases](changelog-and-releases.md)
