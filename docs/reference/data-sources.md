# Data Sources

This document provides a comprehensive reference of all data sources used in the BioRemPP Database v1.0.0.

---

## Purpose of Data Source Documentation

This reference documents the **provenance, scope, and role** of all data sources integrated into BioRemPP Database. It ensures:

- **Transparency** — Clear attribution of data origins
- **Reproducibility** — Version-specific source identification
- **Traceability** — Ability to verify data lineage
- **Sustainability** — Understanding of data update dependencies

---

## External Data Sources

### KEGG (Kyoto Encyclopedia of Genes and Genomes)

**Description:** Comprehensive database of biological systems, integrating genomic, chemical, and systemic functional information.

**Provider:** Kanehisa Laboratories, Kyoto University

**URL:** [https://www.kegg.jp/](https://www.kegg.jp/)

**Role in BioRemPP:**

- Primary source of compound identifiers (`cpd`)
- Primary source of gene orthology identifiers (`ko`)
- Source of compound names
- Source of gene symbols and functional descriptions
- Source of compound-gene relationships via EC numbers and reactions

**Version/Access date:** KEGG Release Dec,25 (December 2025)

**Specific resources used:**

| Resource | Endpoint/File | Rows | Purpose |
|----------|---------------|------|---------|
| KEGG Compound | `https://rest.kegg.jp/list/cpd/` | 10,869 | Compound IDs and names |
| KEGG Orthology | `https://rest.kegg.jp/list/ko/` | 47,421 | KO IDs, gene symbols, gene names |
| KO-EC links | `https://rest.kegg.jp/link/ko/ec` | Variable | Compound-gene relationships |
| KO-Reaction links | `https://rest.kegg.jp/link/ko/reaction` | Variable | Compound-gene relationships |
| Compound-EC links | `https://rest.kegg.jp/link/compound/ec` | Variable | Compound-gene relationships |
| Compound-Reaction links | `https://rest.kegg.jp/link/cpd/reaction` | Variable | Compound-gene relationships |

**License:** KEGG data is freely available for academic use; commercial use requires license.

**Citation:**
> Kanehisa M, Goto S. KEGG: Kyoto Encyclopedia of Genes and Genomes. Nucleic Acids Res. 2000;28(1):27-30.

---

### Environmental Regulatory Agencies

**Description:** International and national agencies that classify environmental pollutants and contaminants of concern.

**Role in BioRemPP:** Source of priority pollutant lists; defines compound scope and regulatory relevance.

**Number of agencies:** 9

**Agencies included:**

1. **ATSDR** — Agency for Toxic Substances and Disease Registry (USA)
2. **EPA** — Environmental Protection Agency (USA)
3. **IARC Group 1** — International Agency for Research on Cancer (Carcinogenic to humans)
4. **IARC Group 2A** — International Agency for Research on Cancer (Probably carcinogenic to humans)
5. **IARC Group 2B** — International Agency for Research on Cancer (Possibly carcinogenic to humans)
6. **PSL** — Priority Substances List (Canada)
7. **EPC** — European Priority Contaminants (EU)
8. **WFD** — Water Framework Directive (EU)
9. **CONAMA** — National Environment Council (Brazil)

**Data format:** Manually curated compound lists with KEGG Compound ID mappings.

**Total compounds:** 806 compound-agency associations (representing 384 unique compounds after KEGG matching).

**Access date:** December 2025 (agency lists compiled from official sources).

**Limitations:**

- Agency lists reflect regulatory priorities at time of compilation
- Not all agency-listed compounds have KEGG Compound IDs
- Lists may become outdated as agencies update priorities

**See also:** [Environmental Agencies Reference](environmental-agencies.md) for detailed agency descriptions.

---

## Curated and Manually Assembled Sources

### Manual Compound-KO Curations

**File:** `missing_compounds_founds_curated.xlsx`

**Description:** Manually curated of missing compound-KO relationships.

**Scope:** Compounds identified by environmental agencies but lacking automated KEGG linkage.

**Number of entries:** 62 compound-KO relationships

**Curation methodology:**

- Identification of genes/enzymes responsible for degradation
- Mapping to KEGG Orthology IDs

**Rationale for inclusion:** Fills gaps in automated KEGG API queries; captures known biodegradation relationships not represented in KEGG pathway maps.

**Curation date:** December 2025

**Limitations:**


- Curation reflects knowledge available at time of compilation

---

### Compound Chemical Classifications

**File:** `confirm_class_CURATED.xlsx`

**Description:** Expert-curated chemical classifications for environmental pollutants.

**Scope:** All 384 compounds in BioRemPP Database.

**Classification system:** 12 standardized chemical classes based on structural features.

**Classes:**

1. Aromatic
2. Chlorinated
3. Nitrogen-containing
4. Polyaromatic
5. Aliphatic
6. Metal
7. Inorganic
8. Sulfur-containing
9. Organophosphorus
10. Organometallic
11. Halogenated
12. Organosulfur

**Curation methodology:**

- Manual inspection of chemical structures
- Assignment of one or more classes per compound

**Rationale for inclusion:** Enables filtering and analysis by chemical class; supports structure-activity relationship studies.

**Curation date:** December 2025

**Limitations:**

- No hierarchical classification (e.g., Polyaromatic is not explicitly a subset of Aromatic)
- Emerging chemical classes (e.g., nanomaterials) not represented

---

### Enzyme Activity Lexicon

**File:** `enzymes_unique.txt`

**Description:** Curated lexicon of standardized enzyme activity terms for feature engineering from KEGG gene annotations.

**Scope:** 210 unique enzyme terms.

**Source:** Feature engineering from KEGG gene functional descriptions (accessible via KEGG API).

**Examples:** `cytochrome P450`, `dioxygenase`, `monooxygenase`, `dehydrogenase`, `reductase`, `dehalogenase`

**Curation methodology:**

- Extraction of enzyme activity terms from KEGG gene functional descriptions
- Standardization and deduplication of enzyme nomenclature
- Pattern matching for consistent enzyme activity annotation

**Rationale for inclusion:** Enables extraction of standardized enzyme activities from KEGG gene names; supports enzyme-centric analysis. Original KEGG gene descriptions can be verified via KEGG API calls.

**Curation date:** December 2025

**Limitations:**

- Lexicon may not cover all biodegradation enzymes
- Novel enzyme activities may be missed
- No mapping to EC numbers or Gene Ontology terms

**Traceability:** Original enzyme terms are derived from KEGG gene annotations and can be verified via:
```
https://rest.kegg.jp/get/[KO_ID]
```

---

## Data Source Limitations and Dependencies

### Temporal Dependency on KEGG

**Issue:** KEGG database is updated quarterly; BioRemPP uses a static snapshot.

**Impact:**

- Database content reflects KEGG state as of Dec,25
- Newer KEGG entries (compounds, KO, pathways) not included
- Deprecated KEGG entries may be present

**Mitigation:** Document KEGG release version; recommend periodic database regeneration.

---

### Agency List Currency

**Issue:** Environmental agency lists are updated irregularly.

**Impact:**

- Emerging contaminants may not be included
- Regulatory priorities may shift over time
- Geographic bias toward well-represented regions

**Mitigation:** Document agency list access date; recommend periodic review of agency updates.

---

### Manual Curation Scalability

**Issue:** Manual curations are time-intensive and not scalable.

**Impact:**

- Limited coverage of literature-derived relationships
- Potential for human error
- Difficult to maintain with rapid literature growth

**Mitigation:** Document curation provenance; recommend community contributions via GitHub.

---

### External Database Availability

**Issue:** BioRemPP depends on external databases (KEGG) that may change access policies.

**Impact:**

- KEGG API may introduce rate limits or authentication
- KEGG may retire or restructure databases
- Commercial use of KEGG data requires licensing

**Mitigation:** Use local snapshots of KEGG reference files; document KEGG license requirements.

---

## Notes on Data Updates and Sustainability

### Recommended Update Frequency

| Data Source | Update Frequency | Rationale |
|-------------|------------------|-----------|
| **KEGG** | Annually | KEGG releases quarterly; annual updates balance currency and stability |
| **Agency lists** | Biennially | Agency lists update irregularly; biennial review captures major changes |
| **Manual curations** | Ongoing | Literature-derived curations added as discovered |
| **Enzyme lexicon** | As needed | Lexicon is relatively stable; updates only when new enzyme families emerge |

---

### Data Update Procedure

1. **Download latest KEGG reference files**
   - `kegglistcompounds.xlsx` (KEGG Compound list)
   - `kegglistko.txt` (KEGG Orthology list)

2. **Review agency lists for updates**
   - Check EPA, IARC, EU, and other agency websites
   - Update `compostos_todasagencias.xlsx` with new compounds

3. **Add new manual curations**
   - Review recent biodegradation literature
   - Add new compound-KO relationships to `missing_compounds_founds_curated.xlsx`

4. **Re-generate database**
   - Run `generate_database.R` script
   - Validate output statistics

5. **Document changes**
   - Update `CHANGELOG.md` with version-specific changes
   - Update KEGG release version in documentation

---

### Data Sustainability Considerations

**Long-term sustainability depends on:**

- **KEGG availability** — KEGG is a well-established resource but requires ongoing funding
- **Agency list accessibility** — Agency websites may reorganize or remove historical lists
- **Community contributions** — Manual curations benefit from community input
- **Version control** — Git ensures historical data is preserved

**Recommendations:**

- Archive KEGG reference files in long-term repository (e.g., Zenodo)
- Document agency list sources with URLs and access dates
- Encourage community contributions via GitHub Issues and Pull Requests
- Maintain version control for all curated files

---

## Data Source Summary Table

| Source | Type | Rows/Entries | Version/Date | Role |
|--------|------|--------------|--------------|------|
| **KEGG Compound** | External DB | 10,869 | Dec,25 | Compound IDs, names |
| **KEGG Orthology** | External DB | 47,421 | Dec,25 | KO IDs, gene symbols, names |
| **KEGG API** | External API | Variable | Dec,25 | Compound-gene relationships |
| **Environmental Agencies** | Curated lists | 806 | Dec 2025 | Priority pollutant scope |
| **Manual curations** | Literature-derived | 62 | Dec 2025 | Gap-filling compound-KO links |
| **Compound classes** | Expert curation | 384 | Dec 2025 | Chemical classifications |
| **Enzyme lexicon** | Literature review | 210 | Dec 2025 | Enzyme activity extraction |

---

## Questions?

**GitHub Repository:** [https://github.com/BioRemPP/biorempp_db](https://github.com/BioRemPP/biorempp_db)  
**Email:** biorempp@gmail.com
