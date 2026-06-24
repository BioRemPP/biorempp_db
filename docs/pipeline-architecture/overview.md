<!--
Page status: verified
Audience: maintainers, reviewers, advanced operators
Applies to: Snakemake
Version scope: Snakemake output contract v1.1.0
Last verified on: 2026-06-24
Primary sources:
- biorempp_snakemake_version/Snakefile
- biorempp_snakemake_version/config/config.yaml
- biorempp_snakemake_version/workflow/rules/00_preflight.smk
- biorempp_snakemake_version/workflow/rules/10_generation.smk
- biorempp_snakemake_version/workflow/rules/20_analysis.smk
- biorempp_snakemake_version/workflow/rules/30_validation.smk
- biorempp_snakemake_version/workflow/rules/90_reporting.smk
- biorempp_snakemake_version/workflow/lib/io_contracts.R
- biorempp_snakemake_version/workflow/lib/utils.R
-->

# Overview

This section documents the internal design of the active Snakemake workflow. It focuses on orchestration, contracts, and artifact boundaries rather than installation steps or command recipes.

## Architectural Spine

The BioRemPP implementation is built around one explicit DAG:

- `Snakefile` loads `config/config.yaml`
- `rule all` defines the release contract
- five `.smk` modules group the workflow into preflight, generation, analysis, validation, and reporting

The numbering used in `workflow/rules/` groups responsibilities, but it does not guarantee strict wall-clock order. Snakemake may schedule independent rules in parallel whenever their declared inputs are already satisfied.

## Workflow Layers

### Orchestration layer

The orchestration layer is declarative. `Snakefile` and the included rule modules define:

- which artifacts belong to a successful release
- which rule produces each artifact
- which dependencies must exist before a rule can run

This keeps the execution graph visible in the workflow definition itself instead of hiding it inside long scripts.

### Contract layer

The contract layer is split across two files with different responsibilities:

- `config/config.yaml`
  - runtime paths, release version, database output filenames, CSV formatting, KEGG base URL, analysis cutoffs, and validation thresholds
- `workflow/lib/io_contracts.R`
  - required curated input filenames, exported database column order, identifier patterns, and the KEGG endpoint contract used by the generation layer

One architectural detail matters here: KEGG endpoint ownership is split. The generation script reads endpoint definitions from `workflow/lib/io_contracts.R`, while the integrated validation rules read five link endpoints from `config/config.yaml`.

### Script layer

The transformation logic is decomposed into small entry-point scripts:

- `workflow/scripts/generation/`
  - curated input loading, KEGG acquisition, relationship assembly, classification, enrichment, and release export
- `workflow/scripts/analysis/`
  - descriptive summaries and merged analysis artifacts
- `workflow/scripts/validation/`
  - KEGG link caching and integrated validation reports
- `workflow/scripts/reporting/`
  - release-level summary generation

The rules orchestrate these scripts. The scripts do not orchestrate each other directly.

### Utility layer

`workflow/lib/utils.R` provides shared behavior for:

- CLI argument parsing
- JSON read/write helpers
- CSV read/write helpers
- NA normalization
- directory creation and logging

This keeps stage scripts narrow and reduces drift in common I/O behavior.

## Artifact Boundaries

The workflow uses four distinct artifact surfaces:

| Surface | Location | Role |
|---|---|---|
| Intermediate state | `work/` | serialized `.rds` bundles passed between generation stages |
| Public release outputs | `results/` | database exports, analysis artifacts, metadata reports, and workflow summary |
| Validation cache | `cache/kegg_link_cache/` | persisted KEGG link payloads reused by the integrated validation rules |
| Execution logs | `logs/` | per-rule command logs |

Only `results/` is the public release surface. The other directories exist for execution mechanics and auditability.

## Design Consequences

This architecture has three practical consequences:

- reproducibility comes from explicit file contracts rather than in-memory sequencing
- partial reruns are possible because expensive intermediate states are materialized in `work/`
- release review can rely on public metadata, validation outputs, and artifact hashes instead of the final database file alone

The remaining pages in this section unpack that architecture from three angles: stage order, rule-to-script mapping, and configuration plus I/O contracts.
