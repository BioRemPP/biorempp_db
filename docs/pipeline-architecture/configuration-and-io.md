<!--
Page status: verified
Audience: maintainers, reviewers, advanced operators
Applies to: Snakemake
Version scope: Snakemake output contract v1.1.0
Last verified on: 2026-06-24
Primary sources:
- biorempp_snakemake_version/config/config.yaml
- biorempp_snakemake_version/workflow/lib/io_contracts.R
- biorempp_snakemake_version/workflow/lib/utils.R
- biorempp_snakemake_version/Snakefile
- biorempp_snakemake_version/workflow/rules/30_validation.smk
- biorempp_snakemake_version/workflow/scripts/generation/01_load_local_data.R
- biorempp_snakemake_version/workflow/scripts/generation/03_fetch_kegg_data.R
- biorempp_snakemake_version/workflow/scripts/generation/07_extract_enzymes_export.R
-->

# Configuration And IO Contracts

This page documents the files and keys that define the Snakemake workflow contract. In this repository, reproducibility depends on explicit filenames, directory boundaries, column order, and KEGG identifier rules.

## Contract Ownership

The pipeline contract is not owned by a single file.

| Source | Owns |
|---|---|
| `config/config.yaml` | runtime values such as version, paths, database filenames, CSV formatting, KEGG base URL, analysis cutoffs, and validation thresholds |
| `workflow/lib/io_contracts.R` | required curated input filenames, exported database schema, KEGG endpoint definitions for generation, and identifier patterns |
| `workflow/lib/utils.R` | shared NA handling plus CSV and JSON I/O behavior |
| `workflow/rules/30_validation.smk` | fixed validation cache location `cache/kegg_link_cache/` |

## Runtime Configuration File

The active runtime configuration is `biorempp_snakemake_version/config/config.yaml`.

Its top-level sections are:

| Section | Current role |
|---|---|
| `version` | release identifier injected into the workflow and reporting layer |
| `paths` | input, results, work, and logs locations |
| `outputs` | database filenames and CSV formatting |
| `kegg` | base URL, info endpoint, and validation-layer link endpoints |
| `analysis` | top-N cutoffs for summary scripts |
| `validation` | threshold settings for integrated validation |

## Path Contract

The current path settings are:

| Key | Current value | Meaning |
|---|---|---|
| `paths.input_dir` | `../input_data` | curated input root, resolved from `biorempp_snakemake_version/` |
| `paths.results_dir` | `results` | public release artifacts |
| `paths.work_dir` | `work` | intermediate serialized bundles and preflight marker |
| `paths.logs_dir` | `logs` | per-rule execution logs |

One additional path is fixed outside `config.yaml`:

| Location | Defined in | Role |
|---|---|---|
| `cache/kegg_link_cache/` | `workflow/rules/30_validation.smk` | persisted KEGG link cache for integrated validation |

This means curated inputs stay at repository level, while execution products remain local to the pipeline implementation directory.

## Curated Input Contract

`workflow/lib/io_contracts.R` defines `REQUIRED_INPUT_FILES`. The active curated input contract is:

- `kegglistcompounds.xlsx`
- `curated_regulated_compounds.xlsx`
- `curated_programatic_missing_compounds.xlsx`
- `curated_compound_classes.xlsx`
- `kegglistko.txt`
- `curated_enzyem_names_extracted.txt`

These filenames are enforced by `preflight_check_inputs` and then consumed by `01_load_local_data.R`.

## Public Output Contract

Only the database export filenames are configurable. The current configured values are:

| Key | Current value |
|---|---|
| `outputs.database_csv` | `biorempp_database_v1.1.0.csv` |
| `outputs.database_xlsx` | `biorempp_database_v1.1.0.xlsx` |
| `outputs.database_csv_delimiter` | `;` |
| `outputs.database_csv_quote` | `true` |

The rest of the public release surface is fixed by `Snakefile` and the rule modules:

- `results/analysis/basic_statistics.json`
- `results/analysis/compound_statistics.json`
- `results/analysis/ko_statistics.json`
- `results/analysis/enzyme_statistics.json`
- `results/analysis/gene_statistics.json`
- `results/analysis/crosstab_statistics.json`
- `results/analysis/database_metadata.json`
- `results/analysis/executive_summary.json`
- `results/analysis/complete_analysis.json`
- `results/metadata/kegg_release.json`
- `results/metadata/keys_consistency_report.json`
- `results/metadata/links_groundtruth_policy_report.json`
- `results/reports/workflow_summary.json`

## Public Database Schema Contract

`workflow/lib/io_contracts.R` defines `EXPECTED_DATABASE_COLUMNS`, and `07_extract_enzymes_export.R` uses that vector to write the final export. The verified public column order is:

1. `cpd`
2. `compoundclass`
3. `ko`
4. `ec`
5. `reaction`
6. `reaction_description`
7. `referenceAG`
8. `compoundname`
9. `genesymbol`
10. `genename`
11. `enzyme_activity`

This is the public database contract. Internal staging fields used in intermediate transformations are not part of the exported schema.

## KEGG Contract Split

The KEGG contract is explicit but currently split across layers.

| Concern | Source of truth | Consumed by |
|---|---|---|
| Base URL | `config/config.yaml` `kegg.base_url` | generation and validation |
| Release info endpoint | `config/config.yaml` `kegg.info_endpoint` | `fetch_kegg_info` |
| Generation endpoint definitions and expected column orientation | `workflow/lib/io_contracts.R` `KEGG_ENDPOINTS` | `03_fetch_kegg_data.R` |
| Validation link endpoints | `config/config.yaml` `kegg.endpoints.*` | `fetch_kegg_link_cache` and downstream validation rules |

The generation layer does not read `kegg.endpoints.*` from `config.yaml`. It reads endpoint definitions directly from `workflow/lib/io_contracts.R`.

The compound list endpoint used by the generation layer is defined in `workflow/lib/io_contracts.R`. The `kegg.endpoints.*` keys in `config.yaml` apply exclusively to the validation layer.

## Value Normalization Contract

`workflow/lib/io_contracts.R` defines the identifier patterns for:

- `cpd`
- `ko`
- `ec`
- `reaction`

`workflow/lib/utils.R` complements those patterns with:

- shared NA-like token normalization
- consistent CSV reading and writing
- shared JSON writing behavior

Together, these files define how identifiers and missing values are interpreted before they enter the public outputs.

## Analysis And Validation Settings

Two runtime sections directly influence downstream behavior:

- `analysis.top_n_compounds`, `analysis.top_n_ko`, and `analysis.top_n_enzymes`
- `validation.max_invalid_line_ratio`

The first group controls ranked summaries in `workflow/scripts/analysis/`. The second is passed by `30_validation.smk` into both integrated validation scripts.

## Why These Contracts Matter

The workflow remains auditable because its contracts are explicit:

- curated inputs fail fast at preflight time
- exported columns are centralized in one contract object
- database filenames and CSV formatting propagate consistently across export, analysis, validation, and reporting
- KEGG-dependent logic can be traced back to named endpoints and normalization rules
