# Documentation Workflow

## Purpose

This file defines a short reusable workflow for writing each official documentation chunk from the planning package in `.archive/FINAL_DOCS/`.

It should be used as an authoring prompt pattern, not as a source of truth by itself.

## How to use the context package

For each documentation request, use these files in this order:

1. `00_INDEX.md`
   - understand the planning package and current scope
2. `02_VERIFIED_PROJECT_BASELINE.md`
   - recover the verified project facts already established
3. `03_MKDOCS_INFORMATION_ARCHITECTURE.md`
   - identify the page set implied by the requested `nav` slice
4. `04_GLOBAL_CONTENT_MODEL.md`
   - apply the required page anatomy and claim taxonomy
5. `05_SOURCE_OF_TRUTH_AND_EVIDENCE_PROTOCOL.md`
   - compare every draft section against the real pipeline or validator implementation
6. `06_PAGE_BLUEPRINTS_BY_SECTION.md`
   - recover page-specific goals, required checks, and priority
7. `07_AUTHORING_WORKFLOW_QA_AND_GOVERNANCE.md`
   - run the page acceptance checklist
8. `08_MIGRATION_MAP_AND_IMPLEMENTATION_SEQUENCE.md`
   - use only when migrating material from README or archived docs

## Reusable workflow prompt

Use the template below whenever requesting the writing of a documentation chunk.

```md
Write the official documentation for the following MkDocs nav chunk:

[PASTE NAV SLICE HERE]

Before writing:
- read `.archive/FINAL_DOCS/00_INDEX.md`
- read `.archive/FINAL_DOCS/02_VERIFIED_PROJECT_BASELINE.md`
- read `.archive/FINAL_DOCS/03_MKDOCS_INFORMATION_ARCHITECTURE.md`
- read `.archive/FINAL_DOCS/04_GLOBAL_CONTENT_MODEL.md`
- read `.archive/FINAL_DOCS/05_SOURCE_OF_TRUTH_AND_EVIDENCE_PROTOCOL.md`
- read `.archive/FINAL_DOCS/06_PAGE_BLUEPRINTS_BY_SECTION.md`
- read `.archive/FINAL_DOCS/07_AUTHORING_WORKFLOW_QA_AND_GOVERNANCE.md`
- read `.archive/FINAL_DOCS/08_MIGRATION_MAP_AND_IMPLEMENTATION_SEQUENCE.md` only if historical docs or README text will be reused

Execution requirements:
- identify every page implied by this nav chunk
- for each page, recover the relevant real source files from the repository
- compare every paragraph with the real implementation before writing
- do not rely on README text or archived docs without re-checking against code and config
- avoid overclaim and underclaim
- keep exact filenames, rule names, config keys, output names, and validation modes
- explicitly distinguish Snakemake pipeline, GX validator, and monolithic `generate_database.R` whenever relevant

Expected output:
- produce the markdown files for all pages in this nav chunk
- include a compact metadata block in each page
- list the primary sources used for each page
- flag any unresolved discrepancy instead of guessing
```

## Example for the first nav chunk

Input chunk:

```yaml
nav:
  - Home: index.md
  - Getting Started:
      - Overview: getting-started/overview.md
      - Requirements: getting-started/requirements.md
      - Installation: getting-started/installation.md
      - Quick Start: getting-started/quick-start.md
  - User Guide:
```

Suggested request:

```md
Write the official documentation for this first MkDocs chunk:

- `Home: index.md`
- `Getting Started`
  - `getting-started/overview.md`
  - `getting-started/requirements.md`
  - `getting-started/installation.md`
  - `getting-started/quick-start.md`
- `User Guide` section scaffold only if no child pages are defined yet

Use `.archive/FINAL_DOCS/00_INDEX.md` through `.archive/FINAL_DOCS/08_MIGRATION_MAP_AND_IMPLEMENTATION_SEQUENCE.md` as planning context.

Before writing, recover and verify the real sources at minimum from:
- root `mkdocs.yml`
- `biorempp_snakemake_version/Snakefile`
- `biorempp_snakemake_version/config/config.yaml`
- `biorempp_snakemake_version/env/`
- `biorempp_snakemake_version/scripts/`
- `biorempp_validation/config/validation.yaml`
- `generate_database.R`
- `input_data/`

Requirements:
- write `index.md`
- write all `getting-started/*.md` pages
- for each page include a metadata block with scope, version, verification date, and primary sources
- do not invent commands, prerequisites, paths, or outputs
- if `User Guide` child pages are not yet defined in the nav slice, do not fabricate them; only note what the next authoring chunk should cover
- compare every final paragraph against the real implementation before saving
```

## Acceptance rule

If the writer cannot point from each page section to a real repository source, the section is not ready to publish.
