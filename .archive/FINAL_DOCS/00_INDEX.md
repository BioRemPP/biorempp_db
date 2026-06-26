# BioRemPP Documentation Planning Index

## Purpose

This directory consolidates the official documentation planning baseline for:

- the modular Snakemake pipeline in `biorempp_snakemake_version/`
- the standalone Great Expectations validator in `biorempp_validation/`
- the monolithic generator `generate_database.R`

The goal is to preserve architectural context before the actual MkDocs authoring work begins.

## Verified planning baseline

Verified on `2026-06-24` against the current repository state:

- root `mkdocs.yml` already contains a Material theme setup and `mike` versioning metadata, but its `nav` still exposes only `Home`
- `.archive/docs_deprecated/mkdocs.yml` contains the richest historical navigation model and is useful as an information architecture seed
- `.archive/gx_documentation/00_index.md` contains a GX-specific modular proposal and is useful as a section seed
- `biorempp_snakemake_version/Snakefile` currently includes five rule modules:
  - `00_preflight.smk`
  - `10_generation.smk`
  - `20_analysis.smk`
  - `30_validation.smk`
  - `90_reporting.smk`
- `biorempp_validation/config/validation.yaml` currently enables both:
  - `internal_consistency`
  - `regression_detection`
- `input_data/` currently exposes the curated input contract with these exact filenames:
  - `kegglistcompounds.xlsx`
  - `curated_regulated_compounds.xlsx`
  - `curated_programatic_missing_compounds.xlsx`
  - `curated_compound_classes.xlsx`
  - `kegglistko.txt`
  - `curated_enzyem_names_extracted.txt`

## Non-negotiable rule

Every future documentation excerpt must be compared against the real implementation segment before it is written or published.

Do not write from memory.
Do not write from archived docs alone.
Do not write from README files alone.
Do not silently normalize filenames, versions, outputs, or behavior descriptions.

This rule exists to avoid:

- overclaim: stating guarantees, behaviors, or outputs that are not implemented
- underclaim: omitting validation, provenance, or reproducibility behavior that is implemented

## Document set

- `01_DOCUMENTATION_CHARTER_AND_SCOPE.md`
  - documentation mission, scope, audience, and writing principles
- `02_VERIFIED_PROJECT_BASELINE.md`
  - repository baseline verified against code, config, inputs, and validation artifacts
- `03_MKDOCS_INFORMATION_ARCHITECTURE.md`
  - proposed site map and phased MkDocs navigation model
- `04_GLOBAL_CONTENT_MODEL.md`
  - reusable page structure, page metadata, and claim taxonomy
- `05_SOURCE_OF_TRUTH_AND_EVIDENCE_PROTOCOL.md`
  - required comparison protocol between prose and real pipeline behavior
- `06_PAGE_BLUEPRINTS_BY_SECTION.md`
  - page-by-page blueprints for the future docs tree
- `07_AUTHORING_WORKFLOW_QA_AND_GOVERNANCE.md`
  - drafting workflow, review checklist, and quality gates
- `08_MIGRATION_MAP_AND_IMPLEMENTATION_SEQUENCE.md`
  - source migration map, discrepancy handling, and phased implementation order

## How to use this folder

1. Start with `01`, `02`, and `05`.
2. Use `03` to define the future `mkdocs.yml` navigation.
3. Use `06` to author modular page drafts in priority order.
4. Apply the workflow and QA gates in `07`.
5. Use `08` whenever archived docs or README text is being migrated.

## Canonical writing stance

The future official documentation should be written in English as the canonical published language because the current MkDocs assets, validator docs, and historical public-facing material are already structured that way.

If a bilingual layer is later required, it should be added after the English canonical set is stable and verified.
