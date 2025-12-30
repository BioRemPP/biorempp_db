# Database Statistics

This document provides quantitative characteristics of the BioRemPP Database v1.0.0.

---

## Scope of Reported Statistics

All statistics reported in this document are:

- **Reproducible** — Derived from automated analysis scripts (`analysis/analyze_database.R`)
- **Version-specific** — Correspond to BioRemPP Database v1.0.0 (December 2025)
- **Verifiable** — Source data available in JSON format (`analysis/output/*.json`)
- **Objective** — Descriptive counts and distributions without biological interpretation

**Data source:** BioRemPP Database v1.0.0 (`biorempp_database_v1.0.0.csv`)

**Analysis date:** December 2025

**KEGG reference:** Release Dec,23

---

## Overall Database Size and Composition

### Core Metrics

| Metric | Value | Description |
|--------|-------|-------------|
| **Total entries** | 10,869 | Complete compound-gene-enzyme-agency relationships |
| **Total columns** | 8 | Schema fields (cpd, compoundclass, ko, referenceAG, compoundname, genesymbol, genename, enzyme_activity) |
| **Unique compounds** | 384 | Distinct chemical compounds (KEGG Compound IDs) |
| **Unique KO entries** | 1,541 | Distinct KEGG Orthology functional groups |
| **Unique gene symbols** | 1,515 | Distinct gene nomenclature identifiers |
| **Unique gene names** | 1,420 | Distinct functional gene descriptions |
| **Unique enzyme activities** | 205 | Distinct enzyme activity classifications |
| **Unique compound classes** | 12 | Chemical structural classifications |
| **Unique reference agencies** | 9 | Environmental regulatory authorities |

### Data Completeness

**100% field completeness** — Zero missing values across all 8 columns

| Column | Missing Values | Completeness |
|--------|----------------|--------------|
| `cpd` | 0 | 100% |
| `compoundclass` | 0 | 100% |
| `ko` | 0 | 100% |
| `referenceAG` | 0 | 100% |
| `compoundname` | 0 | 100% |
| `genesymbol` | 0 | 100% |
| `genename` | 0 | 100% |
| `enzyme_activity` | 0 | 100% |

---

## Distribution of Compounds

### Compounds by Chemical Class

**Total classes:** 12

| Rank | Class | Compounds | Percentage | Description |
|------|-------|-----------|------------|-------------|
| 1 | Aromatic | 123 | 32.0% | Benzene ring-containing compounds |
| 2 | Chlorinated | 117 | 30.5% | Halogenated with chlorine |
| 3 | Nitrogen-containing | 115 | 29.9% | Nitrogen functional groups |
| 4 | Polyaromatic | 98 | 25.5% | Multiple fused aromatic rings (PAHs) |
| 5 | Aliphatic | 94 | 24.5% | Straight-chain or branched hydrocarbons |
| 6 | Metal | 29 | 7.6% | Metal-containing compounds |
| 7 | Inorganic | 26 | 6.8% | Inorganic compounds |
| 8 | Sulfur-containing | 20 | 5.2% | Sulfur functional groups |
| 9 | Organophosphorus | 13 | 3.4% | Phosphorus-containing organic compounds |
| 10 | Organometallic | 9 | 2.3% | Metal-carbon bonds |
| 11 | Halogenated | 8 | 2.1% | Halogenated compounds (general) |
| 12 | Organosulfur | 1 | 0.3% | Organic sulfur compounds |

**Note:** Percentages sum to >100% because compounds may belong to multiple classes.

**Class distribution summary:**

- **Minimum compounds per class:** 1 (Organosulfur)
- **Maximum compounds per class:** 123 (Aromatic)
- **Mean compounds per class:** 54.4
- **Median compounds per class:** 27.5

---

### Compounds by Environmental Agency

**Total agencies:** 9

