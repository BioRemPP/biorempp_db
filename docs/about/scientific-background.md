<!--
Page status: verified
Audience: researchers, reviewers
Applies to: Snakemake and GX
Version scope: repository contract v1.1.0
Last verified on: 2026-06-26
Primary sources:
- biorempp_snakemake_version/workflow/scripts/generation/04_merge_relationships.R
- biorempp_snakemake_version/workflow/lib/io_contracts.R
- biorempp_validation/config/validation.yaml
- biorempp_snakemake_version/results/analysis/basic_statistics.json
-->

# Scientific Background

## Bioremediation in the Genomic Era

Bioremediation exploits the metabolic capacity of microorganisms to transform or mineralize environmental pollutants. The functional basis for this capacity is encoded at the gene level: specific enzyme families — dioxygenases, dehalogenases, cytochrome P450 monooxygenases, and reductases among others — catalyze key steps in the degradation of organic and inorganic contaminants. High-throughput sequencing has made it possible to survey this functional potential directly from environmental samples through metagenomics and metatranscriptomics, but interpreting genomic data in a bioremediation context requires structured reference resources that connect compound identity to gene function and to the regulatory significance of the compounds under study.

## The Data Integration Problem

Three information sources carry the knowledge needed for this interpretation, but they are not integrated by default.

The KEGG database provides the most comprehensive public catalog of ortholog-level enzyme functions and metabolic pathway annotations. However, KEGG does not organize its data around regulatory compound lists, and identifying which KEGG-annotated genes are relevant to a specific priority pollutant requires cross-referencing that is not built into the KEGG interface.

Environmental regulatory agencies — including ATSDR, EPA, CONAMA, IARC, and others — publish curated lists of priority pollutants and contaminants of concern, representing decades of epidemiological and environmental risk assessment. These lists do not carry gene or enzyme annotations.

Manual curation in the literature fills gaps in KEGG link coverage, particularly for compound-KO pairs that direct API queries do not resolve. This curated knowledge is distributed across publications and not consolidated into a queryable resource.

BioRemPP integrates these three sources into a single structured database designed for functional annotation and bioremediation screening.

## Design Rationale

BioRemPP anchors its compound universe to regulatory agency lists and expands compound-gene associations through KEGG REST endpoints and curated supplementation.

The assembly applies three evidence models in decreasing completeness. The `ko_complete` model links compound to KO through direct KO-to-EC and KO-to-reaction KEGG relationships. The `ko_fallback` model uses partial KEGG link coverage. The `compound_bridge` model establishes associations through curated compound-KO pairs that bypass direct KEGG link resolution. Each model produces rows in the database. The nullable fields `ec` and `reaction` reflect this design: a row produced under a less complete evidence model may lack EC or reaction support that a denser link set would provide. This is an explicit representation of annotation completeness, not a data defect.

The pipeline is fully reproducible. Snakemake orchestrates assembly in a defined rule order with all intermediate outputs pinned to explicit filenames and configurations. A companion Great Expectations validator applies structured quality checks and regression detection against a committed baseline, ensuring that successive runs against the same KEGG release produce statistically stable outputs.

## Comparison with Related Resources

BioRemPP occupies a distinct position among databases relevant to biodegradation and xenobiotic metabolism.

| Resource | Primary focus | Regulatory compound lists | Gene annotations (KO) | EC numbers | Reproducible pipeline |
|---|---|---|---|---|---|
| KEGG BRITE Xenobiotics | Metabolic function annotation | Partial | ✓ | ✓ | N/A |
| MetaCyc | Manually curated metabolic pathways | Partial | ✓ | ✓ | N/A |
| UM-BBD / BioCat | Biodegradation pathway catalog | Partial | ✓ | Partial | Archived |
| BioTransformer 3.0 | Biotransformation prediction | ✓ | — | ✓ | — |
| BioRemPP v1.1.0 | Bioremediation functional potential | ✓ (9 agencies) | ✓ (KEGG KO) | ✓ | ✓ (Snakemake + GX) |

The primary distinguishing feature of BioRemPP is the integration of regulatory compound provenance with gene-level functional annotation across a reproducible and versioned generation pipeline.

## Reference Agency Selection

The nine reference agencies were selected to achieve broad geographic and regulatory coverage while maintaining focus on environmental and occupational health contexts.

| Agency code | Full name | Geography | Regulatory focus |
|---|---|---|---|
| ATSDR | Agency for Toxic Substances and Disease Registry | USA | Public health hazards at contaminated sites |
| EPA | Environmental Protection Agency | USA | Priority pollutants and water quality |
| CONAMA | Conselho Nacional do Meio Ambiente | Brazil | National environmental standards |
| EPC | European Priority Chemicals | European Union | Priority substances in water environments |
| WFD | Water Framework Directive | European Union | Surface and groundwater quality |
| IARC1 | International Agency for Research on Cancer — Group 1 | International | Compounds carcinogenic to humans |
| IARC2A | International Agency for Research on Cancer — Group 2A | International | Compounds probably carcinogenic to humans |
| IARC2B | International Agency for Research on Cancer — Group 2B | International | Compounds possibly carcinogenic to humans |
| PSL | Priority Substances List | Canada | Substances of concern under CEPA |

Together these agencies cover North American, European, South American, and international regulatory frameworks across environmental, carcinogenesis, and occupational health domains.

## Intended Applications

BioRemPP is designed to support:

- functional annotation of metagenomes or genomes against regulated environmental contaminants
- identification of gene and enzyme candidates for experimental bioremediation studies
- comparative screening of bioremediation potential across samples or taxa
- hypothesis-driven analysis of pollutant-degradation gene coverage in environmental datasets

The database supports in silico hypothesis generation. Experimental validation is required before making claims about active biodegradation in specific organisms or environments.

## Related Pages

- [Known Limitations](limitations.md)
- [Database Statistics](../database-reference/statistics.md)
- [Schema](../database-reference/schema.md)
- [Project Scope](project-scope.md)
