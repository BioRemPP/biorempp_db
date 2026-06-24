<!--
Page status: verified
Audience: researchers, operators, maintainers, reviewers
Applies to: Snakemake
Version scope: Snakemake output contract v1.1.0
Last verified on: 2026-06-24
Primary sources:
- biorempp_snakemake_version/workflow/lib/io_contracts.R
- biorempp_snakemake_version/workflow/scripts/generation/01_load_local_data.R
- biorempp_snakemake_version/workflow/scripts/generation/04_merge_relationships.R
- biorempp_snakemake_version/workflow/scripts/generation/05_add_classifications.R
- biorempp_snakemake_version/workflow/scripts/generation/06_enrich_gene_info.R
- biorempp_snakemake_version/workflow/scripts/generation/07_extract_enzymes_export.R
- input_data directory listing
Known gaps:
- `kegglistcompounds.xlsx` is still required and loaded into `local_data.rds`, but the active downstream generation path does not consume `local_data$kegg_compounds`
-->

# Curated Inputs

This page explains what each curated input contributes to the assembled database. It complements the [Input Data Contract](../user-guide/input-data.md), which documents file presence and loader rules.

## Contribution Map

| Curated file | Public columns affected | How it shapes the database |
|---|---|---|
| `curated_regulated_compounds.xlsx` | `cpd`, `referenceAG` | defines the regulated compound universe and preserves the agency label carried into the final export |
| `curated_programatic_missing_compounds.xlsx` | `cpd`, `ko` | adds curated compound-KO pairs before KEGG expansion |
| `curated_compound_classes.xlsx` | `compoundclass` | assigns classes and can expand one compound into multiple class-specific rows |
| `kegglistko.txt` | `genesymbol`, `genename` | supplies KO-linked gene annotations joined after classification |
| `curated_enzyem_names_extracted.txt` | `enzyme_activity` | supplies the curated term list used to extract activity labels from `genename` |
| `kegglistcompounds.xlsx` | none in the current public export path | remains part of the required input contract, but the active pipeline does not use it to populate the exported `compoundname` field |

## What Establishes The Database Key Space

Two curated files determine which compound-KO combinations can enter the database:

### `curated_regulated_compounds.xlsx`

This file is normalized into distinct `cpd` plus `referenceAG` pairs. It anchors the regulated compound universe and is the only curated source for the public `referenceAG` column.

### `curated_programatic_missing_compounds.xlsx`

This file is normalized into distinct `cpd` plus `ko` pairs. The generation script then joins those curated pairs back to the regulated compound universe so the resulting keys retain agency provenance.

Together, these files define the curated seed space that later expands against KEGG links.

## What Establishes Row Multiplicity

The final database can contain multiple rows for the same compound because curated inputs are applied at different stages.

### Agency replication

`referenceAG` is preserved through the generation path. If a compound appears under multiple agencies, the downstream database retains that distinction.

### Class replication

`curated_compound_classes.xlsx` is split on commas and expanded into one row per class value. The current classification step also:

- trims whitespace
- removes the suffix ` (repeated)`
- normalizes `Organometalic` to `Organometallic`

This means a single `cpd` and `ko` combination can produce multiple exported rows once classes are applied.

## What Supplies Gene And Enzyme Annotation

### `kegglistko.txt`

The enrichment step lowercases the file headers, selects `ko`, `genesymbol`, and `genename`, normalizes KO values, then keeps the first annotation seen per KO before joining that annotation into the classified data.

### `curated_enzyem_names_extracted.txt`

The export step converts the curated term list into a case-insensitive regex. It then:

- extracts the first matching enzyme term from `genename`
- falls back to the full `genename` when no curated term matches

That fallback behavior is part of the current public `enzyme_activity` semantics.

## Important Boundary: `compoundname`

`kegglistcompounds.xlsx` is still a required curated input, but the active public `compoundname` field is not taken from it.

The final `compoundname` comes from the KEGG `compound_list` dataset joined in `04_merge_relationships.R`. For consumers of the exported database, KEGG is therefore the authoritative source of `compoundname` in the current Snakemake implementation.

## What These Files Do Not Determine Alone

No curated input by itself determines the full final row shape. Public rows only emerge after curated keys are expanded through KEGG-supported `ec` and `reaction` relationships and then enriched with class, gene, and enzyme annotations.

## Related Pages

- [Schema](schema.md)
- [Data Sources](../reference/data-sources.md)
- [Input Data Contract](../user-guide/input-data.md)
