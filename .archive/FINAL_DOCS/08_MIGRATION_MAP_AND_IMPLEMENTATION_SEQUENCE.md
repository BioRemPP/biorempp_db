# Migration Map And Implementation Sequence

## Purpose

Map the currently available documentation-like sources into the future official docs set and define the safest implementation order.

## Source migration map

| Existing source | Best use | Risk | Migration rule |
|---|---|---|---|
| `mkdocs.yml` | reuse theme, plugin, and versioning setup | low | expand `nav`, do not replace blindly |
| `.archive/docs_deprecated/mkdocs.yml` | reuse as navigation scaffold | medium | re-check every page title and path before adoption |
| `README.md` | reuse for high-level repository orientation only | high | do not copy input filenames without code check |
| `biorempp_snakemake_version/README.md` | reuse for broad pipeline narrative and command hints | high | re-check rules, input names, and outputs |
| `biorempp_validation/README.md` | reuse for validator architecture and commands | medium | re-check against `validation.yaml` and source |
| `.archive/gx_documentation/` | reuse as GX section planning scaffold | medium | re-check against current validator code and config |
| `generate_database.R` comments | use as weak explanatory hints only | high | executable code outranks comments |

## Already verified discrepancies that must shape migration

### 1. Root site is configured but content nav is under-built

Implication:

- the task is mainly content architecture and content authoring
- not a full MkDocs technical bootstrap

### 2. README files still expose old curated input filenames

Implication:

- README text cannot be copied directly into official pages

### 3. The monolith and Snakemake pipeline do not share the same output framing

Implication:

- a dedicated monolith page is required
- docs must not present one unified output contract for both surfaces

### 4. Archived docs contain useful structure but uncertain truth

Implication:

- archive material is a scaffold, not a source of authority

## Recommended implementation sequence

### Phase 1 - foundation

1. Create the new docs tree and expand `mkdocs.yml` navigation.
2. Author:
   - `index.md`
   - `getting-started/overview.md`
   - `getting-started/requirements.md`
   - `getting-started/installation.md`
   - `getting-started/quick-start.md`

Reason:

- users need an accurate entry path before deeper pages exist

### Phase 2 - operator-critical content

Author:

- `user-guide/input-data.md`
- `user-guide/run-snakemake.md`
- `user-guide/run-monolith.md`
- `user-guide/understanding-output.md`

Reason:

- this locks the current execution and input contract into official docs

### Phase 3 - architecture and data contract

Author:

- all `pipeline-architecture/` P1 pages
- `database-reference/schema.md`
- `database-reference/curated-inputs.md`
- `database-reference/analysis-artifacts.md`

Reason:

- this is the core reviewer and maintainer reference layer

### Phase 4 - validation layers

Author:

- all `pipeline-validation/` pages
- all `validation-gx/` P1 pages

Reason:

- validation pages depend on stable understanding of outputs and architecture

### Phase 5 - secondary supporting pages

Author:

- remaining P2 pages in `database-reference/`
- `reference/`
- `about/`

Reason:

- these pages are valuable, but they are safest after core contracts are documented

## Non-copy rule for migration

No archived or README text should be pasted into the official docs without source re-check.

The correct migration flow is:

1. identify reusable structure
2. locate the real current source
3. write a fresh verified version

## Final implementation outcome

When this plan is followed, the future MkDocs site will have:

- a complete information architecture
- page-by-page source traceability
- explicit separation between pipeline, monolith, and GX surfaces
- protection against overclaim and underclaim
- a reliable foundation for versioned scientific release documentation
