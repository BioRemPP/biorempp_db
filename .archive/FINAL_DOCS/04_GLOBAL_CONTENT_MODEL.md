# Global Content Model

## Purpose

Define the common structure every official documentation page should follow so the full site remains technically consistent and easy to review.

## Required page metadata block

Every page draft should start with a compact metadata block like this:

```md
Page status: draft | verified | reviewed
Audience: operators | researchers | maintainers | reviewers
Applies to: Snakemake | GX | monolith | mixed
Version scope: v1.1.0 | current main | specify explicitly
Last verified on: YYYY-MM-DD
Primary sources:
- path/to/source_1
- path/to/source_2
Observed artifacts:
- optional artifact path
Known gaps:
- optional unresolved point
```

This block is not decorative.
It is the minimum traceability layer for preventing silent drift.

## Recommended page anatomy

Every page should use this order unless there is a strong reason not to:

1. Summary
2. Why this matters
3. Contract or behavior details
4. Inputs, outputs, or commands
5. Failure modes or limitations
6. Related pages

## Claim taxonomy

### Contract claim

What the code or config explicitly requires.

Examples:

- required input filenames
- output filenames
- validation mode keys
- expected schema columns

Evidence requirement:

- direct code or config source

### Behavior claim

What the implementation currently does.

Examples:

- rule execution stages
- where validation reads results from
- where the monolith writes outputs

Evidence requirement:

- executable rule or script source

### Observed claim

What a specific run produced.

Examples:

- current validation pass status
- current row counts
- current baseline identifier

Evidence requirement:

- generated artifact
- verification date

### Historical claim

What an archived source previously said.

Allowed use:

- only as context
- only after current re-check

Historical claims are never sufficient evidence by themselves.

## Required page fields by page type

### Landing page

Must include:

- project purpose
- execution surfaces
- where to start
- release scope

### How-to page

Must include:

- exact command path
- required inputs or prerequisites
- expected outputs
- common failure modes

### Reference page

Must include:

- exact names
- exact paths or keys
- authoritative source files
- limitations if the contract is partial

### Explanation page

Must include:

- conceptual model
- system boundaries
- direct pointers to code that implements the explanation

## Mandatory language rules

- use exact filenames and exact configuration keys
- avoid vague verbs like "handles", "supports", or "ensures" unless the behavior is directly verifiable
- when citing counts or run outcomes, attach a date and artifact path
- explicitly distinguish "pipeline", "validator", and "monolith"

## Anti-overclaim and anti-underclaim examples

### Overclaim examples to avoid

- "The database is FAIR-compliant"
  - unless FAIR compliance is formally implemented and evidenced
- "The pipeline exports version 1.1.0 from all execution modes"
  - false for the monolith as currently written
- "Input filenames were normalized"
  - false unless code contract changed

### Underclaim examples to avoid

- omitting `30_validation.smk`
- omitting the GX `regression_detection` mode
- omitting that curated input names were already refactored in the active contract

## Page-level evidence table

Every page should keep a compact evidence table during drafting:

| Claim area | Claim type | Primary source | Artifact check | Verified |
|---|---|---|---|---|
| Example: input filenames | Contract | `workflow/lib/io_contracts.R` | `input_data/` listing | Yes |

This table can remain in authoring drafts and be removed or condensed before publication if needed.
