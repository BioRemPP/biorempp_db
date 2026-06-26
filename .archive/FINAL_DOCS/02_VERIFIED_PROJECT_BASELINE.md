# Verified Project Baseline

## Purpose

This file captures the repository baseline that has already been verified and should anchor the first documentation pass.

## Repository components

| Path | Verified role | Documentation implication |
|---|---|---|
| `mkdocs.yml` | Active site configuration with theme, plugins, and versioning metadata | expand `nav`, do not rebuild site structure from scratch |
| `biorempp_snakemake_version/` | Active modular generation and analysis pipeline | primary source for execution, DAG, inputs, outputs, and integrated validation |
| `biorempp_validation/` | Active standalone Great Expectations validator | primary source for data contract, regression, and consistency validation docs |
| `generate_database.R` | Standalone monolithic generator | document separately from Snakemake runtime behavior |
| `input_data/` | Current canonical curated input root | document exact filenames and path expectations |
| `.archive/docs_deprecated/` | Historical docs source tree | useful for navigation seeding, not authoritative by itself |
| `.archive/gx_documentation/` | Historical GX modular planning notes | useful for GX section seeding, not authoritative by itself |

## Current MkDocs state

Verified in root `mkdocs.yml`:

- Material theme is already configured
- search and minify plugins are already configured
- `mike` versioning metadata is already configured
- navigation currently contains only:
  - `Home: index.md`

Documentation implication:

- the site configuration is not empty
- the main missing layer is content tree plus expanded `nav`

## Snakemake baseline

Verified in `biorempp_snakemake_version/Snakefile`:

- config source:
  - `config/config.yaml`
- included rule modules:
  - `workflow/rules/00_preflight.smk`
  - `workflow/rules/10_generation.smk`
  - `workflow/rules/20_analysis.smk`
  - `workflow/rules/30_validation.smk`
  - `workflow/rules/90_reporting.smk`

Verified rule names:

- preflight
  - `preflight_check_inputs`
- generation
  - `fetch_kegg_info`
  - `load_local_data`
  - `fetch_kegg_data`
  - `merge_relationships`
  - `add_classifications`
  - `enrich_gene_info`
  - `extract_enzymes_export`
- analysis
  - `basic_statistics`
  - `compound_statistics`
  - `ko_statistics`
  - `enzyme_statistics`
  - `gene_statistics`
  - `crosstab_statistics`
  - `database_metadata`
  - `executive_summary`
  - `complete_analysis`
- validation
  - `fetch_kegg_link_cache`
  - `validate_keys_consistency`
  - `validate_links_groundtruth_policy`
- reporting
  - `build_run_report`

Verified config points in `biorempp_snakemake_version/config/config.yaml`:

- `paths.input_dir: "../input_data"`
- `paths.results_dir: "results"`
- `paths.work_dir: "work"`
- `paths.logs_dir: "logs"`
- output database names:
  - `biorempp_database_v1.1.0.csv`
  - `biorempp_database_v1.1.0.xlsx`

## Curated input contract

Verified in:

- `input_data/`
- `biorempp_snakemake_version/workflow/lib/io_contracts.R`
- `biorempp_snakemake_version/workflow/scripts/generation/01_load_local_data.R`

Current required input filenames:

- `kegglistcompounds.xlsx`
- `curated_regulated_compounds.xlsx`
- `curated_programatic_missing_compounds.xlsx`
- `curated_compound_classes.xlsx`
- `kegglistko.txt`
- `curated_enzyem_names_extracted.txt`

Documentation implication:

- these names are current contract
- old names in README files must not be reused in new docs

## Snakemake output families

Verified in `Snakefile` and `biorempp_validation/config/validation.yaml`:

- database outputs
  - `results/database/biorempp_database_v1.1.0.csv`
  - `results/database/biorempp_database_v1.1.0.xlsx`
- analysis outputs
  - `results/analysis/database_metadata.json`
  - `results/analysis/basic_statistics.json`
  - `results/analysis/compound_statistics.json`
  - `results/analysis/ko_statistics.json`
  - `results/analysis/enzyme_statistics.json`
  - `results/analysis/gene_statistics.json`
  - `results/analysis/crosstab_statistics.json`
  - `results/analysis/executive_summary.json`
  - `results/analysis/complete_analysis.json`
- metadata outputs
  - `results/metadata/kegg_release.json`
  - `results/metadata/keys_consistency_report.json`
  - `results/metadata/links_groundtruth_policy_report.json`
- reporting output
  - `results/reports/workflow_summary.json`

## GX validation baseline

Verified in `biorempp_validation/config/validation.yaml` and `biorempp_validation/README.md`:

- validator input root:
  - `../biorempp_snakemake_version/results`
- regression baseline root:
  - `baselines/release_v1_1_0_kegg_118_0plus`
- blocking policy:
  - `fail_on_critical: true`
  - `fail_on_warning: true`
- active modes:
  - `internal_consistency: true`
  - `regression_detection: true`

Verified current validation artifact on `2026-06-24` in `biorempp_validation/results/validation_summary.json`:

- `critical_checkpoint_success: true`
- `warning_checkpoint_success: true`
- `critical_failed_expectations: 0`
- `warning_failed_expectations: 0`

Documentation implication:

- if official docs mention current validation status, they must cite the artifact path and the verification date

## Monolithic generator baseline

Verified in `generate_database.R`:

- reads inputs from root `input_data/`
- currently loads:
  - `kegglistcompounds.xlsx`
  - `curated_regulated_compounds.xlsx`
  - `curated_programatic_missing_compounds.xlsx`
  - `curated_compound_classes.xlsx`
  - `kegglistko.txt`
  - `curated_enzyem_names_extracted.txt`
- currently writes:
  - `output_data/biorempp_database_v1.0.0.csv`
  - `output_data/biorempp_database_v1.0.0.xlsx`

Documentation implication:

- monolith output paths and version labels differ from the modular Snakemake pipeline
- new docs must describe that difference explicitly

## Known stale sources

Verified by current repository inspection:

- root `README.md` still lists old curated input filenames
- `biorempp_snakemake_version/README.md` still lists old curated input filenames
- `generate_database.R` header comments still contain at least one old input reference even though the executable file paths were updated
- historical docs under `.archive/` are useful but not authoritative

Documentation implication:

- code and config outrank README text, comments, and archived docs

## Immediate documentation priorities derived from the baseline

1. Restore a full MkDocs information architecture.
2. Publish the current curated input contract with exact literal filenames.
3. Document Snakemake pipeline stages from the actual rules and scripts.
4. Document the split between pipeline-integrated validation and GX validation.
5. Document the monolithic generator as a distinct execution surface.
