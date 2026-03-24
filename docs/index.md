# BioRemPP Database v1.0.0

**A FAIR-compliant resource integrating KEGG orthology, environmental agencies, and curated biodegradation data for bioremediation research**

---

## What is the BioRemPP Database?

The **BioRemPP Database** (Bioremediation Potential Profile Database) is a curated, integrated resource designed to support environmental bioremediation research by systematically linking chemical compounds, genes, enzymes, and regulatory frameworks. The database addresses a critical gap in bioremediation science: the absence of a unified, standardized resource that connects pollutant compounds with their potential biodegradation pathways across multiple knowledge bases and regulatory contexts.

Environmental contamination by xenobiotic compounds—ranging from chlorinated solvents and polyaromatic hydrocarbons to pesticides and heavy metals—poses significant ecological and public health challenges. While substantial knowledge exists regarding microbial biodegradation capabilities, this information remains fragmented across disparate databases (KEGG, specialized biodegradation repositories), scattered literature, and disconnected regulatory frameworks (EPA, IARC, ATSDR, etc.). Researchers seeking to assess bioremediation potential for a specific contaminant or microbial community face significant barriers: manual cross-referencing of multiple databases, inconsistent identifier systems, incomplete pathway annotations, and lack of integrated regulatory context.

BioRemPP Database v1.0.0 systematically integrates data from **KEGG** (Kyoto Encyclopedia of Genes and Genomes), **nine international environmental regulatory references**, and **manual curations** into a unified, FAIR-compliant (Findable, Accessible, Interoperable, Reusable) framework. The current release contains **10,871 database entries** linking **384 unique chemical compounds** to **1,542 KEGG Orthology (KO) identifiers**, **1,516 gene symbols**, and **205 enzyme activity types** across **12 chemical compound classes**, achieving **100% data completeness** across all core fields.

The database generation pipeline is fully reproducible and transparent, implemented as a **Snakemake workflow** with 18 rules organized into four layers: preflight validation, data generation (ETL from local files and KEGG API), statistical analysis, and provenance reporting. The pipeline is fully containerized via Docker (based on `rocker/tidyverse:4.3`) with pinned dependencies (Snakemake 7.32.4, R packages, Python packages) to ensure bit-for-bit reproducibility. All data sources, transformation steps, and quality control measures are explicitly documented, and every output artifact receives a SHA-256 checksum for integrity verification.

---

## Scope and Purpose

### Scientific Problem Addressed

**Challenge**: Bioremediation research requires integration of diverse data types—chemical compound properties, genetic functional annotations, enzymatic activities, toxicity classifications, and regulatory designations—that exist across fragmented databases with incompatible identifier systems and varying levels of curation.

**Solution**: BioRemPP Database provides a pre-integrated, standardized resource that:

