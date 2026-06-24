<!--
Page status: verified
Audience: researchers, operators, maintainers, reviewers
Applies to: Snakemake and GX
Version scope: Snakemake output contract v1.1.0 and GX validator v1.1.0
Last verified on: 2026-06-24
Primary sources:
- biorempp_snakemake_version/config/config.yaml
- biorempp_snakemake_version/workflow/scripts/generation/02_fetch_kegg_info.R
- biorempp_snakemake_version/workflow/scripts/analysis/07_metadata.R
- biorempp_snakemake_version/workflow/scripts/reporting/build_run_report.py
- biorempp_snakemake_version/results/metadata/kegg_release.json
- biorempp_snakemake_version/results/analysis/database_metadata.json
- biorempp_snakemake_version/results/reports/workflow_summary.json
- biorempp_validation/config/validation.yaml
- biorempp_validation/src/biorempp_validation/run_validation.py
- biorempp_validation/baselines/release_v1_1_0_kegg_118_0plus
-->

# Provenance And Release Semantics

BioRemPP release provenance is captured in data artifacts, not only in filenames. The active pipeline records both source provenance from KEGG and build provenance for the generated release outputs.

## Release Identity

The current release line is driven by `biorempp_snakemake_version/config/config.yaml`:

- `version: "1.1.0"`
- `outputs.database_csv: biorempp_database_v1.1.0.csv`
- `outputs.database_xlsx: biorempp_database_v1.1.0.xlsx`

That version value is reused by the analysis and reporting layers, so the release contract is propagated into multiple JSON artifacts rather than being implied only by the output filename.

## KEGG Source Provenance

The pipeline writes KEGG release metadata to `results/metadata/kegg_release.json`.

The current artifact contains:

| Field | Meaning |
|---|---|
| `release_text` | release line extracted from the KEGG info response |
| `parsed_version` | parsed version token derived from that response |
| `retrieved_at_utc` | UTC timestamp for retrieval |
| `source_url` | effective URL used for the request |
| `raw_response` | full response lines returned by the endpoint |

This file is produced from `info/kegg` and is the repository's primary machine-readable record of the KEGG state used during generation.

## Database-Level Provenance

`results/analysis/database_metadata.json` adds provenance inside the analysis layer. Its top-level sections are:

- `database_info`
- `data_sources`
- `schema`
- `data_quality`
- `link_match`

These sections capture:

- the database name, version, and generation date
- the embedded KEGG release payload
- a schema description aligned with the public export
- per-column completeness
- link-match and support interpretation for the exported rows

This artifact is where schema, quality, and source interpretation meet in one place.

## Workflow-Level Release Summary

The most audit-oriented release artifact is `results/reports/workflow_summary.json`.

Its top-level sections are:

- `pipeline`
- `kegg_reference`
- `keys_consistency`
- `links_groundtruth_policy`
- `reaction_description_coverage`
- `link_match`
- `artifacts`

The `artifacts` block records `path`, `size_bytes`, and `sha256` for the current release files:

- `database_csv`
- `database_xlsx`
- `database_metadata_json`
- `complete_analysis_json`
- `kegg_release_json`
- `keys_consistency_json`
- `links_groundtruth_policy_json`

This makes `workflow_summary.json` the best single artifact for release review when file integrity and source provenance both matter.

## Release Semantics In Practice

For the active Snakemake pipeline, a release is defined by both:

- the repository-side version marker such as `1.1.0`
- the captured KEGG release context in `kegg_release.json`

Two runs that share the same output filename pattern but point to different KEGG releases are not identical from a provenance standpoint.

## Relationship To The GX Baseline

GX regression detection compares the current results tree against a committed baseline configured in `biorempp_validation/config/validation.yaml`:

- current results root: `../biorempp_snakemake_version/results`
- baseline root: `baselines/release_v1_1_0_kegg_118_0plus`

The current shipped baseline contains:

- the nine `analysis/*.json` artifacts
- `metadata/kegg_release.json`

The baseline does not include:

- `database/*.csv`
- `metadata/keys_consistency_report.json`
- `metadata/links_groundtruth_policy_report.json`
- `reports/workflow_summary.json`

That boundary is deliberate in the current validator implementation. Regression detection is anchored to analysis artifacts plus KEGG release metadata, while the pipeline-only validation reports remain part of the current-run contract.

## Why This Matters For Consumers

If you need to cite or compare a BioRemPP release, preserve at minimum:

1. the versioned database file
2. `results/metadata/kegg_release.json`
3. `results/analysis/database_metadata.json`
4. `results/reports/workflow_summary.json`

Those four artifacts together describe what was built, from which KEGG state, and with which file-level integrity markers.

## Related Pages

- [Analysis Artifacts](analysis-artifacts.md)
- [Changelog And Releases](../about/changelog-and-releases.md)
- [Baseline Management](../validation-gx/baseline-management.md)
