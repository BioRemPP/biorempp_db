<!--
Page status: verified
Audience: researchers, operators, maintainers, reviewers
Applies to: Snakemake and GX
Version scope: Snakemake output contract v1.1.0 and GX validator v1.1.0
Last verified on: 2026-06-24
Primary sources:
- biorempp_snakemake_version/Snakefile
- biorempp_snakemake_version/config/config.yaml
- biorempp_snakemake_version/workflow/lib/io_contracts.R
- biorempp_snakemake_version/workflow/rules/30_validation.smk
- biorempp_snakemake_version/workflow/scripts/generation/04_merge_relationships.R
- biorempp_validation/config/validation.yaml
- biorempp_validation/src/biorempp_validation/run_validation.py
- biorempp_validation/src/biorempp_validation/json_to_dataframe.py
- biorempp_validation/great_expectations/checkpoints/critical_gate.yml
- biorempp_validation/great_expectations/checkpoints/warning_report.yml
-->

# Glossary

This glossary defines the recurring terms used across the official BioRemPP documentation.

## Terms

| Term | Meaning in this repository |
|---|---|
| Analysis artifacts | The JSON files written to `biorempp_snakemake_version/results/analysis/`, including `basic_statistics.json`, `database_metadata.json`, and `complete_analysis.json`. |
| Baseline snapshot | The committed reference tree under `biorempp_validation/baselines/` used by GX `regression_detection`. |
| `compoundclass` | Public database column that stores the normalized class assigned to each compound row. |
| `cpd` | Compound identifier column normalized to the KEGG `C#####` form. |
| Critical checkpoint | The GX checkpoint defined in `critical_gate.yml`; its failures are treated as blocking when `fail_on_critical: true`. |
| Curated input | A repository-local file in `input_data/` required by the Snakemake workflow. |
| Drift threshold | A configured warning range in `validation.yaml` used to detect unexpected variation in row counts or key uniqueness metrics. |
| `ec` | Enzyme Commission identifier column used in the exported database and in KEGG link joins. |
| GX | The standalone Great Expectations validation project in `biorempp_validation/`. |
| Internal consistency | The GX mode that compares the current database CSV with the current run's analysis, metadata, and workflow-report artifacts. |
| KEGG | The external data service queried from `https://rest.kegg.jp` during the active Snakemake run. |
| KEGG link cache | The TSV cache written under `cache/kegg_link_cache/` by the pipeline-integrated validation layer. |
| KO | KEGG Orthology identifier normalized to the `K#####` form. |
| `referenceAG` | Public database column that stores the source agency label attached to a regulated compound. |
| Regression detection | The GX mode that compares current outputs against a frozen baseline snapshot committed in the repository. |
| Release contract | The exact set of public filenames, schema fields, and validation expectations associated with a specific version such as `v1.1.0`. |
| `reaction` | Public database column normalized to the KEGG `R#####` reaction identifier form. |
| `reaction_description` | Public database column populated from KEGG `list/reaction` text for rows that have a reaction identifier. |
| Snakemake pipeline | The modular workflow in `biorempp_snakemake_version/` that generates the database and its integrated reports. |
| Warning checkpoint | The GX checkpoint defined in `warning_report.yml`; its failures are reported and can also block when `fail_on_warning: true`. |
| Workflow summary | The run-level JSON artifact written to `results/reports/workflow_summary.json`. |

## Reading Notes

The same term can appear in different layers with different roles:

- `validation` inside the Snakemake pipeline refers to the integrated report-producing rules in `30_validation.smk`.
- `validation` inside `biorempp_validation/` refers to the standalone GX project.
- `results/metadata/` files are pipeline outputs, while `biorempp_validation/results/` files are validator outputs.

## Related Pages

- [Overview](../index.md)
- [Pipeline Validation Overview](../pipeline-validation/overview.md)
- [Validation Modes](../validation-gx/validation-modes.md)
