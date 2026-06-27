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
- biorempp_snakemake_version/results/analysis/basic_statistics.json
- .archive/schema_biorempp.yaml
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
- UTF-8 encoding
- missing values serialized as `NA`

The exported column order is fixed and contains 11 fields. The v1.1.0 release contains 123,543 rows across 384 unique compounds.

## Schema Design

The BioRemPP schema follows a flat, denormalized structure. This design reflects four principles:

- **Simplicity** — a single tidy table supports direct import into R, Python, and spreadsheet environments without relational joins
- **Analytical optimization** — denormalized rows make filtering, grouping, and aggregation straightforward for exploratory analysis
- **Interoperability** — semicolon-delimited UTF-8 CSV keeps the release compatible across bioinformatics pipelines and downstream tools
- **FAIR compliance** — controlled vocabularies for compounds, KOs, agencies, EC numbers, and reactions improve findability and reuse

The trade-off is that compound-level queries must use `unique()` or `distinct()` rather than counting rows directly.

## Column Reference

| Column | Type | Pattern | Nullable | Cardinality | Populated from |
|---|---|---|---|---|---|
| `cpd` | Character | `C#####` | no | 384 | curated compound keys plus KEGG joins |
| `compoundclass` | Character | controlled vocabulary | no | 12 | `curated_compound_classes.xlsx` |
| `ko` | KEGG Orthology identifier | `K#####` | no | 1,543 | curated compound-KO supplementation plus KEGG expansion |
| `ec` | Character | EC notation or `NA` | **yes** | 994 resolved | KEGG link expansion |
| `reaction` | Character | `R#####` or `NA` | **yes** | 1,939 resolved | KEGG link expansion |
| `reaction_description` | Character | free text or `NA` | **yes** | 1,939 resolved | KEGG `list/reaction` |
| `referenceAG` | Character | controlled vocabulary | no | 9 | `curated_regulated_compounds.xlsx` |
| `compoundname` | Character | KEGG standard name | no | 383 | KEGG `list/cpd/` endpoint at runtime |
| `genesymbol` | Character | standard gene abbreviation | no | 1,517 | `kegglistko.txt` |
| `genename` | Character | free text | no | 1,422 | `kegglistko.txt` |
| `enzyme_activity` | Character | curated enzyme-family term | no | 206 | `curated_enzyem_names_extracted.txt` plus `genename` |

### `cpd`

KEGG Compound identifier normalized to the `C#####` format. GX critical contract enforces the regex `^C\d{5}$` on every row. A single compound appears in many rows because the export expands across KO, agency, class, and reaction combinations. Each `cpd` value is resolvable at `https://www.kegg.jp/entry/{cpd}` and cross-links to PubChem and ChEBI through the KEGG Compound entry.

### `compoundclass`

Chemical structural classification sourced from `curated_compound_classes.xlsx`. A compound may appear under more than one class when multiple annotations are retained, which contributes to row multiplicity. Values are normalized during generation: the suffix ` (repeated)` is removed and `Organometalic` is corrected to `Organometallic`.

### `ko`

KEGG Orthology identifier normalized to the `K#####` format. GX critical contract enforces the regex `^K\d{5}$`. The same KO can recur across multiple compounds, agencies, EC numbers, and reactions. Each `ko` value is resolvable at `https://www.kegg.jp/entry/{ko}` and links to KEGG Pathway maps and modules.

### `ec`

Enzyme Commission number. This field is semantically nullable: rows produced under a less complete evidence model may lack an EC resolution. Missing values are serialized as `NA`. The current release has 961 unresolved rows, giving an EC completeness rate of 99.22%. Remaining nulls are explained by `results/metadata/keys_consistency_report.json`.

### `reaction`

KEGG Reaction identifier normalized to the `R#####` format when present. This field is semantically nullable for the same reason as `ec`. Missing values are serialized as `NA`. The current release has 2,223 unresolved rows, giving a reaction completeness rate of 98.20%. Each resolved `reaction` value is resolvable at `https://www.kegg.jp/entry/{reaction}`.

### `reaction_description`

Human-readable reaction text retrieved from KEGG `list/reaction`. Coverage mirrors the `reaction` column exactly: when `reaction` is `NA`, `reaction_description` is also `NA`. The 2,223 unresolved rows in `reaction` produce the same count of unresolved rows here.

### `referenceAG`

Agency provenance label identifying which regulatory framework flags the compound as environmentally relevant. Controlled vocabulary enforced at warning level by GX. A compound can be listed by multiple agencies, so agency codes recur across many rows.

### `compoundname`

Human-readable compound name taken from the KEGG `list/cpd/` endpoint at runtime during `03_fetch_kegg_data.R`. This value is not sourced from the local `kegglistcompounds.xlsx` file. Names follow KEGG standard nomenclature. One compound in the v1.1.0 release does not have a resolvable display name, yielding 383 distinct names across 384 compounds.

### `genesymbol`

Standard gene abbreviation linked to the KO entry via `kegglistko.txt`. The enrichment step keeps the first non-empty symbol seen per KO after normalization. Values can represent human-style HGNC symbols or organism-specific microbial abbreviations.

### `genename`

Expanded gene or function description from `kegglistko.txt`. The export step removes trailing ` [EC ...]` text when present. This field provides a more interpretable functional label than the compact gene symbol alone.

### `enzyme_activity`

Simplified enzyme activity family label derived by applying a curated regex against `genename` values, using the term list in `curated_enzyem_names_extracted.txt`. When no curated term matches, the full `genename` value is used as a fallback. This field supports aggregate queries by enzyme family.

