<!--
Page status: verified
Audience: operators, maintainers, reviewers
Applies to: Snakemake
Version scope: Snakemake output contract v1.1.0
Last verified on: 2026-06-24
Primary sources:
- biorempp_snakemake_version/config/config.yaml
- biorempp_snakemake_version/workflow/lib/io_contracts.R
- biorempp_snakemake_version/workflow/scripts/generation/00_check_inputs.R
- biorempp_snakemake_version/workflow/scripts/generation/01_load_local_data.R
- biorempp_snakemake_version/workflow/scripts/generation/04_merge_relationships.R
- biorempp_snakemake_version/workflow/scripts/generation/05_add_classifications.R
- biorempp_snakemake_version/workflow/scripts/generation/06_enrich_gene_info.R
- biorempp_snakemake_version/workflow/scripts/generation/07_extract_enzymes_export.R
- input_data directory listing
-->

# Input Data Contract

This page documents the curated input contract used by the active Snakemake workflow. The files below must exist in the repository-root `input_data/` directory, because `biorempp_snakemake_version/config/config.yaml` sets `paths.input_dir: "../input_data"`.

## Required Files

The workflow currently requires these exact filenames:

- `kegglistcompounds.xlsx`
- `curated_regulated_compounds.xlsx`
- `curated_programatic_missing_compounds.xlsx`
- `curated_compound_classes.xlsx`
- `kegglistko.txt`
- `curated_enzyem_names_extracted.txt`

The preflight rule `preflight_check_inputs` validates this contract before any generation step runs.

## Role Of Each Input

| File | Loaded fields | Used by | Operational role |
|---|---|---|---|
| `kegglistcompounds.xlsx` | `cpd`, `compoundname` | loaded into `local_data.rds` | part of the curated local bundle; in the current active workflow, final compound names are taken from the KEGG `compound_list` fetched during `03_fetch_kegg_data.R` |
| `curated_regulated_compounds.xlsx` | `cpd`, `referenceAG` | `04_merge_relationships.R` | defines the regulated compound universe and preserves agency provenance through `referenceAG` |
| `curated_programatic_missing_compounds.xlsx` | `cpd`, `ko` | `04_merge_relationships.R` | injects curated compound-KO pairs into the key universe before expansion against KEGG links |
| `curated_compound_classes.xlsx` | expected to include `cpd` and `compoundclass` | `05_add_classifications.R` | assigns compound classes and expands comma-separated class values into one row per class |
| `kegglistko.txt` | `ko`, `genesymbol`, `genename` | `06_enrich_gene_info.R` | provides gene annotations for KO-based enrichment |
| `curated_enzyem_names_extracted.txt` | one enzyme term per line | `07_extract_enzymes_export.R` | provides the curated term list used to derive `enzyme_activity` from gene names |

## Input Normalization Rules

The workflow normalizes several identifiers after loading the curated files:

- `cpd` values are normalized to the `C#####` form
- `ko` values are normalized to the `K#####` form
- empty strings and NA-like markers are converted to real missing values
- `compoundclass` values are split on commas, trimmed, and cleaned before joining

For `curated_compound_classes.xlsx`, the current script also performs two content normalizations:

- removes the suffix ` (repeated)` from class labels
- rewrites `Organometalic` to `Organometallic`

These rules are implementation details of the active pipeline and should be preserved when curating upstream files.

## How The Input Contract Is Verified

The preflight stage writes `work/preflight_ok.json` only after confirming that:

- the configured input directory exists
- every file listed in `REQUIRED_INPUT_FILES` is present

If the contract is incomplete, the workflow stops before `load_local_data` or any KEGG fetch step runs.

## Practical Curation Notes

- Keep filenames literal. The workflow does not auto-discover renamed files.
- Keep the curated files in the repository-root `input_data/`, not inside `biorempp_snakemake_version/`.
- For `curated_programatic_missing_compounds.xlsx`, only the `cpd` and `ko` columns are retained after loading.
- For `kegglistko.txt`, the loader lowercases header names before selecting `ko`, `genesymbol`, and `genename`.
- For `curated_enzyem_names_extracted.txt`, blank lines are ignored and duplicated terms are removed during loading.

## Related Pages

- [Running The Snakemake Pipeline](run-snakemake.md)
- [Understanding Outputs](understanding-output.md)
- [Troubleshooting](troubleshooting.md)