| Rank | Agency | Compounds | Percentage | Jurisdiction |
|------|--------|-----------|------------|--------------|
| 1 | ATSDR | 191 | 49.7% | USA (Public health hazards) |
| 2 | IARC2B | 130 | 33.9% | International (Possibly carcinogenic) |
| 3 | PSL | 99 | 25.8% | Canada (Priority substances) |
| 4 | EPC | 91 | 23.7% | Europe (Priority chemicals) |
| 5 | WFD | 84 | 21.9% | EU (Water quality) |
| 6 | EPA | 83 | 21.6% | USA (Priority pollutants) |
| 7 | IARC1 | 56 | 14.6% | International (Carcinogenic to humans) |
| 8 | CONAMA | 43 | 11.2% | Brazil (Environmental regulations) |
| 9 | IARC2A | 29 | 7.6% | International (Probably carcinogenic) |

**Note:** Percentages calculated as (compounds in agency / total unique compounds). Compounds may appear in multiple agencies.

---

### Top 20 Most Represented Compounds

Compounds with highest number of associated gene-enzyme relationships:

| Rank | Compound ID | Compound Name | Entries | Unique KO | Unique Enzymes |
|------|-------------|---------------|---------|-----------|----------------|
| 1 | C00014 | Ammonia | 666 | 37 | 18 |
| 2 | C06790 | Trichloroethene | 564 | 37 | 15 |
| 3 | C00067 | Formaldehyde | 381 | 28 | 13 |
| 4 | C18428 | Diuron | 369 | 36 | 9 |
| 5 | C14343 | Trifluralin | 297 | 36 | 9 |
| 6 | C07535 | Benzo[a]pyrene | 231 | 36 | 9 |
| 7 | C00829 | Naphthalene | 210 | 36 | 11 |
| 8 | C14322 | Chlorpyrifos | 186 | 36 | 9 |
| 9 | C00090 | Catechol | 180 | 24 | 11 |
| 10 | C00084 | Acetaldehyde | 177 | 28 | 13 |
| 11 | C06604 | Parathion | 168 | 36 | 9 |
| 12 | C14219 | 2-Chlorophenol | 150 | 36 | 9 |
| 13 | C14430 | Dichlorvos | 138 | 36 | 9 |
| 14 | C16444 | Benzidine | 128 | 36 | 9 |
| 15 | C10984 | Cypermethrin | 126 | 36 | 9 |
| 16 | C11042 | Hexachlorobenzene | 126 | 36 | 9 |
| 17 | C11146 | Methylmercury chloride | 120 | 36 | 9 |
| 18 | C19425 | Fluoranthene | 116 | 36 | 9 |
| 19 | C11090 | Endosulfan | 112 | 36 | 9 |
| 20 | C15233 | Cadmium chloride | 108 | 36 | 9 |

**Interpretation:** Ammonia and Trichloroethene exhibit the highest functional diversity, associated with 37 distinct KO groups each.

---

## Distribution of Genes and KO Entries

### KO Entry Statistics

**Total unique KO entries:** 1,541

**Frequency distribution:**

- **Minimum frequency:** 1 entry
- **Maximum frequency:** 104 entries (K14579)
- **Mean frequency:** 7.1 entries per KO
- **Median frequency:** 3 entries per KO

**Compounds per KO:**

- **Minimum compounds:** 1 compound per KO
- **Maximum compounds:** 27 compounds per KO (K14579)
- **Mean compounds:** 2.2 compounds per KO
- **Median compounds:** 1 compound per KO

---

### Top 20 Most Frequent KO Entries

| Rank | KO ID | Entries | Unique Compounds | Gene Symbol Example |
|------|-------|---------|------------------|---------------------|
| 1 | K14579 | 104 | 27 | CYP1A1 |
| 2 | K14580 | 98 | 26 | CYP1A2 |
| 3 | K07408 | 86 | 24 | CYP2A6 |
| 4 | K07409 | 86 | 24 | CYP2B6 |
| 5 | K07410 | 86 | 24 | CYP2C8 |
| 6 | K07411 | 86 | 24 | CYP2C9 |
| 7 | K07412 | 86 | 24 | CYP2C18 |
| 8 | K07413 | 86 | 24 | CYP2C19 |
| 9 | K07414 | 86 | 24 | CYP2D6 |
| 10 | K07418 | 86 | 24 | CYP2E1 |
| 11 | K07420 | 86 | 24 | CYP2F1 |
| 12 | K07424 | 86 | 24 | CYP2J2 |
| 13 | K01563 | 85 | 17 | nahAc |
| 14 | K00490 | 83 | 23 | CYP11A1 |
| 15 | K07426 | 83 | 23 | CYP3A4 |
| 16 | K07428 | 83 | 23 | CYP3A5 |
| 17 | K07429 | 83 | 23 | CYP3A7 |
| 18 | K21647 | 81 | 14 | CYP4F2 |
| 19 | K14578 | 74 | 17 | CYP1B1 |
| 20 | K14581 | 68 | 16 | CYP2A13 |

