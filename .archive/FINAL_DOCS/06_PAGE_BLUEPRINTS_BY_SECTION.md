# Page Blueprints By Section

## Purpose

Define the page-level content plan for the future MkDocs site, including what each page must cover and what it must be checked against before writing.

## Home

### `index.md`

Purpose:

- explain the project at a high level
- distinguish Snakemake, GX, and monolith surfaces
- point users to the correct starting section

Must be verified against:

- `biorempp_snakemake_version/Snakefile`
- `biorempp_validation/config/validation.yaml`
- `generate_database.R`
- root `mkdocs.yml`

Must not claim:

- detailed metrics unless tied to artifacts and date
- unified runtime behavior across all execution surfaces

Priority: P1

## Getting Started

### `getting-started/overview.md`

Purpose:

- define repository layout and explain where users should begin

Must be verified against:

- top-level directory tree
- `mkdocs.yml`
- `biorempp_snakemake_version/`
- `biorempp_validation/`

Priority: P1

### `getting-started/requirements.md`

Purpose:

- document runtime prerequisites

Must be verified against:

- `biorempp_snakemake_version/env/`
- `biorempp_validation/env/`
- requirements and package manifests

Priority: P1

### `getting-started/installation.md`

Purpose:

- explain environment setup and containerized execution entry points

Must be verified against:

- `biorempp_snakemake_version/env/docker-compose.yml`
- helper scripts in `biorempp_snakemake_version/scripts/`
- validator README only after command cross-check

Priority: P1

### `getting-started/quick-start.md`

Purpose:

- provide the shortest correct path to a first successful run

Must be verified against:

- Snakemake runtime command path
- GX runtime command path
- current input contract

Must not claim:

- local non-container execution parity unless verified

Priority: P1

## User Guide

### `user-guide/input-data.md`

Purpose:

- document exact required input files, expected locations, and their role in the pipeline

Must be verified against:

- `input_data/`
- `workflow/lib/io_contracts.R`
- `workflow/scripts/generation/00_check_inputs.R`
- `workflow/scripts/generation/01_load_local_data.R`
- `generate_database.R`

Must not claim:

- corrected filenames that do not exist in code

Priority: P1

### `user-guide/run-snakemake.md`

Purpose:

- explain how to run the modular pipeline

Must be verified against:

- `biorempp_snakemake_version/Snakefile`
- `biorempp_snakemake_version/config/config.yaml`
- helper scripts
- container entry points

Priority: P1

### `user-guide/run-monolith.md`

Purpose:

- explain how to run `generate_database.R` and how it differs from Snakemake

Must be verified against:

- `generate_database.R`

Must explicitly mention:

- reads from root `input_data/`
- writes to `output_data/`
- current output naming is `v1.0.0`

Priority: P1

### `user-guide/understanding-output.md`

Purpose:

- explain output families and where to find them

Must be verified against:

- `Snakefile`
- `biorempp_validation/config/validation.yaml`
- actual `biorempp_snakemake_version/results/` tree
- actual `biorempp_validation/results/` tree

Priority: P1

### `user-guide/troubleshooting.md`

Purpose:

- document common operator failures and where they surface

Must be verified against:

- preflight behavior
- validation behavior
- run commands and logs layout

Priority: P2

## Pipeline Architecture

### `pipeline-architecture/overview.md`

Purpose:

- explain the pipeline layers end to end

Must be verified against:

- `Snakefile`
- all `.smk` rule files

Priority: P1

### `pipeline-architecture/execution-stages.md`

Purpose:

- document the stage ordering from preflight through reporting

Must be verified against:

- actual rule names in `.smk` files

Must not rely on:

- historical DAG names from README without re-check

Priority: P1

### `pipeline-architecture/rules-and-scripts.md`

Purpose:

- map rules to scripts and outputs

Must be verified against:

- `workflow/rules/*.smk`
- `workflow/scripts/**/*`

Priority: P1

### `pipeline-architecture/configuration-and-io.md`

Purpose:

- explain config keys, input directory, results directory, and output contracts

Must be verified against:

- `biorempp_snakemake_version/config/config.yaml`
- `workflow/lib/io_contracts.R`

Priority: P1

## Database Reference

### `database-reference/schema.md`

Purpose:

- document database columns and schema semantics

Must be verified against:

