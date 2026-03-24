# Roadmap

This document describes planned future directions for the BioRemPP Database and associated resources.

---

## Purpose of the Roadmap

This roadmap outlines **scientific intentions** for the BioRemPP project. Items listed represent planned work but are **not guarantees** of implementation or timelines. Actual development depends on funding, community contributions, and scientific priorities.

**Roadmap items are subject to change** based on:

- Scientific advances in bioremediation research
- Community feedback and requests
- Resource availability and funding
- Technical feasibility and validation

---

## Current Status (v1.0.0)

**Implemented:**

- BioRemPP Database v1.0.0 (384 compounds, 1,542 KO entries)
- KEGG-based functional annotations
- Environmental agency compound integration
- Manual curations and chemical classifications
- Comprehensive documentation (MkDocs)
- R and Python interoperability
- FAIR-compliant data release
- Snakemake 7.32.4 workflow with 18 rules (Preflight, Generation, Analysis, Reporting)
- Docker containerization (rocker/tidyverse:4.3)
- Automated analysis layer (9 JSON statistical reports)
- SHA-256 output checksums (workflow_summary.json)

**Implemented Web Service:**

A **web-based analytical platform** has been implemented to support hypothesis-driven bioremediation research:

- **56 use cases** — Structured analytical workflows based on defined scientific questions
- **19 visualization types** — Graphical outputs for bioremediation potential characterization
- **Sample types supported** — Plants, fungi, bacteria (individual or consortia)
- **Analytical scope** — Ortholog-based functional annotation (gene-centric, not molecular dynamics)

**Use case structure:**

Each use case follows a standardized format:

1. **Scientific question** — Defined research question
2. **Methodology** — Data processing and analysis steps
3. **Interpretation** — Suggested interpretation of results
4. **Reproducibility assumptions** — Stated limitations and dependencies

**Analytical capabilities:**

- **Bioremediation potential characterization** — Assess functional capacity of samples
- **Consortium optimization** — Identify complementary gene profiles for microbial consortia
- **Regulatory compliance** — Verify presence of genes for agency-listed priority pollutants
- **Scoring Metrics** — Quantify completeness of biodegradation pathways
- **Comparative analysis** — Compare bioremediation potential across samples

**Important limitations:**

- **Gene-centric analysis** — Based on ortholog annotations (KO IDs), not molecular dynamics
- **No enzymatic activity** — Does not reflect enzyme expression, regulation, or kinetics
- **No transcriptional dynamics** — Does not model gene expression or regulation
- **In silico only** — Computational predictions require experimental validation
- **Hypothesis-driven** — Designed to optimize hypotheses and guide experimental design

**Use case applications:**

- **Annotation intermediary** — Facilitate specific annotation of priority pollutant components
- **Sample comparison** — Identify functional differences between samples
- **Hypothesis optimization** — Refine research questions based on functional profiles

---

## Short-Term Planned Improvements (v1.1.0 - v1.2.0)

### Data Updates

**Planned:**

- Update to latest KEGG release (quarterly or biannual)
- Addition of new environmental agency compound lists
- Expansion of manual curations based on recent literature
- Integration of emerging contaminants (e.g., PFAS, microplastics)

**Impact:** Increased compound coverage and up-to-date functional annotations


---

### Documentation Improvements

**Planned:**

- Interactive examples using Jupyter notebooks or R Markdown
- Snakemake profile templates for HPC/cluster execution
- Expanded troubleshooting guide
- Community-contributed case studies

**Impact:** Improved accessibility for new users

---

## Medium-Term Scientific Directions (v2.0.0 - v3.0.0)

### Multi-Omics Integration

**Planned:**

Internal integration of multi-omics data within BioRemPP ecosystem:

- **Metagenomics** — Link gene abundance to bioremediation potential
- **Metatranscriptomics** — Integrate gene expression data
- **Metabolomics** — Connect compound detection to degradation genes
- **Proteomics** — Link protein abundance to enzyme activities

