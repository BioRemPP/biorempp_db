<!--
Page status: verified
Audience: maintainers, reviewers, contributors
Applies to: Snakemake, GX, and documentation
Version scope: repository contract v1.1.0
Last verified on: 2026-06-24
Primary sources:
- repository root directory listing
- .github/workflows/docs-ci.yml
- .readthedocs.yaml
- scripts/build-docs.sh
- biorempp_snakemake_version/env/docker-compose.yml
- biorempp_snakemake_version/workflow/lib/io_contracts.R
- biorempp_snakemake_version/config/config.yaml
- biorempp_validation/config/validation.yaml
- biorempp_validation/pyproject.toml
- biorempp_validation/tests directory listing
- git log --oneline -n 20
Known gaps:
- no root CONTRIBUTING.md is present in the repository
- docs CI builds the site, but the checked-in workflow does not currently use `mkdocs build --strict`
-->

# Contributing

This page documents the contribution workflow that can be verified from the current repository. It is intentionally contract-focused because the repository does not currently ship a root `CONTRIBUTING.md`.

## Contribution Surfaces

| If your change touches | You should review at minimum |
|---|---|
| curated input filenames or loader assumptions | `workflow/lib/io_contracts.R`, `workflow/scripts/generation/00_check_inputs.R`, `workflow/scripts/generation/01_load_local_data.R`, affected user-guide and reference pages |
| database schema or output names | `workflow/lib/io_contracts.R`, generation export scripts, analysis consumers, `biorempp_validation/config/validation.yaml`, GX suites, baseline assumptions, documentation |
| KEGG acquisition or normalization | generation fetch scripts, integrated validation scripts, metadata outputs, and any affected glossary or architecture pages |
| GX behavior or thresholds | `biorempp_validation/config/validation.yaml`, `src/`, expectation suites, checkpoints, tests, and validation documentation |
| official documentation | `docs/`, `mkdocs.yml`, `.github/workflows/docs-ci.yml`, and `scripts/build-docs.sh` when build behavior changes |

## Minimum Review Discipline

For this repository, a contribution is not complete when it changes code alone. Public contracts are spread across workflow rules, R helpers, GX configuration, and documentation.

Use this review pattern:

1. identify the contract surface that changed
2. update every downstream occurrence of that contract
3. rerun the closest executable validation available
4. update the official docs if public behavior or terminology changed

That is especially important for filename renames, schema changes, controlled vocabularies, and release-baseline updates.

## Verified Local Checks

The repository currently exposes these concrete verification paths:

### Documentation

- GitHub Actions runs `.github/workflows/docs-ci.yml` on documentation-related changes.
- That workflow installs dependencies through `scripts/build-docs.sh install` and builds through `scripts/build-docs.sh build`.
- For local authoring, maintainers should also run `mkdocs build --strict` before merging official documentation changes.

### Snakemake execution

The checked-in Docker Compose service for the pipeline is `snakemake` in `biorempp_snakemake_version/env/docker-compose.yml`.

Typical contribution checks are:

- DAG or command review through a dry run
- full pipeline execution when generation, analysis, validation, or reporting logic changed

### GX validation

The checked-in Docker Compose service for the validator is `validation` in the same Compose file.

The repository currently contains these GX tests:

- `test_dual_mode_validation.py`
- `test_happy_path.py`
- `test_kegg_metadata.py`
- `test_missing_files.py`
- `test_schema_break.py`
- `test_warning_only_drift.py`

When GX logic, thresholds, or upstream output contracts change, the validator run and its test suite should be reviewed together.

## Commit Style Observed In The Repository

Recent history uses conventional-commit style subjects such as:

- `fix(...)`
- `refactor(...)`
- `test(...)`
- `docs(...)`
- `chore(...)`

This style is visible in recent `git log` output, but no repository-local enforcement rule is visible in the checked-in files. Keep scopes specific and align each commit with one contract change whenever possible.

## Change Types That Need Extra Care

Some changes require broader review than they first appear to:

- input filename changes propagate into preflight, loaders, docs, and often validation assumptions
- exported schema changes propagate into analysis, metadata interpretation, GX configuration, suites, tests, and baselines
- vocabulary changes for `referenceAG` or `compoundclass` propagate into GX warning expectations
- release-number changes propagate into output filenames, validator paths, package metadata, baseline naming, and documentation

## Current Governance Gaps

The repository has working review surfaces, but a few process gaps are visible today:

- there is no root `CONTRIBUTING.md`
- docs CI builds the site but does not currently enforce strict MkDocs mode
- `.readthedocs.yaml` sets `fail_on_warning: false`, so Read the Docs configuration is less strict than the recommended local authoring check

Treat this page as the verified contribution guide until a repository-level policy file supersedes it.

## Related Pages

- [Project Scope](project-scope.md)
- [Changelog And Releases](changelog-and-releases.md)
- [Testing](../validation-gx/testing.md)
