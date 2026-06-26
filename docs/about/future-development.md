<!--
Page status: verified
Audience: researchers, operators, maintainers, reviewers
Applies to: Snakemake and GX
Version scope: repository contract v1.1.0
Last verified on: 2026-06-26
Primary sources:
- biorempp_snakemake_version/config/config.yaml
- biorempp_validation/pyproject.toml
- repository root directory listing
-->

# Future Development

## Current Release

BioRemPP v1.1.0 provides:

- a modular Snakemake workflow for reproducible database generation from curated local inputs and KEGG REST data
- an 11-column public schema capturing compound-KO-EC-reaction associations for 384 regulated compounds across 9 agencies
- nine JSON analysis artifacts and three metadata reports produced by each pipeline run
- a standalone Great Expectations validator with dual-mode internal consistency and regression detection
- Docker-containerized execution for both the pipeline and the validator
- versioned baseline support for regression detection against committed release snapshots

## Short-Term Directions

### Data Updates

KEGG releases approximately four times per year. Each update may introduce new orthology groups, additional reaction annotations, or updated compound-gene link assignments. Periodic regeneration against newer KEGG releases is the primary planned mechanism for keeping the database current. The configuration-driven KEGG endpoint contract and the GX regression baseline workflow are designed to support this update cycle without pipeline restructuring.

The curated agency compound lists are refreshed as regulatory frameworks evolve. Additions to the regulated compound universe or updates to agency-specific compound assignments are incorporated through the curated input files.

### Documentation

Planned documentation additions include interactive analysis examples using R Markdown or Jupyter, Snakemake profile templates for HPC and cluster environments, and structured use-case descriptions for common bioremediation annotation workflows.

## Medium-Term Directions

### Multi-Omics Integration Support

The KEGG Orthology identifier is the natural bridging key between BioRemPP and metagenomic or metatranscriptomic annotation outputs. Future development aims to provide reference materials and identifier mapping guidance that support connecting BioRemPP KO coverage with external omics annotation pipelines. BioRemPP supplies the functional reference; users integrate their own omics data.

### Community Curation

The curated compound-KO supplementation file (`curated_programatic_missing_compounds.xlsx`) is the current mechanism for adding compound-gene associations not resolvable through direct KEGG links. Structured community submission procedures for expanding this curated layer are under consideration.

## Constraints

Development priorities depend on funding availability and team capacity. Items listed under short-term and medium-term directions represent intended directions, not scheduled commitments. Version numbers used in this documentation are illustrative of scope and may differ from actual release identifiers.

## How To Contribute

Contributions and feedback can be submitted through:

- GitHub Issues for bug reports, feature requests, and curation proposals at `https://github.com/BioRemPP/biorempp_db/issues`
- GitHub Discussions for community input on roadmap priorities and use cases

## Related Pages

- [Project Scope](project-scope.md)
- [Contributing](contributing.md)
- [Changelog And Releases](changelog-and-releases.md)
