<!--
Page status: verified
Audience: researchers, reviewers
Applies to: Snakemake
Version scope: Snakemake output contract v1.1.0
Last verified on: 2026-06-26
Primary sources:
- biorempp_snakemake_version/results/analysis/basic_statistics.json
- biorempp_snakemake_version/results/analysis/executive_summary.json
- biorempp_snakemake_version/results/analysis/compound_statistics.json
- biorempp_snakemake_version/results/analysis/enzyme_statistics.json
- biorempp_snakemake_version/results/analysis/ko_statistics.json
- biorempp_snakemake_version/results/metadata/kegg_release.json
Observed artifacts:
- biorempp_snakemake_version/results/analysis/basic_statistics.json
- biorempp_snakemake_version/results/metadata/kegg_release.json
-->

# Database Statistics

This page reports the quantitative characteristics of the BioRemPP database release generated from KEGG Release 118.0+ (retrieved 2026-05-18). All values are derived from the analysis artifacts produced by the active Snakemake workflow.

## Core Metrics

| Metric | Value |
|---|---|
| Total entries | 123,543 |
| Public columns | 11 |
| Unique compounds | 384 |
| Unique KO entries | 1,543 |
| Unique compound classes | 12 |
| Unique gene symbols | 1,517 |
| Unique gene names | 1,422 |
| Unique enzyme activities | 206 |
| Reference agencies | 9 |
| KEGG release | 118.0+ |

## EC and Reaction Coverage

Three public columns are nullable: `ec`, `reaction`, and `reaction_description`. The current release fills these columns as follows:

| Column | Present | Missing | Fill rate |
|---|---|---|---|
| `ec` | 122,582 | 961 | 99.2% |
| `reaction` | 121,320 | 2,223 | 98.2% |
| `reaction_description` | 121,320 | 2,223 | 98.2% |

Rows with missing `ec` or `reaction` values represent compound-KO pairs where the current KEGG link structure does not resolve to an EC or reaction identifier under the active evidence policy. The integrated validation report at `results/metadata/keys_consistency_report.json` classifies each case as justified or unjustified based on the available KEGG link data.

## Row Grain and Version Comparison

The database grain is one row per compound-KO-EC-reaction combination. A single compound and KO pair produces multiple rows when more than one EC or reaction identifier is supported by KEGG links.

| Release | Columns | Total entries | Unique compounds | KEGG reference |
|---|---|---|---|---|
| v1.0.0 | 8 | 10,871 | 384 | Release Dec,23 |
| v1.1.0 | 11 | 123,543 | 384 | Release 118.0+ |

The increase from 10,871 to 123,543 entries reflects the addition of `ec`, `reaction`, and `reaction_description` to the schema and the corresponding expansion of rows through EC-reaction combination enumeration. The compound and agency universe is unchanged between releases.

## Compound Distribution

### By Chemical Class

| Class | Unique compounds | % of total |
|---|---|---|
| Aromatic | 123 | 32.0% |
| Chlorinated | 117 | 30.5% |
| Nitrogen-containing | 115 | 29.9% |
| Polyaromatic | 98 | 25.5% |
| Aliphatic | 94 | 24.5% |
| Metal | 29 | 7.6% |
| Inorganic | 26 | 6.8% |
| Sulfur-containing | 20 | 5.2% |
| Organophosphorus | 13 | 3.4% |
| Organometallic | 9 | 2.3% |
| Halogenated | 8 | 2.1% |
| Organosulfur | 1 | 0.3% |

Percentages sum to more than 100% because a compound may belong to multiple classes.

### By Environmental Agency

| Agency | Unique compounds | % of total |
|---|---|---|
| ATSDR | 191 | 49.7% |
| IARC2B | 130 | 33.9% |
| PSL | 99 | 25.8% |
| EPC | 91 | 23.7% |
| WFD | 84 | 21.9% |
| EPA | 83 | 21.6% |
| IARC1 | 56 | 14.6% |
| CONAMA | 43 | 11.2% |
| IARC2A | 29 | 7.6% |

Percentages are calculated relative to the 384 unique compounds. A compound may appear under more than one agency.

### Most Represented Compounds

The five compounds with the highest number of database entries:

| Compound | KEGG ID | Entries |
|---|---|---|
| Ammonia | C00014 | 60,806 |
| Formaldehyde | C00067 | 14,997 |
| Trichloroethene | C06790 | 5,100 |
| Acetaldehyde | C00084 | 2,208 |
| Benzo[a]pyrene | C07535 | 2,135 |

High entry counts reflect broad gene-enzyme coverage through KEGG link expansion, not compound abundance in environmental samples.

## Gene and KO Distribution

The 1,543 unique KO entries have a heavily right-skewed frequency distribution:

| Statistic | Value |
|---|---|
| Maximum entries per KO | 2,690 |
| Mean entries per KO | 80.1 |
| Median entries per KO | 6 |
| Maximum compounds per KO | 27 |
| Mean compounds per KO | 2.2 |

## Enzyme Coverage

Of the 206 unique enzyme activities, the five most represented families account for a majority of database entries:

| Enzyme activity | Entries | Unique compounds | Unique KO |
|---|---|---|---|
| cytochrome P450 | 17,729 | 35 | 36 |
| dioxygenase | 11,414 | 88 | 74 |
| hydrolase | 7,818 | 26 | 31 |
| dehydrogenase | 6,813 | 106 | 165 |
| reductase | 6,314 | 53 | 91 |

The enzyme activity field is derived by matching gene names against a curated 218-term lexicon. Entries that do not match any lexicon term receive the full gene name as their `enzyme_activity` value.

## Reproducibility

All values on this page are derived from the analysis artifacts produced by the active Snakemake workflow. To reproduce these statistics, run the pipeline and inspect `results/analysis/basic_statistics.json`, `results/analysis/compound_statistics.json`, `results/analysis/enzyme_statistics.json`, and `results/analysis/ko_statistics.json`. The KEGG release context is recorded in `results/metadata/kegg_release.json`.

## Related Pages

- [Schema](schema.md)
- [Analysis Artifacts](analysis-artifacts.md)
- [Provenance and Release Semantics](provenance-and-release.md)
- [Keys Consistency Report](../pipeline-validation/keys-consistency.md)