## Nullability Contract

The GX critical checkpoint explicitly permits null values in:

- `ec`
- `reaction`
- `reaction_description`

Every other public column is treated as required by the critical validation suite. For release review, remaining nulls in `ec` and `reaction` should be interpreted together with `results/metadata/keys_consistency_report.json`, which classifies each missing value as justified or requiring attention.

## Controlled Vocabularies

### `referenceAG`

| Code | Full name | Jurisdiction | Compounds |
|---|---|---|---|
| `ATSDR` | Agency for Toxic Substances and Disease Registry | USA | 191 |
| `IARC2B` | IARC Group 2B — Possibly carcinogenic to humans | International | 130 |
| `PSL` | Priority Substances List | Canada | 99 |
| `EPC` | Environmental Priority Chemicals | Europe | 91 |
| `WFD` | Water Framework Directive | European Union | 84 |
| `EPA` | U.S. Environmental Protection Agency | USA | 83 |
| `IARC1` | IARC Group 1 — Carcinogenic to humans | International | 56 |
| `CONAMA` | Conselho Nacional do Meio Ambiente | Brazil | 43 |
| `IARC2A` | IARC Group 2A — Probably carcinogenic to humans | International | 29 |

Percentages are calculated over 384 unique compounds. Compounds may appear under more than one agency.

### `compoundclass`

| Class | Compounds | Description |
|---|---|---|
| `Aromatic` | 123 | Benzene ring-containing compounds |
| `Chlorinated` | 117 | Halogenated with chlorine substituents |
| `Nitrogen-containing` | 115 | Compounds with nitrogen functional groups |
| `Polyaromatic` | 98 | Multiple fused aromatic rings (PAHs) |
| `Aliphatic` | 94 | Straight-chain or branched hydrocarbons |
| `Metal` | 29 | Metal and metal-containing compounds |
| `Inorganic` | 26 | Inorganic compounds (ammonia, sulfates, nitrates) |
| `Sulfur-containing` | 20 | Organic sulfur functional groups |
| `Organophosphorus` | 13 | Phosphorus-containing organic compounds |
| `Organometallic` | 9 | Compounds with direct metal-carbon bonds |
| `Halogenated` | 8 | Halogenated compounds (bromo/fluoro variants) |
| `Organosulfur` | 1 | Organic sulfur compounds |

A compound may appear under more than one class; the sum of compounds per class therefore exceeds 384.

## Row Semantics and Cardinality

The database grain is not one row per compound. Rows multiply because the workflow expands across three independent dimensions:

- **Agency provenance** — a compound listed by multiple agencies generates one row per agency
- **Compound class** — a compound with multiple class annotations generates one row per class
- **KO-to-EC and KO-to-reaction expansion** — a single KO entry can resolve to multiple EC numbers and reactions, producing one row per combination

Three many-to-many relationships shape the final row count:

| Relationship | Type | Description |
|---|---|---|
| Compound-to-KO | Many-to-many | One compound connects to multiple KOs; one KO recurs across multiple compounds. Example: Ammonia (C00014) links to 334 unique KO groups. |
| KO-to-EC/Reaction | One-to-many | A single KO expands into multiple EC and reaction combinations when multiple biochemical mappings exist in KEGG. |
| Compound-to-Agency | Many-to-many | A compound listed by several agencies contributes one row per agency, so row counts per agency exceed the unique compound count. |

The critical uniqueness check is applied to the full 11-column row, not to `cpd` alone. No exact duplicate rows were observed in the v1.1.0 release.

## Data Quality

Eight core columns are fully populated. Three columns are semantically nullable by design:

| Column | Completeness | Missing rows |
|---|---|---|
| `ec` | 99.22% | 961 |
| `reaction` | 98.20% | 2,223 |
| `reaction_description` | 98.20% | 2,223 |

All `cpd` values match `^C\d{5}$`. All `ko` values match `^K\d{5}$`. All `reaction` values resolve to `^R\d{5}$` or the `NA` sentinel. `ec` values resolve to standard EC notation or `NA`. Identifier consistency is enforced by the GX critical checkpoint on every release.

## Usage

The release CSV can be loaded directly in R or Python by specifying the semicolon delimiter.

**R**

```r
library(readr)
db <- read_delim("biorempp_database_v1.1.0.csv", delim = ";")

# Unique compounds
length(unique(db$cpd))  # 384

# Compounds per agency
db |>
  dplyr::group_by(referenceAG) |>
  dplyr::summarise(n_cpd = dplyr::n_distinct(cpd)) |>
  dplyr::arrange(desc(n_cpd))
```

**Python**

```python
import pandas as pd

df = pd.read_csv("biorempp_database_v1.1.0.csv", sep=";", dtype=str)
print(df.shape)          # (123543, 11)
print(df["cpd"].nunique())  # 384

# Compounds per class
df.groupby("compoundclass")["cpd"].nunique().sort_values(ascending=False)
```

When analyzing the database, always use distinct-compound aggregations (`n_distinct(cpd)` in R, `nunique()` in Python) rather than row counts for compound-level statistics.

## Boundary With Internal Fields

Intermediate generation steps produce staging fields during KEGG link assembly and classification. Those fields are not part of the public schema and do not appear in the 11-column export contract.

## Related Pages

- [Database Statistics](statistics.md)
- [Curated Inputs](curated-inputs.md)
- [Configuration And IO Contracts](../pipeline-architecture/configuration-and-io.md)
- [Configuration Reference](../validation-gx/configuration.md)
- [Glossary](../reference/glossary.md)