**Observation:** Cytochrome P450 family dominates top KO entries, reflecting broad substrate specificity in xenobiotic metabolism.

---

### Gene Symbol Statistics

**Total unique gene symbols:** 1,515

**Distribution characteristics:**

- Gene symbols are quasi-unique (some KO groups share symbols for isoforms)
- 1,420 unique gene names (functional descriptions)
- Gene symbols follow standard nomenclature (HUGO for human genes, organism-specific for microbial genes)

---

## Distribution of Enzymes

### Enzyme Activity Statistics

**Total unique enzyme activities:** 205

**Frequency distribution:**

- **Minimum frequency:** 1 entry
- **Maximum frequency:** 2,166 entries (cytochrome P450)
- **Mean frequency:** 53.0 entries per enzyme
- **Median frequency:** 8 entries per enzyme

---

### Top 30 Enzyme Families

| Rank | Enzyme Activity | Entries | Unique Compounds | Unique KO | Percentage |
|------|----------------|---------|------------------|-----------|------------|
| 1 | cytochrome P450 | 2,166 | 35 | 36 | 19.9% |
| 2 | dioxygenase | 1,093 | 88 | 74 | 10.1% |
| 3 | monooxygenase | 872 | 74 | 83 | 8.0% |
| 4 | dehydrogenase | 822 | 106 | 165 | 7.6% |
| 5 | reductase | 438 | 53 | 91 | 4.0% |
| 6 | S-transferase | 314 | 13 | 7 | 2.9% |
| 7 | synthase | 273 | 33 | 102 | 2.5% |
| 8 | dehalogenase | 238 | 31 | 5 | 2.2% |
| 9 | oxidase | 230 | 28 | 53 | 2.1% |
| 10 | isomerase | 203 | 18 | 16 | 1.9% |
| 11 | phosphatase | 192 | 10 | 43 | 1.8% |
| 12 | peroxidase | 163 | 30 | 9 | 1.5% |
| 13 | decarboxylase | 147 | 23 | 21 | 1.4% |
| 14 | lyase | 141 | 23 | 29 | 1.3% |
| 15 | ligase | 136 | 12 | 17 | 1.3% |
| 16 | carboxylesterase | 125 | 12 | 4 | 1.2% |
| 17 | hydrolase | 124 | 26 | 30 | 1.1% |
| 18 | demethylase | 122 | 6 | 28 | 1.1% |
| 19 | cyclase | 119 | 4 | 35 | 1.1% |
| 20 | kinase | 115 | 16 | 28 | 1.1% |
| 21 | receptor | 108 | 2 | 12 | 1.0% |
| 22 | sulfotransferase | 108 | 23 | 12 | 1.0% |
| 23 | ATP-binding | 98 | 13 | 5 | 0.9% |
| 24 | deaminase | 82 | 7 | 32 | 0.8% |
| 25 | hydroxylase | 79 | 13 | 13 | 0.7% |
| 26 | transferase | 71 | 16 | 6 | 0.7% |
| 27 | oxidoreductase | 60 | 2 | 37 | 0.6% |
| 28 | phospholipase | 58 | 4 | 14 | 0.5% |
| 29 | amidase | 57 | 8 | 11 | 0.5% |
| 30 | ADP-ribosyltransferase | 56 | 2 | 14 | 0.5% |

**Note:** Percentages calculated as (enzyme entries / total database entries).

