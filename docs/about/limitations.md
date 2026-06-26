<!--
Page status: verified
Audience: researchers, reviewers
Applies to: Snakemake and GX
Version scope: Snakemake output contract v1.1.0
Last verified on: 2026-06-26
Primary sources:
- biorempp_snakemake_version/workflow/scripts/generation/04_merge_relationships.R
- biorempp_snakemake_version/workflow/lib/io_contracts.R
- biorempp_validation/config/validation.yaml
- biorempp_snakemake_version/results/metadata/keys_consistency_report.json
-->

# Known Limitations

BioRemPP is a knowledge integration resource that assembles compound-gene-enzyme associations from curated regulatory lists and KEGG functional annotations. The associations represent annotated functional potential, not experimentally confirmed biodegradation activity. The scope boundaries below apply when interpreting or reusing the database in downstream analysis.

## Scope

### Environmental Pollutant Focus

The compound universe is defined by lists compiled by nine environmental regulatory agencies. Compounds outside those lists are not represented regardless of their biodegradation relevance. Contaminants not yet regulated at the time of curation — such as per- and polyfluoroalkyl substances or microplastics — may be absent or only partially covered depending on each agency's classification state.

### Functional Potential, Not Realized Activity

The database encodes gene-level functional associations derived from KEGG annotations. Presence of a KO entry for a given compound indicates that KEGG links that orthology group to the compound's degradation context. It does not indicate that any specific organism expresses the gene, that the enzyme is active under environmental conditions, or that the compound is degraded at a measurable rate.

### No Pathway Completeness Validation

The database does not verify whether the genes associated with a compound constitute a complete degradation pathway. An entry linking a compound to an oxidase does not guarantee that subsequent ring-cleavage or mineralization steps are also represented.

### Single-Compound Perspective

Each row encodes a compound-gene association in isolation. Co-metabolic dependencies, competitive inhibition between substrates, and mixture effects are not represented.

## Data Sources

### KEGG Snapshot

The current release is built from KEGG Release 118.0+ (retrieved 2026-05-18). KEGG data is not re-fetched automatically between pipeline runs. Genes annotated, pathway assignments updated, or identifiers retired after that retrieval date are not reflected in this release.

### KO-Annotated Genes Only

Only genes assigned a KEGG Orthology identifier are reachable through the pipeline's link expansion logic. Genes with functional evidence in the literature but without a KO assignment are not captured unless they are explicitly added through the curated compound-KO supplementation file.

### Regulatory List Currency

The curated agency compound lists reflect regulatory priorities at the time of curation. Agency lists are updated on irregular schedules, and compounds may be reclassified, added, or removed in subsequent regulatory cycles.

## v1.1.0 Schema

### Nullable Fields and Evidence Levels

The three fields `ec`, `reaction`, and `reaction_description` are nullable by design. A null value means the compound-KO pair does not resolve to an EC or reaction identifier under the active KEGG link evidence policy. The pipeline applies three evidence models in decreasing completeness: `ko_complete` links, `ko_fallback` links, and `compound_bridge` links. A row produced under a less complete evidence model may lack EC or reaction support that a denser link set would provide.

The integrated validation report at `results/metadata/keys_consistency_report.json` classifies each remaining null as justified or unjustified based on available KEGG link data.

### Row Count Reflects Combinations

The 123,543 entries in the current release represent compound-KO-EC-reaction combinations, not unique compounds. The 384 unique compounds each generate multiple rows through class replication, agency replication, and EC-reaction combination enumeration. Row counts should not be treated as compound counts.

## Annotation

### Compound Classification

Compound classes are assigned through manual curation. Class boundaries reflect expert judgment at the time of curation. Compounds with ambiguous structural features may be classified differently by other classification systems. No hierarchical relationship is enforced between classes in the current schema.

### Enzyme Activity Extraction

The `enzyme_activity` field is populated by matching gene names against a curated 218-term lexicon. When no lexicon term matches, the full gene name is used as the fallback value. Novel enzyme families or non-standard gene name conventions may not be captured by the current lexicon.

### Gene Symbol Simplification

When a KEGG KO entry maps to multiple gene symbols, the enrichment step retains the first symbol in the loaded annotation file. Isoform-level distinctions between gene symbols within a single KO group are not preserved in the public schema.

## Suitable Applications

The database supports:

- functional annotation of KO-enriched metagenomes or genomes against regulated compound targets
- comparative screening of bioremediation gene coverage across samples or taxa
- hypothesis generation for experimental validation of degradation pathways
- educational illustration of enzyme diversity in xenobiotic metabolism contexts

## Applications Outside Scope

The database does not support:

- quantitative biodegradation modeling without additional kinetic or expression data
- organism-specific pathway reconstruction without mapping KO entries to taxon-level genomes
- real-time environmental monitoring or live compound surveillance
- regulatory risk assessment independent of the originating agency frameworks
- claims of experimental biodegradation activity without wet-lab validation

## Related Pages

- [Schema](../database-reference/schema.md)
- [Database Statistics](../database-reference/statistics.md)
- [Keys Consistency Report](../pipeline-validation/keys-consistency.md)
- [Project Scope](project-scope.md)
