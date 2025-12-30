# Changelog

This document records all notable changes to the BioRemPP Database and generation pipeline across versions.

---

## Changelog Overview

This changelog follows [Semantic Versioning](https://semver.org/) principles:

- **MAJOR** version (X.0.0): Incompatible schema changes or major data source updates
- **MINOR** version (0.X.0): Backward-compatible functionality additions or data updates
- **PATCH** version (0.0.X): Backward-compatible bug fixes or documentation updates

**Format:** Each version entry includes release date, summary of changes, and impact on reproducibility or reuse.

**Change categories:**

- **Added:** New features, data sources, or documentation
- **Changed:** Modifications to existing features or data
- **Deprecated:** Features or data marked for removal in future versions
- **Removed:** Features or data removed from the database
- **Fixed:** Bug fixes or data corrections
- **Security:** Security-related changes

---

## Version History

### [1.0.0] - 2025-12-16

**Release date:** December 16, 2025

**Type:** Initial release

#### Added

**Data sources:**

- KEGG Compound (10,869 entries, Release Dec,25)
- KEGG Orthology (47,421 entries, Release Dec,25)
- Environmental agency compound lists (806 associations, 9 agencies)
- Manual compound-KO curations (62 relationships)
- Compound chemical classifications (384 compounds, 12 classes)
- Enzyme activity lexicon (210 terms)

**Database content:**

- 384 unique compounds from environmental agencies
- 1,541 unique KO entries
- 10,869 total database entries
- 12 standardized chemical classes
- 210 enzyme activity terms

**Schema:**

- 8-column schema: `cpd`, `compoundclass`, `ko`, `referenceAG`, `compoundname`, `genesymbol`, `genename`, `enzyme_activity`
- CSV format (primary): RFC 4180 compliant, UTF-8 encoding
- Excel format (alternative): Office Open XML (ISO/IEC 29500)

**Pipeline features:**

- Deterministic data processing (no stochastic components)
- KEGG API integration with error handling
- Identifier sanitization and normalization
- Deduplication of compound-KO pairs
- Feature engineering for enzyme activity extraction

**Documentation:**

- Comprehensive MkDocs-based documentation
- FAIR compliance documentation
- Data quality and validation documentation
- Reproducibility guidelines
- Interoperability documentation (R, Python, multi-omics)

#### Changed

N/A (initial release)

#### Deprecated

N/A (initial release)

#### Removed

N/A (initial release)

#### Fixed

N/A (initial release)

#### Security

N/A (initial release)

**Impact on reproducibility:**

- Bit-for-bit reproducible when using same KEGG reference files
- KEGG API queries may vary if KEGG database updates between executions
- Recommended to use local KEGG snapshots for exact reproduction

**Backward compatibility:** N/A (initial release)

---

## Planned Future Versions

**Planned changes:**

- Update to latest KEGG release
- Addition of new environmental agency compound lists
- Expansion of manual curations based on recent literature

**Impact on reproducibility:**

- KEGG version update will change compound-gene relationships
- New curations will add entries but not modify existing ones
- Backward compatible with v1.0.0 schema

**Backward compatibility:** Full backward compatibility maintained

---

### Future

**Potential changes (not committed):**

- Schema modifications 
- Integration of additional data sources 
- Organism-specific gene annotations
- Pathway completeness validation

**Impact on reproducibility:**

- Schema changes will require data migration
- Not backward compatible with v1.0.0

**Backward compatibility:** Breaking changes expected

---

## Version-Specific Notes

### v1.0.0 Notes

**KEGG dependency:**

- Database content reflects KEGG Release Dec,25
- KEGG API queries performed in December 2025
- Future KEGG updates will not affect v1.0.0 outputs

**Data completeness:**

- 100% field completeness (zero missing values)
- All compounds have at least one chemical class
- All KO entries have gene symbols and gene names

**Known limitations:**

- No organism-specific annotations (KO IDs are organism-independent)
- No pathway completeness validation
- No quantitative biodegradation data (kinetics, rates)
- Enzyme activities extracted via pattern matching (210-term lexicon)

---

## How to Report Issues

**For data errors or inconsistencies:**

- Open a GitHub Issue: [https://github.com/BioRemPP/biorempp_db/issues](https://github.com/BioRemPP/biorempp_db/issues)
- Label: `data-quality`

**For documentation errors:**

- Open a GitHub Issue: [https://github.com/BioRemPP/biorempp_db/issues](https://github.com/BioRemPP/biorempp_db/issues)
- Label: `documentation`

**For feature requests:**

- Open a GitHub Issue: [https://github.com/BioRemPP/biorempp_db/issues](https://github.com/BioRemPP/biorempp_db/issues)
- Label: `enhancement`

---

## Changelog Maintenance

This changelog is updated with each release. Changes are documented:

- **Before release:** Planned changes listed under "Planned Future Versions"
- **At release:** Version entry created with release date and finalized changes
- **After release:** No retroactive modifications to version entries

**Changelog format:** Follows [Keep a Changelog](https://keepachangelog.com/) principles.

---

## Questions?

**GitHub Repository:** [https://github.com/BioRemPP/biorempp_db](https://github.com/BioRemPP/biorempp_db)  
**Email:** biorempp@gmail.com