**Key observations:**

- **Cytochrome P450** represents nearly 20% of all database entries
- **Top 5 enzyme families** account for 49.6% of total entries
- **Top 30 enzyme families** account for 79.4% of total entries
- **175 remaining enzyme families** account for 20.6% of entries (long-tail distribution)

---

## Coverage Across Data Sources

### Environmental Agency Coverage

**Total agencies represented:** 9

**Geographic distribution:**

- **North America:** 3 agencies (ATSDR, EPA, PSL)
- **Europe:** 2 agencies (EPC, WFD)
- **International:** 3 agencies (IARC1, IARC2A, IARC2B)
- **South America:** 1 agency (CONAMA)

**Regulatory focus distribution:**

- **Toxicity/Carcinogenicity:** 4 agencies (IARC1, IARC2A, IARC2B, ATSDR)
- **Environmental priority:** 3 agencies (EPA, PSL, EPC)
- **Water quality:** 1 agency (WFD)
- **National regulations:** 1 agency (CONAMA)

---

### Enzyme Activity Coverage

**Total enzyme activity terms:** 205

**Coverage by enzyme class:**

- **Oxidoreductases:** 68 terms (33.2%)
- **Transferases:** 42 terms (20.5%)
- **Hydrolases:** 38 terms (18.5%)
- **Lyases:** 24 terms (11.7%)
- **Isomerases:** 18 terms (8.8%)
- **Ligases:** 15 terms (7.3%)

**Note:** Classification based on EC number hierarchy where available.

---

## Version-Specific Statistics

### BioRemPP Database v1.0.0

**Release date:** December 2025

**KEGG reference:** Release Dec,23

**Key metrics:**

| Metric | v1.0.0 |
|--------|--------|
| Total entries | 10,869 |
| Unique compounds | 384 |
| Unique KO entries | 1,541 |
| Unique enzyme activities | 205 |
| Compound classes | 12 |
| Environmental agencies | 9 |
| Data completeness | 100% |

**Input data sources:**

- `kegglistcompounds.xlsx` — 10,869 KEGG compounds
- `kegglistko.txt` — 47,421 KO entries
- `compostos_todasagencias.xlsx` — 806 agency-classified compounds
- `missing_compounds_founds_curated.xlsx` — 62 manual curations
- `confirm_class_CURATED.xlsx` — 384 compound classifications
- `enzymes_unique.txt` — 210 enzyme terms

---

## Notes on Variability Across Releases

### Expected Changes in Future Versions

**Factors affecting database size:**

1. **KEGG updates** — New KO entries, compounds, and pathway annotations
2. **Agency list updates** — Addition/removal of priority pollutants
3. **Manual curations** — Literature-derived compound-gene relationships
4. **Enzyme lexicon expansion** — New enzyme activity terms

**Stability guarantees:**

- **Schema stability** — Column structure will remain stable in v1.x.x releases
- **Identifier consistency** — KEGG Compound and KO IDs are persistent
- **Backward compatibility** — New versions will be supersets (additions only, no deletions)

**Recommended update frequency:** Annually, or when major KEGG releases occur

---

### Reproducibility Notes

**All statistics are reproducible via:**

```r
# Load database
db <- read.csv("biorempp_database_v1.0.0.csv")

# Run analysis
source("analysis/analyze_database.R")

# Output: 9 JSON files in analysis/output/
```

**JSON output files:**

1. `basic_statistics.json` — Core counts and completeness
2. `compound_statistics.json` — Compound distributions
3. `ko_statistics.json` — KO entry distributions
4. `enzyme_statistics.json` — Enzyme activity distributions
5. `gene_statistics.json` — Gene symbol distributions
6. `crosstab_statistics.json` — Cross-dimensional analysis
7. `database_metadata.json` — Schema and provenance
8. `executive_summary.json` — High-level overview
9. `complete_analysis.json` — Consolidated analysis

---

## Questions?

**GitHub Issues:** [https://github.com/BioRemPP/biorempp_db/issues](https://github.com/BioRemPP/biorempp_db/issues)  
**Email:** biorempp@gmail.com
