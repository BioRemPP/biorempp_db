<!--
Page status: verified
Audience: researchers, operators, maintainers, reviewers
Applies to: Snakemake
Version scope: repository contract v1.1.0
Last verified on: 2026-06-26
Primary sources:
- biorempp_snakemake_version/config/config.yaml
- biorempp_validation/pyproject.toml
- mkdocs.yml
- biorempp_snakemake_version/results/metadata/kegg_release.json
-->

# Data Availability and Citation

## How To Access

### Database Files

The current release exports are:

- `biorempp_database_v1.1.0.csv` — semicolon-delimited, UTF-8, quoted fields
- `biorempp_database_v1.1.0.xlsx` — Excel format

Both files are located at `biorempp_snakemake_version/results/database/` within the repository. The schema for both files is documented in [Schema](../database-reference/schema.md).

### Repository

The full repository, including source code, curated inputs, pipeline configuration, and generated outputs, is available at:

```
https://github.com/BioRemPP/biorempp_db
```

### Documentation

The official documentation is hosted at:

```
https://biorempp-database.readthedocs.io
```

## License

The database content is released under Creative Commons Attribution 4.0 International (CC BY 4.0). The pipeline source code is released under Apache License 2.0. The documentation is released under CC BY 4.0. License texts are included in the repository root `LICENSE` file.

## Persistent Identifier

A persistent DOI via Zenodo is pending deposit for the current release. Until the DOI is assigned, the current release should be cited using the repository URL and the release version `v1.1.0`.

## How To Cite

When citing BioRemPP v1.1.0 in a publication:

```
BioRemPP Development Team. BioRemPP Database v1.1.0: a reproducible bioremediation
knowledge resource. GitHub. https://github.com/BioRemPP/biorempp_db (2026).
```

When reporting analytical results derived from the database, include the KEGG release used during generation:

```
Results were obtained using BioRemPP v1.1.0, generated from KEGG Release 118.0+
(retrieved 2026-05-18).
```

The KEGG release version is recorded in `results/metadata/kegg_release.json` for every pipeline run.

## Version Information

| Release | Schema columns | Total entries | KEGG reference | Retrieved |
|---|---|---|---|---|
| v1.0.0 | 8 | 10,871 | Release Dec,23 | December 2025 |
| v1.1.0 | 11 | 123,543 | Release 118.0+ | May 2026 |

## Related Pages

- [FAIR Compliance](fair-compliance.md)
- [Database Statistics](../database-reference/statistics.md)
- [Provenance and Release Semantics](../database-reference/provenance-and-release.md)
