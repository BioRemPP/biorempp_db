# Multi-Omics Integration

This document describes how BioRemPP Database identifiers enable interoperability with multi-omics datasets.

---

## Rationale for Multi-Omics Interoperability

**BioRemPP provides identifier-level interoperability rather than an integrated multi-omics analysis framework.**

The database is designed to act as a **functional annotation layer** that can be linked to external omics datasets through standardized biological identifiers. This enables researchers to:

- **Connect metabolomics data** to biodegradation genes via compound identifiers
- **Annotate metagenomics data** with bioremediation potential via KO identifiers
- **Link transcriptomics data** to enzyme activities via gene symbols
- **Integrate proteomics data** with functional pathways via enzyme classifications

**Key principle:** BioRemPP does **not** perform multi-omics integration internally. Instead, it provides **persistent identifiers** that serve as semantic bridges between omics layers.

---

## Core BioRemPP Identifiers and Their Biological Meaning

### Compound Layer (`cpd`)

**Identifier:** KEGG Compound ID (e.g., `C06790` for trichloroethene)

**Biological meaning:**
- Represents a chemical entity (pollutant, metabolite, xenobiotic)
- Links to chemical structure, properties, and regulatory status

**Omics relevance:**
- **Metabolomics:** Direct match to detected metabolites
- **Exposomics:** Link to environmental contaminants
- **Cheminformatics:** Structure-based similarity searches

---

### Gene Layer (`ko`)

**Identifier:** KEGG Orthology ID (e.g., `K07408` for cytochrome P450)

**Biological meaning:**

- Represents a functional gene group (orthologous genes across organisms)
- Links to enzymatic function, pathway membership, and gene regulation

**Omics relevance:**

- **Metagenomics:** Functional annotation of assembled genes
- **Metatranscriptomics:** Expression of biodegradation genes
- **Comparative genomics:** Presence/absence of bioremediation genes

---

### Enzyme Layer (`enzyme_activity`)

**Identifier:** Standardized enzyme term (e.g., `cytochrome P450`, `dioxygenase`)

**Biological meaning:**

- Represents enzymatic activity or functional class
- Links to biochemical reactions and catalytic mechanisms

**Omics relevance:**

- **Proteomics:** Protein abundance of biodegradation enzymes
- **Enzymology:** Kinetic characterization of purified enzymes
- **Systems biology:** Enzyme-centric pathway modeling

---

### Gene Symbol Layer (`genesymbol`)

**Identifier:** Gene symbol (e.g., `CYP1A1`, `nahA`)

**Biological meaning:**

- Represents organism-specific gene nomenclature
- Links to gene expression, regulation, and genetic variation

**Omics relevance:**

- **Transcriptomics:** Gene expression profiling
- **RNA-seq:** Differential expression analysis
- **qPCR:** Targeted gene quantification

---

## Mapping BioRemPP Identifiers to Common Omics Layers

### Metabolomics Integration

**Scenario:** Annotate untargeted metabolomics data with biodegradation potential

**Linkage strategy:**

1. **Match metabolite features to KEGG Compound IDs**
   - Use MS/MS spectral matching (e.g., GNPS, MetFrag)
   - Map InChI/SMILES to KEGG via PubChem

2. **Query BioRemPP for compound-gene relationships**
   - Filter by compound ID (`cpd`)
   - Retrieve associated KO IDs and enzyme activities

3. **Interpret biodegradation potential**
   - Presence of compound in BioRemPP → known biodegradation target
   - Associated genes → candidate biodegradation pathways

**Example workflow (conceptual):**

```
Metabolomics feature → InChI → PubChem CID → KEGG Compound ID → BioRemPP
                                                                      ↓
                                                            KO IDs + Enzymes
```

**Limitation:** Requires external tools for metabolite identification; BioRemPP does not perform spectral matching.

---

### Metagenomics Integration

**Scenario:** Annotate metagenomic contigs with bioremediation potential

**Linkage strategy:**

1. **Annotate genes with KEGG Orthology**
   - Use KEGG Automatic Annotation Server (KAAS), eggNOG-mapper, or DIAMOND
   - Assign KO IDs to predicted genes

2. **Query BioRemPP for KO-compound relationships**
   - Filter by KO ID (`ko`)
   - Retrieve associated compounds and chemical classes

3. **Assess bioremediation potential**
   - Presence of KO in BioRemPP → biodegradation gene
   - Associated compounds → predicted degradation targets

**Example workflow (conceptual):**

```
Metagenomic contig → Gene prediction → KO annotation → BioRemPP
                                                           ↓
                                                  Compounds + Classes
```

**Limitation:** KO annotation quality depends on external tools; BioRemPP does not perform gene prediction or annotation.

---

### Metatranscriptomics Integration

**Scenario:** Identify actively expressed biodegradation genes

**Linkage strategy:**

1. **Quantify gene expression via RNA-seq**
   - Map reads to reference genes or metagenome
   - Assign KO IDs to expressed genes

