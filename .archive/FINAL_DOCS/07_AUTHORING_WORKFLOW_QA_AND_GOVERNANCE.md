# Authoring Workflow, QA, And Governance

## Purpose

Define the repeatable workflow that future documentation work must follow so the published site remains compliant with the real pipeline and validator behavior.

## Standard authoring workflow

### Stage 1 - choose the page

- select the page from `06_PAGE_BLUEPRINTS_BY_SECTION.md`
- identify whether the page is P1 or P2

### Stage 2 - collect evidence

- open the Tier 1 sources for that page
- record them in the page metadata block
- record any observed artifact paths that will be cited

### Stage 3 - draft only verified prose

- write from code and config first
- use README or archived docs only as cross-check aids
- keep execution surfaces separate

### Stage 4 - run the section verification pass

For each major section ask:

- which file proves this statement
- does the current repository still expose this path, mode, or output
- am I mixing Snakemake behavior with monolith behavior
- am I mixing integrated validation with GX validation

### Stage 5 - resolve discrepancies

If there is disagreement between sources:

- stop the affected section
- identify the authoritative source
- either fix the code/docs mismatch or mark the section as pending verification

### Stage 6 - perform final page QA

- complete the anti-overclaim gate
- complete the anti-underclaim gate
- ensure filenames and paths remain literal
- ensure observed claims have artifact path and date

## Page acceptance checklist

The page is not ready unless all items below are true:

- page metadata block is present
- top-level audience and scope are explicit
- every major claim maps to at least one authoritative source
- exact filenames and config keys were preserved
- Snakemake, GX, and monolith surfaces are not conflated
- current renamed curated inputs are used everywhere
- validation behavior is not simplified beyond what the code implements
- outdated README or archive language was not copied without re-check

## Site-level QA checklist

Before the MkDocs content set is considered publishable:

- navigation matches the page tree
- no dead links remain
- section titles consistently distinguish pipeline vs GX
- version-sensitive pages declare their version scope
- pages that cite observed metrics declare date and artifact source

## Recommended validation commands during docs work

These commands are recommended quality checks for future authoring sessions:

```powershell
Get-ChildItem input_data | Select-Object Name
```

```powershell
rg -n "^rule " biorempp_snakemake_version\workflow\rules
```

```powershell
Get-Content -Raw biorempp_validation\config\validation.yaml
```

```powershell
Get-Content -Raw generate_database.R
```

If MkDocs build tooling is available in the authoring environment, also run:

```bash
mkdocs build
```

Only present `mkdocs build` as a required QA step if the project environment actually installs it.

## Change-trigger governance

Documentation must be reviewed whenever any of these areas changes:

| Change area | Pages that must be revisited |
|---|---|
| `input_data/` contract or loaders | Getting Started, User Guide input page, Database Reference curated inputs |
| `config/config.yaml` | Getting Started, User Guide run pages, Pipeline Architecture config page |
| `.smk` rules | Pipeline Architecture pages, Pipeline Validation pages, output-related user guide pages |
| `generate_database.R` | monolith user guide page, any comparison page |
| `validation.yaml` or GX source | all `validation-gx/` pages |
| result artifact names | User Guide outputs page, Database Reference, Validation pages |

## Governance stance

The documentation must evolve together with code contracts.
It must not be treated as a separate narrative layer that can drift for months.

When a change modifies:

- filenames
- output contracts
- validation behavior
- release naming
- execution commands

the matching docs pages should be updated in the same change window whenever possible.