**Approach:**

- Develop standardized workflows for multi-omics data integration
- Provide identifier mapping tools (KEGG ↔ PubChem ↔ UniProt)
- Create multi-omics visualization use cases
- Maintain semantic interoperability through shared identifiers

**Important distinction:**

- BioRemPP will provide **identifier-level integration** and **analytical workflows**
- BioRemPP will **not** perform automated multi-omics data processing or statistical modeling
- Users will integrate their own omics data with BioRemPP annotations

**Impact:** Enable comprehensive functional characterization across omics layers

---

### Machine Learning Integration

**Potential applications:**

- Predict biodegradation pathways for novel compounds
- Identify candidate genes for uncharacterized pollutants
- Optimize microbial consortia using machine learning
- Predict enzyme promiscuity and substrate specificity

**Important caveat:** Machine learning predictions require extensive experimental validation

---

### Community-Driven Curation

**Potential features:**

- Community submission portal for new curations
- Peer review system for contributed data
- Automated literature mining for biodegradation relationships
- Integration with text mining tools (e.g., PubTator, Europe PMC)

**Impact:** Accelerate data growth through community contributions

---


## Constraints and Dependencies

### Funding and Resources

**Current status:** BioRemPP is maintained by a small team with limited resources.

**Dependency:** Implementation of roadmap items depends on:

- Availability of research funding
- Allocation of developer time
- Community contributions

**Impact:** Timelines are uncertain and subject to change.

---

### External Database Dependencies

**Current dependencies:**

- KEGG database (primary data source)
- Environmental agency compound lists

**Risks:**

- KEGG may change access policies or licensing
- Environmental agencies may reorganize or remove data
- External databases may be discontinued

**Mitigation:** Maintain local snapshots and explore alternative data sources.

---

### Technical Feasibility

**Challenges:**

- Organism-specific annotations require significant computational resources
- Quantitative data integration requires extensive data curation
- Machine learning requires large training datasets and validation

**Impact:** Some roadmap items may be deferred or modified based on feasibility.

---

### Scientific Validation

**Requirement:** All new features and data sources must undergo scientific validation.

**Process:**

- Literature review for new data sources
- Reproducibility testing for pipeline changes
- Community feedback for new features

**Impact:** Implementation may be slower than anticipated to ensure quality.

---

## Disclaimer Regarding Implementation Timelines

**No guaranteed timelines:**

- Roadmap items are **intentions**, not commitments
- Implementation depends on funding, resources, and priorities
- Timelines may change without notice

**Version numbering:**

- Version numbers (v1.1.0, v2.0.0, etc.) are **illustrative**, not scheduled releases
- Actual version numbers may differ based on implementation order

**Community input:**

- Roadmap is subject to community feedback
- Users can propose new features via GitHub Issues
- Priority may be adjusted based on community needs

**Transparency:**

- Progress on roadmap items will be documented in Changelog
- Major changes to roadmap will be announced via GitHub Discussions

---

## How to Influence the Roadmap

**Users can contribute to roadmap prioritization by:**

1. **Opening GitHub Issues** — Propose new features or data sources
2. **Participating in Discussions** — Provide feedback on planned features
3. **Contributing code or data** — Accelerate implementation through contributions
4. **Citing BioRemPP** — Demonstrate impact and support funding applications

**Maintainers will consider:**

- Scientific merit of proposed features
- Community demand and use cases
- Technical feasibility and resource requirements
- Alignment with project goals

---

## Questions About the Roadmap?

**GitHub Discussions:** [https://github.com/BioRemPP/biorempp_db/discussions](https://github.com/BioRemPP/biorempp_db/discussions)  
**GitHub Issues:** [https://github.com/BioRemPP/biorempp_db/issues](https://github.com/BioRemPP/biorempp_db/issues)  
**Email:** biorempp@gmail.com