2. **Query BioRemPP for KO-compound relationships**
   - Filter by KO ID (`ko`)
   - Retrieve associated compounds and enzyme activities

3. **Interpret functional expression**
   - High expression of BioRemPP-annotated KO → active biodegradation
   - Enzyme activity terms → specific catalytic functions

**Example workflow (conceptual):**

```
RNA-seq reads → KO abundance → BioRemPP
                                   ↓
                         Compounds + Enzyme activities
```

**Limitation:** Expression level does not guarantee enzymatic activity; requires experimental validation.

---

### Proteomics Integration

**Scenario:** Link protein abundance to biodegradation function

**Linkage strategy:**

1. **Identify proteins via mass spectrometry**
   - Match peptides to protein sequences
   - Assign gene symbols or KO IDs

2. **Query BioRemPP for gene-compound relationships**
   - Filter by gene symbol (`genesymbol`) or KO ID (`ko`)
   - Retrieve associated compounds and enzyme activities

3. **Correlate protein abundance with function**
   - High abundance of BioRemPP-annotated protein → potential biodegradation activity
   - Enzyme activity terms → predicted catalytic function

**Example workflow (conceptual):**

```
MS/MS spectra → Protein ID → Gene symbol → BioRemPP
                                               ↓
                                    Compounds + Enzyme activities
```

**Limitation:** Protein abundance does not confirm enzymatic activity; requires enzyme assays.

---

### Comparative Genomics Integration

**Scenario:** Compare bioremediation gene repertoires across organisms

**Linkage strategy:**

1. **Annotate genomes with KEGG Orthology**
   - Use KAAS, eggNOG-mapper, or OrthoFinder
   - Assign KO IDs to all genes

2. **Query BioRemPP for biodegradation-relevant KOs**
   - Filter by KO ID (`ko`)
   - Identify organisms with bioremediation genes

3. **Compare gene presence/absence**
   - Organisms with BioRemPP-annotated KOs → biodegradation potential
   - Missing KOs → pathway gaps or alternative mechanisms

**Example workflow (conceptual):**

```
Genome annotation → KO profile → BioRemPP
                                     ↓
                           Biodegradation gene inventory
```

**Limitation:** Gene presence does not guarantee expression or activity; requires transcriptomics or proteomics.

---

## Examples of Cross-Omics Linkage Scenarios

### Scenario 1: Metabolomics + Metagenomics

**Research question:** Which microbial genes are responsible for degrading detected pollutants?

**Linkage approach:**

1. **Metabolomics:** Identify pollutants in environmental sample (e.g., PAHs, PCBs)
2. **Map to KEGG Compound IDs** via PubChem or spectral databases
3. **Query BioRemPP** for compound-KO relationships
4. **Metagenomics:** Check if predicted KOs are present in microbial community
5. **Interpretation:** Overlap between detected compounds and metagenome KOs → candidate degradation pathways

**BioRemPP role:** Provides semantic link between chemical layer (metabolomics) and genetic layer (metagenomics).

---

### Scenario 2: Metatranscriptomics + Proteomics

**Research question:** Are expressed biodegradation genes translated into functional proteins?

**Linkage approach:**

1. **Metatranscriptomics:** Quantify KO expression in microbial community
2. **Query BioRemPP** for KO-enzyme relationships
3. **Proteomics:** Measure protein abundance of predicted enzymes
4. **Correlation:** Compare KO expression vs. protein abundance
5. **Interpretation:** High correlation → active biodegradation pathway; low correlation → post-transcriptional regulation

**BioRemPP role:** Provides functional annotation layer linking transcripts (KO) to proteins (enzyme activities).

---

### Scenario 3: Comparative Genomics + Metabolomics

**Research question:** Do organisms with specific biodegradation genes degrade corresponding compounds?

**Linkage approach:**

1. **Comparative genomics:** Identify organisms with BioRemPP-annotated KOs
2. **Query BioRemPP** for KO-compound relationships
3. **Metabolomics:** Measure compound depletion in cultures of selected organisms
4. **Validation:** Organisms with predicted KOs → compound degradation observed
5. **Interpretation:** Confirms functional prediction from genomic data

**BioRemPP role:** Generates testable hypotheses linking genotype (KO presence) to phenotype (compound degradation).

---

## Interoperability Limitations and Assumptions

### Limitation 1: Identifier Mapping Dependency

**Issue:** BioRemPP uses KEGG identifiers; external datasets may use different nomenclatures.

**Impact:**
- Metabolomics data may use PubChem, ChEBI, or CAS numbers
- Genomics data may use UniProt, NCBI Gene, or organism-specific IDs
- Requires external mapping tools (e.g., UniProt ID Mapping, BridgeDb)

**Recommendation:** Use KEGG as common identifier space; map external IDs to KEGG before querying BioRemPP.

---

### Limitation 2: Organism Independence

**Issue:** BioRemPP KO IDs are organism-independent; do not specify which organisms possess genes.

