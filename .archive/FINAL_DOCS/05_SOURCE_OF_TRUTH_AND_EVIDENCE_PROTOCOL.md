# Source Of Truth And Evidence Protocol

## Non-negotiable authoring rule

For every document excerpt that will be written, the author must compare the draft against the real implementation segment that describes or produces that behavior.

Do not publish text that has not been compared against source.

This applies to:

- one-line statements
- command examples
- file lists
- output descriptions
- validation explanations
- architecture diagrams
- release notes

## Source precedence

Use sources in this order:

### Tier 1 - authoritative

- `biorempp_snakemake_version/Snakefile`
- `biorempp_snakemake_version/config/config.yaml`
- `biorempp_snakemake_version/workflow/rules/*.smk`
- `biorempp_snakemake_version/workflow/lib/io_contracts.R`
- `biorempp_snakemake_version/workflow/scripts/**/*`
- `biorempp_validation/config/validation.yaml`
- `biorempp_validation/src/**/*`
- `generate_database.R`
- actual files in `input_data/`
- actual files in `biorempp_snakemake_version/results/`
- actual files in `biorempp_validation/results/`

### Tier 2 - strong supporting evidence

- `biorempp_validation/tests/**/*`
- pinned requirements and environment files
- helper scripts under `scripts/` and `env/`

### Tier 3 - secondary context only

- `README.md`
- `biorempp_snakemake_version/README.md`
- `biorempp_validation/README.md`
- `.archive/docs_deprecated/**/*`
- `.archive/gx_documentation/**/*`
- comments and headers inside source files

If Tier 1 and Tier 3 disagree, Tier 1 wins.

## Mandatory comparison targets by topic

| Topic being written | Minimum comparison set |
|---|---|
| Input filenames and paths | `input_data/`, `workflow/lib/io_contracts.R`, `workflow/scripts/generation/00_check_inputs.R`, `workflow/scripts/generation/01_load_local_data.R`, `generate_database.R` |
| Pipeline DAG and rule stages | `Snakefile`, `workflow/rules/*.smk` |
| Script responsibilities | corresponding file in `workflow/scripts/` or `biorempp_validation/src/` |
| Database schema and controlled vocabularies | `workflow/lib/io_contracts.R`, `biorempp_validation/config/validation.yaml`, actual CSV header when needed |
| Runtime commands | `env/docker-compose.yml`, helper scripts, and if necessary the relevant README after code check |
| Pipeline-integrated validation | `workflow/rules/30_validation.smk`, corresponding validation scripts, generated metadata reports |
| GX validation behavior | `biorempp_validation/config/validation.yaml`, `biorempp_validation/src/**/*`, `biorempp_validation/docs/validation_modes.md` |
| Monolith behavior | `generate_database.R` executable code, not just its comments |
| Current run outcomes | generated artifacts plus explicit verification date |

## Paragraph drafting workflow

### Step 1 - classify the paragraph

Mark the paragraph as one of:

- contract
- behavior
- observed
- historical context

### Step 2 - open the primary source

Before drafting, inspect the real file that implements or defines the claim.

### Step 3 - compare prose to source

Check:

- names
- paths
- versions
- rule order
- output locations
- current validation modes
- command syntax

### Step 4 - write only what is supported

If the source does not support the claim, do not write the claim.

### Step 5 - record evidence

Attach the source path to the page metadata block or page evidence table.

### Step 6 - run the anti-claim review

Ask two questions:

- am I saying more than the code proves
- am I saying less than the code clearly implements

## Special handling for observed values

Observed values are volatile because the pipeline consumes KEGG data and produces generated artifacts.

Therefore:

- cite the artifact path
- cite the verification date
- do not present observed values as timeless truths
- if the observed value is release-specific, say so explicitly

## Discrepancy handling

If two sources disagree:

1. identify the authoritative source tier
2. verify whether the disagreement is:
   - stale documentation
   - stale comments
   - outdated artifact
   - real code inconsistency
3. do not publish ambiguous prose
4. either:
   - fix the underlying inconsistency first
   - or mark the section as pending verification

## Known repository-specific discrepancy patterns

Already observed in the current repository:

- README files still carry old curated input filenames
- root `mkdocs.yml` is configured but under-populated
- `generate_database.R` comments are not fully aligned with current executable file paths
- archived docs preserve useful structure but not guaranteed current truth

These are not reasons to stop authoring.
They are reasons to follow this protocol strictly.

## Mandatory anti-overclaim and anti-underclaim gate

Before any page section is accepted, explicitly confirm:

- no outdated filenames were reintroduced
- no implementation surface was conflated with another
- no output location was guessed
- no validation mode was omitted
- no release or result claim lacks date and artifact context

## Recommended author evidence template

```md
Evidence notes
- Claim: current curated input contract
  - Source: biorempp_snakemake_version/workflow/lib/io_contracts.R
  - Cross-check: input_data/ directory listing
  - Status: verified
- Claim: GX modes
  - Source: biorempp_validation/config/validation.yaml
  - Cross-check: biorempp_validation/docs/validation_modes.md
  - Status: verified
```