- `workflow/lib/io_contracts.R`
- `biorempp_validation/config/validation.yaml`
- actual CSV header when needed

Priority: P1

### `database-reference/curated-inputs.md`

Purpose:

- explain what each curated input contributes to the assembled database

Must be verified against:

- `workflow/scripts/generation/01_load_local_data.R`
- `generate_database.R`

Must not claim:

- biological semantics not visible in code or stable curated metadata

Priority: P1

### `database-reference/analysis-artifacts.md`

Purpose:

- document the analysis JSON outputs and their role

Must be verified against:

- `Snakefile`
- `workflow/rules/20_analysis.smk`
- actual `results/analysis/` files

Priority: P1

### `database-reference/provenance-and-release.md`

Purpose:

- explain release-linked outputs, KEGG provenance artifacts, and validation baseline relationships

Must be verified against:

- `results/metadata/kegg_release.json`
- `results/reports/workflow_summary.json`
- `biorempp_validation/config/validation.yaml`
- baseline directory naming

Priority: P2

## Pipeline Validation

### `pipeline-validation/overview.md`

Purpose:

- explain validation that occurs inside the Snakemake pipeline itself

Must be verified against:

- `workflow/rules/30_validation.smk`

Priority: P1

### `pipeline-validation/kegg-link-cache.md`

Purpose:

- explain the KEGG cache generated for validation checks

Must be verified against:

- `workflow/rules/30_validation.smk`
- validation cache scripts

Priority: P2

### `pipeline-validation/keys-consistency.md`

Purpose:

- explain `keys_consistency_report.json`

Must be verified against:

- `workflow/rules/30_validation.smk`
- `workflow/scripts/validation/01_validate_keys_consistency_api.py`
- generated report schema if available

Priority: P1

### `pipeline-validation/links-groundtruth-policy.md`

Purpose:

- explain `links_groundtruth_policy_report.json`

Must be verified against:

- `workflow/rules/30_validation.smk`
- `workflow/scripts/validation/02_validate_links_groundtruth_policy_api.py`
- generated report schema if available

Priority: P1

## Data Validation (GX)

### `validation-gx/architecture.md`

Purpose:

- explain the validator structure and runtime model

Must be verified against:

- `biorempp_validation/README.md`
- `biorempp_validation/src/**/*`

Priority: P1

### `validation-gx/expectation-suites.md`

Purpose:

- document the suite families and what they validate

Must be verified against:

- `biorempp_validation/great_expectations/expectations/`
- source files that load and run suites

Priority: P1

### `validation-gx/validation-modes.md`

Purpose:

- document `internal_consistency` and `regression_detection`

Must be verified against:

- `biorempp_validation/config/validation.yaml`
- `biorempp_validation/docs/validation_modes.md`
- validator source files

Priority: P1

### `validation-gx/configuration.md`

Purpose:

- explain `validation.yaml`

Must be verified against:

- `biorempp_validation/config/validation.yaml`

Priority: P1

### `validation-gx/baseline-management.md`

Purpose:

- explain how the regression baseline is maintained

Must be verified against:

- `biorempp_validation/config/validation.yaml`
- validator README
- actual baseline directory layout

Priority: P1

### `validation-gx/testing.md`

Purpose:

- explain how validator tests are executed and updated

Must be verified against:

- `biorempp_validation/tests/`
- current test command

Priority: P1

## Reference

### `reference/data-sources.md`

Purpose:

- document external and curated data sources actually used by the code

Must be verified against:

- input contract
- KEGG config and fetch scripts
- curated input loaders

Priority: P2

### `reference/glossary.md`

Purpose:

- define recurring project terms and acronyms

Must be verified against:

- real repository vocabulary
- schema and validation contracts

Priority: P2

## About

### `about/project-scope.md`

Purpose:

- document project boundaries, supported surfaces, and non-goals

Must be verified against:

- repository structure
- this planning baseline

Priority: P2

### `about/contributing.md`

Purpose:

- explain how documentation and validation-related changes should be reviewed

Must be verified against:

- current repo workflows and contribution conventions

Priority: P2

### `about/changelog-and-releases.md`

Purpose:

- explain how release-linked documentation should be versioned and updated

Must be verified against:

- output versioning in config
- current `mkdocs.yml` versioning hints
- repository release practice if documented

Priority: P2