**Impact:**
- Cannot infer organism-specific biodegradation capacity from BioRemPP alone
- Requires organism-specific genome or metagenome annotation

**Recommendation:** Combine BioRemPP with organism-specific databases (e.g., KEGG Organism, UniProt Proteomes).

---

### Limitation 3: No Quantitative Data

**Issue:** BioRemPP provides qualitative compound-gene associations, not quantitative omics data.

**Impact:**
- Cannot predict degradation rates, enzyme kinetics, or pathway flux
- Requires experimental omics data for quantitative analysis

**Recommendation:** Use BioRemPP for functional annotation; integrate with quantitative omics datasets for modeling.

---

### Limitation 4: Pathway Completeness Not Validated

**Issue:** BioRemPP does not verify completeness of biodegradation pathways.

**Impact:**
- Presence of one gene does not guarantee functional pathway
- Missing intermediate enzymes may prevent complete degradation

**Recommendation:** Consult KEGG Pathway maps for pathway context; validate pathway completeness experimentally.

---

### Limitation 5: No Automated Integration

**Issue:** BioRemPP does not provide automated multi-omics integration pipelines.

**Impact:**
- Users must manually link BioRemPP identifiers to external omics datasets
- Requires bioinformatics expertise and custom scripting

**Recommendation:** Use BioRemPP as annotation layer within existing multi-omics workflows (e.g., MixOmics, MOFA, Anvi'o).

---

## Best Practices for Multi-Omics Reuse

### 1. Use KEGG as Common Identifier Space

**Rationale:** KEGG provides comprehensive cross-references to other databases.

**Implementation:**
- Map metabolomics features to KEGG Compound via PubChem
- Map genomics data to KEGG Orthology via KAAS or eggNOG-mapper
- Use KEGG as semantic bridge between omics layers

---

### 2. Validate Identifier Mappings

**Rationale:** Automated mappings may introduce errors or ambiguities.

**Implementation:**
- Manually inspect high-confidence mappings
- Use multiple mapping tools and compare results
- Document mapping provenance and confidence scores

---

### 3. Integrate BioRemPP with Pathway Databases

**Rationale:** BioRemPP provides gene-compound links; pathway databases provide metabolic context.

**Recommended databases:**
- **KEGG Pathway:** Metabolic pathway maps
- **BioCyc:** Organism-specific pathway databases
- **Reactome:** Human-centric pathway database

**Integration approach:**
- Use BioRemPP to identify candidate genes
- Use pathway databases to validate pathway completeness
- Combine for comprehensive functional annotation

---

### 4. Document Assumptions and Limitations

**Rationale:** Multi-omics integration involves multiple assumptions; transparency is critical.

**Best practices:**
- Document identifier mapping methods and tools
- State assumptions about gene-function relationships
- Acknowledge limitations of functional predictions
- Include BioRemPP version and KEGG release in methods

---

### 5. Experimental Validation

**Rationale:** Computational predictions require experimental confirmation.

**Recommended validations:**
- **Metabolomics:** Confirm compound identification via authentic standards
- **Metagenomics:** Validate gene presence via PCR or sequencing
- **Metatranscriptomics:** Confirm expression via qPCR
- **Proteomics:** Validate protein abundance via Western blot
- **Functional assays:** Measure biodegradation activity in cultures

---

## Multi-Omics Integration Summary

| Omics Layer | BioRemPP Identifier | Linkage Strategy | Validation Required |
|-------------|---------------------|------------------|---------------------|
| **Metabolomics** | Compound ID (`cpd`) | MS/MS → KEGG Compound → BioRemPP | Authentic standards |
| **Metagenomics** | KO ID (`ko`) | Gene prediction → KO annotation → BioRemPP | PCR, sequencing |
| **Metatranscriptomics** | KO ID (`ko`) | RNA-seq → KO abundance → BioRemPP | qPCR |
| **Proteomics** | Gene symbol (`genesymbol`) | MS/MS → Protein ID → BioRemPP | Western blot |
| **Comparative genomics** | KO ID (`ko`) | Genome annotation → KO profile → BioRemPP | Functional assays |

---

## What BioRemPP Multi-Omics Integration IS and is NOT

### What it IS

✅ **Identifier-level interoperability** — Provides semantic bridges between omics layers  
✅ **Functional annotation layer** — Links compounds, genes, and enzymes  
✅ **Hypothesis generation tool** — Suggests candidate biodegradation pathways  
✅ **Cross-database integration enabler** — KEGG IDs link to PubChem, UniProt, etc.  

### What it is NOT

❌ **Automated multi-omics pipeline** — Does not perform data integration  
❌ **Quantitative omics analysis tool** — No statistical modeling or pathway flux  
❌ **Organism-specific annotation** — KO IDs are organism-independent  
❌ **Pathway completeness validator** — Does not verify functional pathways  

---

## Questions?

**GitHub Repository:** [https://github.com/BioRemPP/biorempp_db](https://github.com/BioRemPP/biorempp_db)  
**Email:** biorempp@gmail.com
