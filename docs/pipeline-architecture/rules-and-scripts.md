<!--
Page status: verified
Audience: maintainers, reviewers
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
- biorempp_snakemake_version/workflow/scripts/generation/
- biorempp_snakemake_version/workflow/scripts/analysis/
- biorempp_snakemake_version/workflow/scripts/validation/
- biorempp_snakemake_version/workflow/scripts/reporting/
- biorempp_snakemake_version/workflow/lib/utils.R
- biorempp_snakemake_version/workflow/lib/io_contracts.R
-->

# Rules And Scripts Map

This page maps each Snakemake rule to the script that implements it. It is a maintenance reference for reviewers and maintainers, not an execution guide.

## Shared Libraries

| File | Role |
|---|---|
| `workflow/lib/utils.R` | shared CLI parsing, logging, JSON I/O, CSV I/O, NA normalization, directory creation |
| `workflow/lib/io_contracts.R` | required input filenames, expected public database columns, KEGG endpoint definitions, value patterns |
| `workflow/lib/na_markers.txt` | optional NA-like token registry consumed through `utils.R` |

## Preflight Module

| Rule | Script | Main output | Responsibility |
|---|---|---|---|
| `preflight_check_inputs` | `workflow/scripts/generation/00_check_inputs.R` | `work/preflight_ok.json` | validate the configured curated input directory and required filenames |

The preflight checker lives under `workflow/scripts/generation/`, but it is wired to the dedicated preflight module in `00_preflight.smk`.

## Generation Module

| Rule | Script | Main output | Responsibility |
|---|---|---|---|
| `fetch_kegg_info` | `workflow/scripts/generation/02_fetch_kegg_info.R` | `results/metadata/kegg_release.json` | fetch and record KEGG release provenance |
| `load_local_data` | `workflow/scripts/generation/01_load_local_data.R` | `work/local_data.rds` | load curated local files into a single serialized bundle |
| `fetch_kegg_data` | `workflow/scripts/generation/03_fetch_kegg_data.R` | `work/kegg_data.rds` | fetch and normalize the KEGG link and list datasets used downstream |
| `merge_relationships` | `workflow/scripts/generation/04_merge_relationships.R` | `work/merged_compounds.rds` | build the compound-KO-reference universe and merge KEGG-supported relationships |
| `add_classifications` | `workflow/scripts/generation/05_add_classifications.R` | `work/classified_compounds.rds` | expand and join compound class annotations, then sanitize KO identifiers |
| `enrich_gene_info` | `workflow/scripts/generation/06_enrich_gene_info.R` | `work/enriched_compounds.rds` | attach gene symbols and gene names from the curated KO list |
| `extract_enzymes_export` | `workflow/scripts/generation/07_extract_enzymes_export.R` | database CSV and XLSX | attach reaction descriptions, derive enzyme activity, and write the public database outputs |

## Analysis Module

| Rule | Script | Main output | Responsibility |
|---|---|---|---|
| `basic_statistics` | `workflow/scripts/analysis/01_basic_statistics.R` | `results/analysis/basic_statistics.json` | core counts, public column list, and missing-value totals |
| `compound_statistics` | `workflow/scripts/analysis/02_compound_statistics.R` | `results/analysis/compound_statistics.json` | compound-level summaries and ranked views |
| `ko_statistics` | `workflow/scripts/analysis/03_ko_statistics.R` | `results/analysis/ko_statistics.json` | KO-level summaries and ranked views |
| `enzyme_statistics` | `workflow/scripts/analysis/04_enzyme_statistics.R` | `results/analysis/enzyme_statistics.json` | enzyme activity summaries and ranked views |
| `gene_statistics` | `workflow/scripts/analysis/05_gene_statistics.R` | `results/analysis/gene_statistics.json` | gene symbol and gene name summaries |
| `crosstab_statistics` | `workflow/scripts/analysis/06_crosstab_statistics.R` | `results/analysis/crosstab_statistics.json` | cross-tabulated summaries across major dimensions |
| `database_metadata` | `workflow/scripts/analysis/07_metadata.R` | `results/analysis/database_metadata.json` | release metadata, public schema description, completeness, and link-match context |
| `executive_summary` | `workflow/scripts/analysis/08_executive_summary.R` | `results/analysis/executive_summary.json` | condensed summary across the core analytical outputs |
| `complete_analysis` | `workflow/scripts/analysis/09_merge_complete_analysis.R` | `results/analysis/complete_analysis.json` | merge all analysis JSON artifacts into one composite bundle |

## Validation Module

| Rule | Script | Main output | Responsibility |
|---|---|---|---|
| `fetch_kegg_link_cache` | `workflow/scripts/validation/cache_kegg_links.py` | `cache/kegg_link_cache/*.tsv` | fetch and persist the five KEGG link payloads reused by the validation layer |
| `validate_keys_consistency` | `workflow/scripts/validation/01_validate_keys_consistency_api.py` | `results/metadata/keys_consistency_report.json` | classify rows with missing `ec` and/or `reaction` as justified or incorrect using the cached KEGG link graph |
| `validate_links_groundtruth_policy` | `workflow/scripts/validation/02_validate_links_groundtruth_policy_api.py` | `results/metadata/links_groundtruth_policy_report.json` | measure pair-level agreement and policy-aware coverage for populated KEGG-linked rows |

The validation scripts also rely on Python helpers in the same directory, including:

- `common_normalization.py`
- `kegg_api_client.py`

## Reporting Module

| Rule | Script | Main output | Responsibility |
|---|---|---|---|
| `build_run_report` | `workflow/scripts/reporting/build_run_report.py` | `results/reports/workflow_summary.json` | consolidate release context, validation summaries, reaction description coverage, and artifact hashes |

## Language Split

The workflow uses R for most generation and analysis stages, while Python is reserved for:

- validation cache and report generation
- final workflow reporting

That split follows the current codebase rather than an abstract design rule. The workflow is organized around rule contracts and script responsibilities, not around a language boundary.
