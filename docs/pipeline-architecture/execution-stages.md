<!--
Page status: verified
Audience: maintainers, reviewers, advanced operators
Applies to: Snakemake
Version scope: Snakemake output contract v1.1.0
Last verified on: 2026-06-24
Primary sources:
- biorempp_snakemake_version/Snakefile
- biorempp_snakemake_version/workflow/rules/00_preflight.smk
- biorempp_snakemake_version/workflow/rules/10_generation.smk
- biorempp_snakemake_version/workflow/rules/20_analysis.smk
- biorempp_snakemake_version/workflow/rules/30_validation.smk
- biorempp_snakemake_version/workflow/rules/90_reporting.smk
-->

# Execution Stages

The stages below describe the logical progression of the DAG. They are not a strict serial timeline: Snakemake can run independent rules in parallel when their declared dependencies are already available.

## Stage Map

| Stage | Rules | Primary outputs | Architectural role |
|---|---|---|---|
| 1. Preflight | `preflight_check_inputs` | `work/preflight_ok.json` | validates the curated input directory and required filenames before local file-dependent rules proceed |
| 2. Curated local bundle | `load_local_data` | `work/local_data.rds` | loads all curated sources into one serialized object reused by downstream generation stages |
| 3. KEGG acquisition | `fetch_kegg_info`, `fetch_kegg_data` | `results/metadata/kegg_release.json`, `work/kegg_data.rds` | records KEGG release provenance and materializes the KEGG data bundle used for assembly and export |
| 4. Relationship assembly | `merge_relationships` | `work/merged_compounds.rds` | builds the `cpd`-`ko`-`referenceAG` universe and expands it through KEGG-supported mappings |
| 5. Classification | `add_classifications` | `work/classified_compounds.rds` | joins curated compound classes and normalizes KO identifiers into the exported form |
| 6. Gene enrichment | `enrich_gene_info` | `work/enriched_compounds.rds` | attaches `genesymbol` and `genename` from the curated KO list |
| 7. Release export | `extract_enzymes_export` | `results/database/biorempp_database_v1.1.0.csv`, `results/database/biorempp_database_v1.1.0.xlsx` | derives `enzyme_activity`, attaches reaction descriptions, and writes the public database contract |
| 8. Analysis | `basic_statistics`, `compound_statistics`, `ko_statistics`, `enzyme_statistics`, `gene_statistics`, `crosstab_statistics`, `database_metadata`, `executive_summary`, `complete_analysis` | `results/analysis/*.json` | computes structured summaries from the exported CSV and consolidates them into `complete_analysis.json` |
| 9. Integrated validation | `fetch_kegg_link_cache`, `validate_keys_consistency`, `validate_links_groundtruth_policy` | `cache/kegg_link_cache/*.tsv`, `results/metadata/keys_consistency_report.json`, `results/metadata/links_groundtruth_policy_report.json` | caches KEGG link payloads and evaluates the exported database against the active KEGG-linked validation logic |
| 10. Final reporting | `build_run_report` | `results/reports/workflow_summary.json` | assembles release provenance, validation summaries, reaction-description coverage, and artifact hashes into one audit summary |

## Dependency Notes

Three dependency details are important for interpreting the stage map correctly.

First, `fetch_kegg_info` does not depend on `preflight_check_inputs`. It can run as soon as the workflow starts because it only needs `kegg.base_url` and `kegg.info_endpoint`.

Second, `fetch_kegg_link_cache` also has no upstream file dependency. It belongs to the integrated validation layer, but its cache files may be created before the final database export is finished.

Third, the analysis and reporting layers are strictly file-driven. `complete_analysis` waits for the upstream analysis JSON artifacts, and `build_run_report` waits for the final database, `database_metadata.json`, `complete_analysis.json`, `kegg_release.json`, and both integrated validation reports.

## Contract Closure

`rule all` closes the DAG only when all public artifact families exist:

- database exports in `results/database/`
- analysis JSON artifacts in `results/analysis/`
- KEGG and validation metadata in `results/metadata/`
- workflow summary in `results/reports/workflow_summary.json`

That contract is the architectural definition of a complete pipeline release.
