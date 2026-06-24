<!--
Page status: verified
Audience: researchers, operators, maintainers, reviewers
Applies to: Snakemake and GX
Version scope: Snakemake output contract v1.1.0 and GX validator v1.1.0
Last verified on: 2026-06-24
Primary sources:
- biorempp_snakemake_version/workflow/lib/io_contracts.R
- biorempp_snakemake_version/workflow/lib/utils.R
- biorempp_snakemake_version/workflow/scripts/generation/04_merge_relationships.R
- biorempp_snakemake_version/workflow/scripts/generation/05_add_classifications.R
- biorempp_snakemake_version/workflow/scripts/generation/06_enrich_gene_info.R
- biorempp_snakemake_version/workflow/scripts/generation/07_extract_enzymes_export.R
- biorempp_validation/config/validation.yaml
- biorempp_validation/great_expectations/expectations/database_critical.json
- biorempp_snakemake_version/results/database/biorempp_database_v1.1.0.csv
Known gaps:
- `workflow/scripts/analysis/07_metadata.R` still embeds a legacy `compoundclass` example that is not the authoritative controlled vocabulary; this page follows the exported data plus GX contract instead
-->

# Schema

This page documents the public BioRemPP database schema as exported by the active Snakemake workflow. It is intended for downstream consumers of the CSV and XLSX releases, not for internal `work/` intermediates.

## Public Export Contract

The current database release is written to:

- `results/database/biorempp_database_v1.1.0.csv`
- `results/database/biorempp_database_v1.1.0.xlsx`

The CSV contract is:

- delimiter `;`
- quoted fields enabled
- UTF-8 output
- missing values serialized as `NA`

The exported column order is fixed and currently contains 11 fields.

## Column Reference

| Column | Meaning | Populated from | Nullable | Notes |
|---|---|---|---|---|
| `cpd` | KEGG compound identifier | curated compound keys plus KEGG joins | no | normalized to `C#####`; GX critical contract enforces the pattern |
| `compoundclass` | normalized compound class label | `curated_compound_classes.xlsx` | no | one compound can generate multiple rows when multiple class values exist |
| `ko` | KEGG Orthology identifier | curated compound-KO supplementation plus KEGG expansion | no | normalized to `K#####`; GX critical contract enforces the pattern |
| `ec` | Enzyme Commission identifier | KEGG link expansion | yes | may remain `NA` when the current compound-KO pair is not resolved to an EC value |
| `reaction` | KEGG reaction identifier | KEGG link expansion | yes | normalized to `R#####` when present |
| `reaction_description` | reaction text associated with `reaction` | KEGG `list/reaction` | yes | written only after joining reaction identifiers to KEGG reaction text |
| `referenceAG` | agency provenance label for the regulated compound | `curated_regulated_compounds.xlsx` | no | controlled vocabulary checked by GX warning expectations |
| `compoundname` | public compound name | KEGG `compound_list` | no | in the active pipeline this comes from KEGG, not from the local `kegglistcompounds.xlsx` file |
| `genesymbol` | gene symbol associated with `ko` | `kegglistko.txt` | no | the enrichment step keeps the first non-empty symbol seen per KO |
| `genename` | gene name associated with `ko` | `kegglistko.txt` | no | the export step removes trailing ` [EC ...]` text when present |
| `enzyme_activity` | extracted enzyme term or fallback gene-name label | `curated_enzyem_names_extracted.txt` plus `genename` | no | extracted by regex against the curated term list; falls back to `genename` when no curated term matches |

## Nullability Contract

The current GX database contract explicitly allows null values in:

- `ec`
- `reaction`
- `reaction_description`

Every other public column is treated as required by the current critical validation suite.

For release review, remaining nulls in `ec` and `reaction` should be interpreted together with `results/metadata/keys_consistency_report.json`, not from the CSV alone.

## Controlled Vocabularies

The active GX warning contract currently expects these `referenceAG` values:

- `ATSDR`
- `CONAMA`
- `EPA`
- `EPC`
- `IARC1`
- `IARC2A`
- `IARC2B`
- `PSL`
- `WFD`

The active GX warning contract currently expects these `compoundclass` values:

- `Aliphatic`
- `Aromatic`
- `Chlorinated`
- `Halogenated`
- `Inorganic`
- `Metal`
- `Nitrogen-containing`
- `Organometallic`
- `Organophosphorus`
- `Organosulfur`
- `Polyaromatic`
- `Sulfur-containing`

These vocabularies are warning-level controls in GX, but they are also the most stable public reference for downstream consumers.

## Row Semantics

The database grain is not one row per compound.

Rows can multiply because the workflow expands across:

- agency provenance in `referenceAG`
- class assignments in `compoundclass`
- KO-linked `ec` and `reaction` combinations

The critical uniqueness check is therefore applied to the full exported column set, not to `cpd` alone.

## Boundary With Internal Fields

Intermediate generation steps use internal staging fields while assembling KEGG-supported combinations. Those fields are not part of the public schema unless they appear in the 11-column export contract above.

## Related Pages

- [Curated Inputs](curated-inputs.md)
- [Configuration And IO Contracts](../pipeline-architecture/configuration-and-io.md)
- [Configuration Reference](../validation-gx/configuration.md)
