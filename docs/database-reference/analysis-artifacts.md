<!--
Page status: verified
Audience: researchers, operators, maintainers, reviewers
Applies to: Snakemake and GX
Version scope: Snakemake output contract v1.1.0 and GX validator v1.1.0
Last verified on: 2026-06-24
Primary sources:
- biorempp_snakemake_version/Snakefile
- biorempp_snakemake_version/config/config.yaml
- biorempp_snakemake_version/workflow/rules/20_analysis.smk
- biorempp_snakemake_version/workflow/scripts/analysis/01_basic_statistics.R
- biorempp_snakemake_version/workflow/scripts/analysis/02_compound_statistics.R
- biorempp_snakemake_version/workflow/scripts/analysis/03_ko_statistics.R
- biorempp_snakemake_version/workflow/scripts/analysis/04_enzyme_statistics.R
- biorempp_snakemake_version/workflow/scripts/analysis/05_gene_statistics.R
- biorempp_snakemake_version/workflow/scripts/analysis/06_crosstab_statistics.R
- biorempp_snakemake_version/workflow/scripts/analysis/07_metadata.R
- biorempp_snakemake_version/workflow/scripts/analysis/08_executive_summary.R
- biorempp_snakemake_version/workflow/scripts/analysis/09_merge_complete_analysis.R
- biorempp_snakemake_version/results/analysis/basic_statistics.json
- biorempp_snakemake_version/results/analysis/compound_statistics.json
- biorempp_snakemake_version/results/analysis/ko_statistics.json
- biorempp_snakemake_version/results/analysis/enzyme_statistics.json
- biorempp_snakemake_version/results/analysis/gene_statistics.json
- biorempp_snakemake_version/results/analysis/crosstab_statistics.json
- biorempp_snakemake_version/results/analysis/database_metadata.json
- biorempp_snakemake_version/results/analysis/executive_summary.json
- biorempp_snakemake_version/results/analysis/complete_analysis.json
- biorempp_validation/src/biorempp_validation/run_validation.py
-->

# Analysis Artifacts

The Snakemake workflow writes nine JSON artifacts under `results/analysis/`. These files are part of the public release contract and also feed the GX validator.

## Artifact Index

| File | Producer | Main contents | Downstream role |
|---|---|---|---|
| `basic_statistics.json` | rule `basic_statistics`, script `01_basic_statistics.R` | row count, column count, column names, uniqueness totals, per-column missing-value totals | structural summary and GX parity checks |
| `compound_statistics.json` | rule `compound_statistics`, script `02_compound_statistics.R` | class counts, agency counts, top compounds, class distribution summary | compound-centric interpretation and baseline comparison |
| `ko_statistics.json` | rule `ko_statistics`, script `03_ko_statistics.R` | KO frequencies and compound-per-KO summaries | KO-centric interpretation and baseline comparison |
| `enzyme_statistics.json` | rule `enzyme_statistics`, script `04_enzyme_statistics.R` | top enzyme labels and frequency summaries | enzyme-centric interpretation and baseline comparison |
| `gene_statistics.json` | rule `gene_statistics`, script `05_gene_statistics.R` | top gene symbols and gene names | gene-annotation summary and baseline comparison |
| `crosstab_statistics.json` | rule `crosstab_statistics`, script `06_crosstab_statistics.R` | top class-agency, enzyme-class, and class-KO diversity combinations | cross-dimensional summaries and baseline comparison |
| `database_metadata.json` | rule `database_metadata`, script `07_metadata.R` | database identity, source summary, embedded schema, completeness, and KEGG link-match interpretation | structural provenance artifact and GX parity source |
| `executive_summary.json` | rule `executive_summary`, script `08_executive_summary.R` | overview, highlights, and coverage sections | compact human-facing summary derived from other analysis artifacts |
| `complete_analysis.json` | rule `complete_analysis`, script `09_merge_complete_analysis.R` | bundle of the eight analysis artifacts above | single-file downstream snapshot and regression baseline input |

## What Each Artifact Measures

The analysis layer is intentionally split by question rather than by data source.

### Structural artifact

`basic_statistics.json` describes the exported table as a table:

- how many rows and columns exist
- which columns are present
- how many unique values exist in core dimensions
- how many missing values remain in each column

### Dimension-specific artifacts

The next four files summarize one dimension at a time:

- compounds
- KO identifiers
- enzyme labels
- gene annotations

These artifacts are where the configurable ranking cutoffs from `config/config.yaml` appear. With the current shipped config, the ranking payloads are keyed as:

- `top_20_compounds`
- `top_20_ko`
- `top_30_enzymes`

### Cross-dimensional artifact

`crosstab_statistics.json` captures combinations rather than single dimensions. In the current implementation, it contains:

- top 20 class-agency combinations
- top 20 enzyme-class combinations
- top 10 classes by KO diversity

### Metadata-rich artifact

`database_metadata.json` is part of `results/analysis/`, not `results/metadata/`. It packages:

- `database_info`
- `data_sources`
- `schema`
- `data_quality`
- `link_match`

This makes it the analysis artifact with the strongest provenance content.

### Synthesis artifacts

`executive_summary.json` condenses selected values from the earlier analysis files into three blocks:

- `overview`
- `highlights`
- `coverage`

`complete_analysis.json` then stores a merged snapshot of the whole analysis layer:

- `metadata`
- `basic_stats`
- `compound_stats`
- `ko_stats`
- `enzyme_stats`
- `gene_stats`
- `crosstab_stats`
- `executive_summary`

## Boundary With Other Output Families

These files should not be confused with:

- `results/metadata/`, which holds KEGG release tracking and integrated validation reports
- `results/reports/workflow_summary.json`, which is the release-level summary built after analysis and validation

`database_metadata.json` sounds similar to `results/metadata/`, but it belongs to the analysis layer and is produced by `20_analysis.smk`.

## How GX Uses These Artifacts

The GX validator consumes the analysis layer in two ways:

- `internal_consistency` compares the current CSV against the current `results/analysis/` artifacts
- `regression_detection` compares the current CSV against the committed baseline copy of those analysis artifacts

This is why the analysis JSONs are first-class release artifacts rather than optional reporting extras.

## Related Pages

- [Understanding Outputs](../user-guide/understanding-output.md)
- [Provenance And Release Semantics](provenance-and-release.md)
- [Validation Modes](../validation-gx/validation-modes.md)