1. **Unifies identifier systems** across KEGG compounds (C#####), KEGG Orthology (K#####), gene symbols, and environmental agency codes
2. **Integrates regulatory context** by linking compounds to their classification across nine international environmental agencies
3. **Provides functional annotations** connecting compounds to genes and specific enzyme activities involved in biodegradation
4. **Ensures data quality** through systematic validation, consistency checks, and 100% field completeness
5. **Enables reproducibility** via transparent data provenance and a fully documented generation pipeline
6. **Facilitates interoperability** through FAIR principles compliance and standard file formats (CSV, JSON)

### Core Use Cases

The database is designed to support:

- **Comparative genomics and metagenomics**: Annotating microbial genomes or metagenome-assembled genomes (MAGs) with biodegradation functional potential
- **Environmental risk assessment**: Cross-referencing contaminants of concern across multiple regulatory frameworks
- **Pathway reconstruction**: Identifying gene sets required for complete biodegradation pathways for specific pollutants
- **Multi-omics integration**: Linking genomic potential (KO annotations) with transcriptomic expression or metabolomic profiles
- **Bioaugmentation design**: Selecting microbial strains or consortia based on functional capacity for target compounds
- **Regulatory compliance**: Mapping detected genes to compounds listed by EPA, ATSDR, IARC, and other agencies
- **Metabolic engineering**: Identifying enzyme candidates for synthetic biodegradation pathway construction

---

## Intended Audience

This resource is designed for:

- **Environmental microbiologists** studying microbial biodegradation mechanisms and metabolic pathways
- **Bioinformaticians** analyzing metagenomic, metatranscriptomic, or genomic datasets for functional annotation
- **Environmental engineers** designing or optimizing bioremediation strategies for contaminated sites
- **Computational biologists** developing metabolic models or pathway prediction tools
- **Regulatory scientists** assessing environmental pollutant coverage in microbial functional databases
- **Database developers** building specialized biodegradation or environmental databases
- **Multi-omics researchers** integrating genomic, transcriptomic, proteomic, or metabolomic data layers

**Prerequisites**: Users should have basic familiarity with:

- **Bioinformatics concepts**: KEGG identifiers (KO, Compound IDs), functional annotation, gene-pathway relationships
- **Environmental science**: Xenobiotic compounds, biodegradation, regulatory frameworks (EPA, IARC, etc.)
- **Data analysis tools**: R or Python for data manipulation, or spreadsheet software for exploratory analysis
- **Scientific computing**: Command-line usage, file formats (CSV, JSON), version control (Git)

---

## Out-of-Scope Use Cases

BioRemPP Database is **not** designed for:

### What This Resource Does NOT Provide

1. **Metabolic pathway reconstruction from scratch**  
   The database provides gene-compound relationships but does not infer complete metabolic pathways from genomic data. Users requiring pathway inference should integrate BioRemPP with tools like KEGG Mapper, MetaCyc, or pathway prediction algorithms.

2. **Compound toxicity predictions**  
   While the database links compounds to regulatory classifications (IARC carcinogenicity groups, EPA priority pollutants), it does not predict toxicity for novel compounds. Toxicity prediction requires specialized tools (e.g., QSAR models, toxicogenomics databases).

3. **Quantitative biodegradation kinetics**  
   The database indicates *potential* biodegradation capacity (presence of genes/enzymes) but does not provide kinetic parameters (e.g., degradation rates, Michaelis-Menten constants, biodegradation half-lives). Kinetic data must be obtained from experimental studies or specialized kinetics databases.

4. **Organism-specific biodegradation capabilities**  
   BioRemPP uses KEGG Orthology (functional groups abstracted across organisms) rather than organism-specific gene sequences. Mapping to specific organisms requires additional annotation steps (e.g., using KEGG Organism databases, BLAST against reference genomes).

5. **Real-time KEGG synchronization**  
   The database represents a snapshot of KEGG data at the time of generation, Release 116.0+/12-16, Dec 25 . While the pipeline can be re-run to update data, this release (v1.0.0) is a static resource and does not automatically synchronize with KEGG updates.

6. **Proprietary or unpublished degradation pathways**  
   The database integrates publicly available data sources (KEGG, regulatory agency lists, literature-based curations). Proprietary biodegradation data or unpublished experimental results are not included.

7. **Regulatory compliance certification**  
   While the database provides regulatory context (EPA, ATSDR, IARC classifications), it is not a legal compliance tool and should not be used as the sole basis for regulatory risk assessments without consulting official agency guidelines.

### When to Use Alternative Resources

- **For pathway visualization and detailed metabolic maps**: Use KEGG Mapper, BioCyc, or Reactome
- **For toxicity prediction and QSAR modeling**: Use ToxCast, CompTox Dashboard, or VEGA QSAR
- **For organism-specific metabolism**: Use organism-specific KEGG databases or ModelSEED
- **For biodegradation kinetics**: Consult specialized databases like EAWAG-BBD (UM-BBD) or experimental literature
- **For metagenome functional annotation pipelines**: Integrate BioRemPP with HUMAnN3, PICRUSt2, or DRAM
- **For enzyme structure and mechanism**: Use PDB, BRENDA, or UniProt

---

## How to Navigate This Documentation

This documentation is organized into **eight major sections** to serve different user needs:

### For New Users

1. **[Getting Started](getting-started/installation.md)** — Installation guide, system requirements, and quick start tutorial
2. **[User Guide](user-guide/overview.md)** — Step-by-step instructions for running the database generation pipeline and interpreting outputs

### For Researchers Evaluating the Database

3. **[Database Reference](database/schema.md)** — Schema documentation, field descriptions, statistics, and data quality metrics
4. **[Validation & QC](validation/qc-rules.md)** — Quality control rules, benchmarking results, known limitations, and reproducibility protocols

### For Developers and Integrators

5. **[Pipeline Architecture](technical/pipeline-architecture.md)** — Snakemake workflow architecture, DAG, rule modules, configuration, and containerization
6. **[Interoperability](interoperability/r-python-integration.md)** — Integration examples for R, Python, and multi-omics workflows

### For Reference

7. **[Reference Materials](reference/glossary.md)** — Glossary of terms, data source descriptions, environmental agencies, and enzyme nomenclature
8. **[About](about/how-to-cite.md)** — Citation guidelines, changelog, license, contributing guidelines, and future roadmap

### Quick Navigation by Task

| **Task** | **Recommended Starting Point** |
|----------|-------------------------------|
| Install and run the pipeline | [Installation Guide](getting-started/installation.md) |
| Understand database structure | [Database Schema](database/schema.md) |
| Load data into R or Python | [R and Python Integration](interoperability/r-python-integration.md) |
| Evaluate data quality | [Data Quality Metrics](database/data-quality.md) |
| Assess reproducibility | [Reproducibility Protocols](validation/reproducibility.md) |
| Understand FAIR compliance | [FAIR Compliance](database/fair-compliance.md) |
| Cite the resource | [How to Cite](about/how-to-cite.md) |
| Report issues or contribute | [Contributing Guidelines](about/contributing.md) |

---

## Citation

If you use BioRemPP Database v1.0.0 in your research, please cite:

> **BioRemPP Database v1.0.0: A FAIR-compliant resource for bioremediation research integrating KEGG orthology, environmental agencies, and curated biodegradation data**  
> Douglas Felipe, et al. (2025)  
> GitHub: [https://github.com/BioRemPP/biorempp_db](https://github.com/BioRemPP/biorempp_db)

A peer-reviewed publication is in preparation. This citation format will be updated with DOI and journal reference upon publication. For detailed citation formats (BibTeX, RIS, EndNote), see [How to Cite](about/how-to-cite.md).

---

## Contact and Support

**GitHub Repository**: [https://github.com/BioRemPP/biorempp_db](https://github.com/BioRemPP/biorempp_db)  
**Bug Reports and Feature Requests**: [GitHub Issues](https://github.com/BioRemPP/biorempp_db/issues)  
**Email**: biorempp@gmail.com

---

## License

BioRemPP Database content is distributed under **Creative Commons Attribution 4.0 International (CC BY 4.0)**.  
Database generation pipeline and scripts are distributed under **Apache License 2.0**.

See [License](about/license.md) for full terms.

---

<div align="center">

**BioRemPP Database v1.0.0** | December 2025

*Empowering bioremediation research through integrated, FAIR-compliant biodegradation data*

[GitHub](https://github.com/BioRemPP/biorempp_db) · [License](about/license.md) · [How to Cite](about/how-to-cite.md)

</div>
