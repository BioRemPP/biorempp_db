# Documentation Charter And Scope

## Mission

Produce an official documentation system for BioRemPP that is:

- technically accurate
- reproducible
- release-aware
- explicit about curated data contracts
- explicit about validation behavior
- usable by both operators and reviewers

## Primary documentation targets

- `biorempp_snakemake_version/`
  - the canonical modular pipeline implementation
- `biorempp_validation/`
  - the standalone validation layer for pipeline outputs
- `generate_database.R`
  - the monolithic generator kept in the repository as a separate execution surface

## Primary audiences

- researchers who need to understand the biological database generation process
- operators who need to execute the pipeline reproducibly
- reviewers who need to verify provenance, data contracts, and validation logic
- maintainers who need to update inputs, rules, outputs, or GX baselines without creating documentation drift

## Scope included

- execution prerequisites
- input data contract
- Snakemake pipeline architecture
- database outputs and analysis artifacts
- pipeline-integrated validation behavior
- Great Expectations validation behavior
- release and baseline management
- troubleshooting and maintenance guidance

## Scope excluded from first delivery

- speculative future features
- unimplemented FAIR claims
- performance claims not backed by current runs
- integration guides for systems that do not exist in the repository
- prose copied from historical docs without re-verification

## Core writing principles

### 1. Evidence before prose

Every claim must be grounded in code, config, tests, or generated artifacts that exist in the current repository state.

### 2. Distinguish execution surfaces

The documentation must not collapse these three surfaces into one:

- Snakemake pipeline
- GX validator
- monolithic `generate_database.R`

They share domain logic, but they do not share the same runtime contract, output locations, or version framing.

### 3. Use literal current contracts

When documenting filenames, paths, configuration keys, rule names, output names, or validation modes, use the exact current contract.

Examples that must remain literal until code changes:

- `curated_programatic_missing_compounds.xlsx`
- `curated_enzyem_names_extracted.txt`

The docs must not "correct" these names editorially while the code still depends on them.

### 4. Separate claim types

The docs must clearly distinguish:

- normative claims
  - what the code and config require
- descriptive claims
  - how the current implementation behaves
- observed claims
  - what a specific run produced on a specific date
- historical claims
  - what prior docs said, only if still verified

### 5. Version-aware writing

The root `mkdocs.yml` already signals versioned documentation intent through `mike`.
The docs should therefore be written so they can survive future release branches or versioned publications.

### 6. Explicit uncertainty handling

If a detail cannot be confirmed from the repository, the page must either:

- omit the claim
- label it as a pending verification item
- or trigger a code/documentation discrepancy review

## Official anti-drift policy

The documentation process must actively prevent:

- overclaim
  - example: saying the pipeline guarantees something that is only aspirational
- underclaim
  - example: omitting the existence of `30_validation.smk` or omitting GX regression detection
- stale naming
  - example: reintroducing old curated input filenames after the contract rename
- surface conflation
  - example: implying that the monolith writes into `biorempp_snakemake_version/results/`

## Expected publication shape

The official site should prioritize these top-level sections:

- Home
- Getting Started
- User Guide
- Pipeline Architecture
- Database Reference
- Pipeline Validation
- Data Validation (GX)
- Reference
- About

This matches what is expected from a reproducible scientific pipeline and biological database project without forcing unnecessary speculative sections.

## Success criteria

The documentation is successful when:

- a new operator can run the pipeline from the docs without guessing filenames or paths
- a reviewer can map every major claim to a real source file
- validation behavior is documented without ambiguity
- the difference between Snakemake outputs and monolith outputs is explicit
- future maintainers can update pages through a repeatable verification workflow
