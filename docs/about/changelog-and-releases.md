<!--
Page status: verified
Audience: maintainers, reviewers, release managers
Applies to: Snakemake, GX, and documentation
Version scope: repository contract v1.1.0
Last verified on: 2026-06-24
Primary sources:
- biorempp_snakemake_version/config/config.yaml
- biorempp_snakemake_version/Snakefile
- biorempp_validation/config/validation.yaml
- biorempp_validation/pyproject.toml
- mkdocs.yml
- .readthedocs.yaml
- scripts/build-docs.sh
- git tag
- git log --oneline -n 20
Known gaps:
- `git tag` returned no tags on 2026-06-24
- `scripts/build-docs.sh` still prints `Version 1.0.0` in its banner while active pipeline and validator contracts are `1.1.0`
- `mkdocs.yml` advertises `extra.version.provider: mike`, but no checked-in publication workflow documents how versioned docs releases are published
-->

# Changelog And Releases

BioRemPP exposes several concrete version markers, but it does not currently centralize release history in one authoritative changelog file. This page explains how release state can be verified from the repository as it exists today.

## Where Version Information Lives

| Surface | File or path | Current verified marker |
|---|---|---|
| Snakemake release contract | `biorempp_snakemake_version/config/config.yaml` | `version: "1.1.0"` |
| Public database filenames | `biorempp_snakemake_version/config/config.yaml` | `biorempp_database_v1.1.0.csv` and `biorempp_database_v1.1.0.xlsx` |
| GX runtime configuration | `biorempp_validation/config/validation.yaml` | `version: "1.1.0"` |
| GX package metadata | `biorempp_validation/pyproject.toml` | `version = "1.1.0"` |
| Regression baseline naming | `biorempp_validation/baselines/` | `release_v1_1_0_kegg_118_0plus` |
| Documentation site default version | `mkdocs.yml` | `extra.version.default: 1.1.0` |

These markers are aligned around `1.1.0`, but they are distributed across different subsystems.

## What Counts As A Release Surface

In the current repository, a release is represented by more than the database file alone. The effective release surface includes:

- versioned database outputs in `results/database/`
- analysis JSON artifacts in `results/analysis/`
- KEGG release metadata in `results/metadata/kegg_release.json`
- pipeline-integrated validation reports in `results/metadata/`
- the workflow summary in `results/reports/workflow_summary.json`
- GX configuration, suites, and baseline assumptions that validate those outputs
- official documentation when public contracts or behavior change

## How Change History Is Currently Tracked

The checked-in evidence for change history is currently:

- recent git commit history
- version values in config and package files
- baseline directory names
- generated output filenames

Recent commit subjects use a modular conventional-commit style, including `fix`, `refactor`, `test`, `docs`, and `chore` scopes. That gives maintainers a useful review trail, but it is not the same thing as a dedicated published changelog.

As of 2026-06-24, `git tag` returned no tags. This means the repository does not currently expose tag-based release markers in git itself.

## Practical Release Review

When reviewing a release-shaped change, compare at minimum:

1. `biorempp_snakemake_version/config/config.yaml`
2. `biorempp_validation/config/validation.yaml`
3. `biorempp_validation/pyproject.toml`
4. affected output filenames, schema, or validation assets
5. the relevant official documentation pages

If regression behavior is expected to change, also review the baseline snapshot and any threshold changes together rather than in isolation.

## Current Release Governance Gaps

Three concrete gaps are visible in the checked-in repository:

- no root `CHANGELOG.md` is present
- no git tags are present for the current release line
- documentation versioning hints exist in `mkdocs.yml`, but no checked-in process describes how versioned docs are published

There is also one small version-marker mismatch outside the core pipeline contract: `scripts/build-docs.sh` still prints `Version 1.0.0` in its banner even though the active Snakemake, GX, and docs version markers are `1.1.0`.

## Related Pages

- [Project Scope](project-scope.md)
- [Contributing](contributing.md)
- [Configuration And IO Contracts](../pipeline-architecture/configuration-and-io.md)
