# Glossary

This glossary provides concise definitions of key technical, biological, and data-model terms used throughout the BioRemPP Database documentation.

---

## A

**Agency Code**  
Standardized acronym identifying an environmental regulatory agency that has classified a compound as a priority pollutant or contaminant of concern. BioRemPP uses 9 agency codes: `ATSDR`, `EPA`, `IARC1`, `IARC2A`, `IARC2B`, `PSL`, `EPC`, `WFD`, `CONAMA`.

**Annotation**  
Process of assigning functional or biological information to a gene, protein, or compound. In BioRemPP, annotation refers to linking compounds to genes via KEGG Orthology IDs and enzyme activities.

---

## B

**Biodegradation**  
Biological process by which microorganisms or enzymes break down organic compounds into simpler substances. BioRemPP focuses on genes and enzymes involved in biodegradation of environmental pollutants.

**Bioremediation**  
Use of biological systems (microorganisms, enzymes, plants) to remove or neutralize environmental contaminants. BioRemPP provides functional annotations to support bioremediation research.

---

## C

**Chemical Class**  
Categorical classification of compounds based on structural features. BioRemPP uses 12 standardized classes: Aromatic, Chlorinated, Nitrogen-containing, Polyaromatic, Aliphatic, Metal, Inorganic, Sulfur-containing, Organophosphorus, Organometallic, Halogenated, Organosulfur.

**Compound**  
Chemical entity represented in BioRemPP by a KEGG Compound ID. Compounds are environmental pollutants, xenobiotics, or metabolites relevant to biodegradation.

**Compound ID** (cpd)  
KEGG Compound identifier in the format `C#####` (e.g., `C06790` for trichloroethene). Primary identifier for chemical entities in BioRemPP.

**Controlled Vocabulary**  
Standardized set of terms used consistently throughout a database. BioRemPP uses controlled vocabularies for agency codes, chemical classes, and enzyme activities.

**Curation**  
Manual review and validation of data by domain experts. BioRemPP includes curated compound-KO relationships, chemical classifications, and enzyme lexicon.

---

## D

**Deduplication**  
Process of removing redundant or duplicate entries from a dataset. BioRemPP deduplicates compound-KO pairs and KEGG reference data.

**Deterministic**  
Property of a computational process that produces identical outputs when given identical inputs. BioRemPP pipeline is deterministic (no random or stochastic components).

---

## E

**EC Number**  
Enzyme Commission number; hierarchical classification system for enzymes based on chemical reactions catalyzed. BioRemPP uses EC numbers to link compounds and genes via KEGG.

**Enzyme Activity**  
Standardized term describing the catalytic function of an enzyme. BioRemPP extracts enzyme activities from KEGG gene names using a 210-term lexicon (e.g., `cytochrome P450`, `dioxygenase`).

**Environmental Agency**  
International or national regulatory organization that classifies environmental pollutants. BioRemPP integrates compound lists from 9 agencies.

---

## F

**FAIR Principles**  
Data management guidelines ensuring data are Findable, Accessible, Interoperable, and Reusable. BioRemPP is designed for FAIR compliance.

**Feature Engineering**  
Process of transforming raw data into structured features for analysis. BioRemPP performs feature engineering on KEGG gene names to extract standardized enzyme activities.

---

## G

**Gene**  
Functional unit of heredity; in BioRemPP, represented by KEGG Orthology IDs (organism-independent gene groups).

**Gene Name**  
Functional description of a gene's role (e.g., `cytochrome P450 family 1 subfamily A member 1`). BioRemPP uses KEGG gene names.

**Gene Symbol**  
Short alphanumeric identifier for a gene (e.g., `CYP1A1`, `nahA`). BioRemPP uses KEGG gene symbols.

---

## I

**Identifier**  
Unique code used to reference a specific entity in a database. BioRemPP uses KEGG Compound IDs, KEGG Orthology IDs, and agency codes as primary identifiers.

**Interoperability**  
Ability of different systems or datasets to exchange and use information. BioRemPP achieves interoperability through standardized KEGG identifiers.

---

## K

**KEGG**  
Kyoto Encyclopedia of Genes and Genomes; comprehensive database of biological systems integrating genomic, chemical, and functional information. Primary data source for BioRemPP.

**KEGG API**  
RESTful web service providing programmatic access to KEGG data. BioRemPP queries KEGG API for compound-gene relationships.

**KEGG Compound**  
Chemical entity in KEGG database with identifier format `C#####`. BioRemPP uses KEGG Compound IDs as primary compound identifiers.

**KEGG Orthology** (KO)  
Functional gene group representing orthologous genes across organisms. KO IDs (format `K#####`) are organism-independent and serve as primary gene identifiers in BioRemPP.

**KO ID** (ko)  
KEGG Orthology identifier in the format `K#####` (e.g., `K07408` for cytochrome P450). Primary identifier for genes in BioRemPP.

---

## M

**Metadata**  
Data describing other data; includes information about data sources, versions, formats, and provenance. BioRemPP provides comprehensive metadata for reproducibility.

**Multi-Omics**  
Integration of multiple types of biological data (genomics, transcriptomics, proteomics, metabolomics). BioRemPP enables multi-omics integration through shared identifiers.

---

## N

**Normalization**  
Process of standardizing data to a consistent format. BioRemPP normalizes KEGG identifiers, gene symbols, and compound names.

---

## O

**Orthology**  
Evolutionary relationship between genes in different species that evolved from a common ancestral gene. KEGG Orthology groups orthologous genes.

---

## P

**Pathway**  
Series of biochemical reactions catalyzed by enzymes. BioRemPP provides compound-gene relationships that can be mapped to KEGG pathways.

**Pollutant**  
Substance that contaminates the environment and may cause harm. BioRemPP focuses on priority pollutants classified by environmental agencies.

**Provenance**  
Record of the origin, history, and processing of data. BioRemPP documents provenance for all data sources and transformations.

---

## R

**Reference Database**  
External database used as a source of standardized identifiers or annotations. KEGG serves as the primary reference database for BioRemPP.

**Reproducibility**  
Ability to obtain identical results when repeating a computational analysis. BioRemPP pipeline is designed for bit-for-bit reproducibility.

---

## S

**Sanitization**  
Process of cleaning and standardizing data to remove errors or inconsistencies. BioRemPP sanitizes KEGG identifiers to canonical format (e.g., `K#####`).

**Schema**  
Formal specification of database structure, including column names, data types, and constraints. BioRemPP schema defines 8 columns with controlled vocabularies.

**Snapshot**  
Static copy of a database at a specific point in time. BioRemPP uses KEGG snapshots (Dec,25) to ensure reproducibility.

---

## T

**Tidy Data**  
Data structure where each variable is a column, each observation is a row, and each type of observational unit is a table. BioRemPP outputs are in tidy format.

**Traceability**  
Ability to track the origin and transformations of data. BioRemPP ensures traceability through version control and provenance documentation.

---

## V

**Validation**  
Process of verifying data quality and consistency. BioRemPP performs identifier format validation, cross-reference validation, and completeness checks.

**Version Control**  
System for tracking changes to files over time. BioRemPP uses Git for version control of code and data.

**Vocabulary**  
See Controlled Vocabulary.

---

## X

**Xenobiotic**  
Chemical compound foreign to a biological system. Many environmental pollutants in BioRemPP are xenobiotics.

---

## Questions?

**GitHub Repository:** [https://github.com/BioRemPP/biorempp_db](https://github.com/BioRemPP/biorempp_db)  
**Email:** biorempp@gmail.com
