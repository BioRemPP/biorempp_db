<!--
Page status: verified
Audience: researchers, reviewers
Applies to: Snakemake and GX
Version scope: repository contract v1.1.0
Last verified on: 2026-06-26
Primary sources:
- biorempp_snakemake_version/config/config.yaml
- biorempp_validation/pyproject.toml
- mkdocs.yml
- biorempp_snakemake_version/results/metadata/kegg_release.json
- biorempp_snakemake_version/results/reports/workflow_summary.json
-->

# FAIR Compliance

BioRemPP v1.1.0 is designed to satisfy the FAIR data principles — Findable, Accessible, Interoperable, and Reusable — as they apply to a reproducible bioinformatics database resource. This page maps each principle to the concrete implementation elements present in the current release.

## F — Findable

### F1. Data are assigned globally unique and persistent identifiers

Each release is identified by a version-scoped filename embedded in the database exports:

- `biorempp_database_v1.1.0.csv`
- `biorempp_database_v1.1.0.xlsx`

The repository is publicly accessible at `https://github.com/BioRemPP/biorempp_db`. A persistent DOI via Zenodo is pending deposit and will be assigned to the current release on archive submission.

Individual database rows carry KEGG Compound identifiers (`C#####`) and KEGG Orthology identifiers (`K#####`), both globally unique and persistently maintained by Kanehisa Laboratories.

### F2. Data are described with rich metadata

Each pipeline run generates structured metadata artifacts that describe the release:

- `results/metadata/kegg_release.json` records the KEGG release version and retrieval timestamp
- `results/analysis/database_metadata.json` records database-level provenance
- `results/reports/workflow_summary.json` records pipeline version, artifact SHA256 hashes, and run-level context
- `biorempp_validation/results/validation_summary.json` records the validation outcome for the release

### F3. Metadata clearly include the identifier of the data they describe

The version identifier `1.1.0` appears consistently in:

- database export filenames (`biorempp_database_v1.1.0.csv`)
- `config/config.yaml` under `version`
- `biorempp_validation/pyproject.toml` under `version`
- `mkdocs.yml` under `extra.version.default`
- the regression baseline directory name `release_v1_1_0_kegg_118_0plus`

### F4. Metadata are registered in a searchable resource

The repository is indexed by GitHub search and accessible through the public documentation site at `https://biorempp-database.readthedocs.io`. Registration in FAIRsharing.org is planned following DOI assignment.

## A — Accessible

### A1. Data are retrievable by their identifier using a standardized protocol

The database files and full source code are accessible via HTTPS through the public GitHub repository. No authentication is required for read access. The documentation site is independently accessible at its ReadTheDocs URL.

### A1.1. The protocol is open, free, and universally implementable

HTTPS is the retrieval protocol. It is an open, royalty-free standard defined by RFC 9110 and supported by all current programming environments and data access tools.

### A2. Metadata are accessible even when data are no longer available

Repository metadata in `README.md`, `mkdocs.yml`, and `pyproject.toml` persists independently of the database binary files. Following Zenodo deposit, the DOI metadata record will remain accessible even if the dataset is withdrawn from the archive.

## I — Interoperable

### I1. Data use a broadly applicable knowledge representation

The database is distributed in two standard formats:

- CSV with delimiter `;` and UTF-8 encoding, conforming to RFC 4180
- Excel XLSX conforming to ISO/IEC 29500

Analysis artifacts use JSON conforming to RFC 8259. All formats are readable by standard tooling in R, Python, and Excel without proprietary software requirements.

### I2. Data use vocabularies that follow FAIR principles

Every entity in the database is grounded in KEGG-controlled vocabularies:

- compound identifiers follow the `C#####` pattern maintained by the KEGG Compound database
- orthology identifiers follow the `K#####` pattern maintained by the KEGG Orthology database
- reaction identifiers follow the `R#####` pattern maintained by the KEGG Reaction database
- EC numbers follow the four-field hierarchical format maintained by the IUBMB Enzyme Commission

These vocabularies carry persistent identifiers and are independently resolvable. Controlled values for `referenceAG` and `compoundclass` are defined in `biorempp_validation/config/validation.yaml` and enforced by the GX validation layer.

### I3. Data include qualified references to other data

Each row carries resolvable KEGG identifiers. A compound identified as `C00014` resolves to `https://www.kegg.jp/entry/C00014`. An orthology group identified as `K11819` resolves to `https://www.kegg.jp/entry/K11819`. These references allow downstream tools to retrieve additional biological context directly from KEGG without intermediate lookup tables.

## R — Reusable

### R1. Data are released with a clear and accessible usage license

The database content is released under Creative Commons Attribution 4.0 International (CC BY 4.0). The pipeline source code is released under Apache License 2.0. Both licenses permit commercial use, redistribution, and modification with attribution. License texts are included in the repository root.

### R1.1. Data are released with clear data usage licenses

License terms are stated in the repository root `LICENSE` file and referenced in the documentation. Machine-readable SPDX identifiers are used where applicable.

### R1.2. Data are associated with detailed provenance

The pipeline records provenance at three levels:

- source provenance: `results/metadata/kegg_release.json` identifies the KEGG release version and retrieval timestamp
- processing provenance: `results/reports/workflow_summary.json` records pipeline version, configuration, and SHA256 hashes for all major outputs
- validation provenance: `biorempp_validation/results/validation_summary.json` and the regression baseline at `baselines/release_v1_1_0_kegg_118_0plus` document what was validated and against what reference snapshot

### R1.3. Data meet domain-relevant community standards

The database uses KEGG identifiers, which are the de facto standard for functional annotation of microbial genomes. EC numbers follow the international enzyme classification maintained by the IUBMB. File formats conform to published open standards. Documentation follows the MkDocs Material framework with semantic versioning.

## FAIR Assessment Summary

| Principle | Implementation element | Status |
|---|---|---|
| F1 | Version-scoped filenames; KEGG persistent identifiers per row | Implemented |
| F1 | DOI via Zenodo | Pending deposit |
| F2 | kegg_release.json, workflow_summary.json, database_metadata.json | Implemented |
| F3 | Version identifier in config, package, mkdocs, baseline, filenames | Implemented |
| F4 | GitHub indexing; ReadTheDocs | Implemented |
| F4 | FAIRsharing registration | Planned |
| A1 | HTTPS access; public GitHub; ReadTheDocs | Implemented |
| A1.1 | HTTPS — open, free, universal (RFC 9110) | Implemented |
| A2 | Repository metadata; Zenodo DOI metadata persistence | Partially implemented |
| I1 | CSV (RFC 4180), XLSX (ISO/IEC 29500), JSON (RFC 8259) | Implemented |
| I2 | KEGG Compound, Orthology, Reaction vocabularies; EC numbers | Implemented |
| I3 | Resolvable KEGG identifiers per row | Implemented |
| R1 | CC BY 4.0 (data); Apache 2.0 (code) | Implemented |
| R1.1 | LICENSE file; SPDX identifiers | Implemented |
| R1.2 | kegg_release.json; workflow_summary.json (SHA256); baseline manifest | Implemented |
| R1.3 | KEGG identifiers; EC numbers; open file formats | Implemented |

## Related Pages

- [Data Availability and Citation](availability.md)
- [Provenance and Release Semantics](../database-reference/provenance-and-release.md)
- [Data Validation (GX) Architecture](../validation-gx/architecture.md)
