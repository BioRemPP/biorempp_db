<!--
Page status: verified
Audience: researchers, operators, maintainers, reviewers
Applies to: Snakemake and GX
Version scope: Snakemake output contract v1.1.0 and GX validator v1.1.0
Last verified on: 2026-06-24
Primary sources:
- biorempp_snakemake_version/config/config.yaml
- biorempp_snakemake_version/workflow/lib/io_contracts.R
- biorempp_snakemake_version/workflow/scripts/generation/00_check_inputs.R
- biorempp_snakemake_version/workflow/scripts/generation/01_load_local_data.R
- biorempp_snakemake_version/workflow/scripts/generation/02_fetch_kegg_info.R
- biorempp_snakemake_version/workflow/scripts/generation/03_fetch_kegg_data.R
- biorempp_snakemake_version/workflow/scripts/generation/04_merge_relationships.R
- biorempp_snakemake_version/workflow/scripts/generation/05_add_classifications.R
- biorempp_snakemake_version/workflow/scripts/generation/06_enrich_gene_info.R
- biorempp_snakemake_version/workflow/scripts/generation/07_extract_enzymes_export.R
- biorempp_validation/config/validation.yaml
- input_data directory listing
-->

# Data Sources

BioRemPP combines repository-local curated inputs with KEGG REST data fetched at runtime. This page describes those source families and their roles in the active pipeline contract.

## Source Families

The current implementation uses three distinct source families:

| Source family | Location | Owned by | Used for |
|---|---|---|---|
| Curated local inputs | `input_data/` | repository | release-specific compound, class, KO, and enzyme curation |
| External runtime source | `https://rest.kegg.jp` | KEGG | link expansion, release metadata, compound names, and reaction descriptions |
| Validation reference inputs | `biorempp_snakemake_version/results/` and `biorempp_validation/baselines/` | repository | GX validation against current outputs and frozen regression snapshots |

The final database is therefore not assembled from one upstream table. It is derived from curated inputs plus multiple KEGG endpoints, then validated against repository-owned contracts.

## Curated Local Inputs

The Snakemake workflow checks these exact files in repository-root `input_data/`:

| File | Main fields used by the workflow | Role in the active implementation |
|---|---|---|
| `kegglistcompounds.xlsx` | `cpd`, `compoundname` | loaded during local-data bundling and enforced by preflight; the current final export still takes public `compoundname` values from KEGG `compound_list` |
| `curated_regulated_compounds.xlsx` | `cpd`, `referenceAG` | defines the regulated compound universe and agency provenance |
| `curated_programatic_missing_compounds.xlsx` | `cpd`, `ko` | adds curated compound-KO pairs before KEGG expansion |
| `curated_compound_classes.xlsx` | `cpd`, `compoundclass` | provides class assignments later normalized and expanded into one row per class value |
| `kegglistko.txt` | `ko`, `genesymbol`, `genename` | provides KO-linked gene annotations |
| `curated_enzyem_names_extracted.txt` | one enzyme term per line | provides the curated term list used to derive `enzyme_activity` |

For column-level loading details and filename rules, see [Input Data Contract](../user-guide/input-data.md).

## KEGG Runtime Sources

The generation layer fetches KEGG data from `kegg.base_url`, currently `https://rest.kegg.jp`. The exact endpoint contract used by `03_fetch_kegg_data.R` is defined in `workflow/lib/io_contracts.R`.

| Endpoint | Current purpose in the workflow |
|---|---|
| `info/kegg` | captures release metadata into `results/metadata/kegg_release.json` |
| `link/ko/ec` | maps KO identifiers to EC identifiers |
| `link/ko/reaction` | maps KO identifiers to reaction identifiers |
| `link/compound/ec` | maps compounds to EC identifiers |
| `link/compound/reaction` | maps compounds to reaction identifiers |
| `link/enzyme/reaction` | maps EC identifiers to reaction identifiers |
| `list/reaction` | supplies `reaction_description` text |
| `list/cpd/` | supplies the final `compoundname` values used in export |

The generation script validates endpoint orientation and identifier structure before saving the KEGG bundle to `work/`.

## How The Sources Are Combined

The current assembly path is:

1. curated regulated compounds define the compound and agency key space
2. curated missing compounds add explicit compound-KO pairs
3. KEGG links expand those keys into `ec` and `reaction` combinations
4. curated compound classes add `compoundclass`
5. curated KO annotations add `genesymbol` and `genename`
6. curated enzyme terms extract `enzyme_activity`
7. KEGG `list/reaction` adds `reaction_description`
8. KEGG `list/cpd/` adds public `compoundname`

This division matters because not every public field comes from the same source family.

## Validation Reference Inputs

The GX validator does not read curated inputs directly. It reads:

| Validator source | Current location | Role |
|---|---|---|
| Current release artifacts | `../biorempp_snakemake_version/results` | validate the just-generated database, analysis JSON files, metadata, and workflow summary |
| Frozen regression baseline | `biorempp_validation/baselines/release_v1_1_0_kegg_118_0plus` | compare release-shape statistics and KEGG release metadata against a committed reference snapshot |

That means GX is validating pipeline outputs, not rebuilding the database from the original curated files.

## Source Boundaries

Some boundaries are easy to miss:

- `input_data/` is the curated input contract, not a complete representation of every public output field.
- KEGG is the only runtime external source used by the active Snakemake workflow.
- `results/` contains derived artifacts, not authoritative upstream source tables.
- the regression baseline is a repository-owned validation reference, not an upstream biological data source.

## Related Pages

- [Input Data Contract](../user-guide/input-data.md)
- [Configuration And IO Contracts](../pipeline-architecture/configuration-and-io.md)
- [Configuration Reference](../validation-gx/configuration.md)
