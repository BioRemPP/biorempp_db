# Known Limitations

This document explicitly describes the methodological and data-related limitations of the BioRemPP Database v1.0.0.

---

## Purpose of This Document

The BioRemPP Database is a **knowledge integration resource** designed for specific use cases in bioremediation research. This document defines the **scientific boundaries** of the database to ensure appropriate reuse and prevent misinterpretation.

**Intended use:** Understanding limitations is essential for:

- Correct interpretation of database content
- Appropriate selection of analytical methods
- Realistic expectations for downstream applications
- Identification of areas requiring additional validation

---

## Scope-Related Limitations

### Limitation 1: Environmental Pollutant Focus

**Boundary:** Database is limited to compounds classified as priority pollutants or contaminants of concern by environmental regulatory agencies.

**Implications:**

- ❌ **Not comprehensive for all xenobiotics** — Many industrial chemicals, pharmaceuticals, and emerging contaminants are excluded
- ❌ **Not suitable for general metabolism studies** — Focus is environmental remediation, not general biochemistry
- ❌ **Agency-dependent coverage** — Compounds not listed by the 9 included agencies are excluded

**Example:** Emerging contaminants like microplastics, PFAS (per- and polyfluoroalkyl substances), or novel pharmaceuticals may not be represented if not yet classified by agencies.

**Recommendation:** For comprehensive xenobiotic coverage, consult KEGG Xenobiotics Biodegradation module or PubChem BioAssay.

---

### Limitation 2: Functional Potential, Not Realized Activity

**Boundary:** Database represents **gene presence**, not **functional expression** or **enzymatic activity**.

**Implications:**

- ❌ **No guarantee of biodegradation** — Presence of gene does not confirm compound degradation in specific organisms or environments
- ❌ **No kinetic or thermodynamic data** — Database does not include degradation rates, efficiencies, or pathway energetics
- ❌ **No organism-specific validation** — KO groups are organism-independent; actual gene function varies by species

**Example:** A microorganism possessing cytochrome P450 genes (KO:K07408) may not degrade trichloroethene in practice due to:

- Gene not expressed under environmental conditions
- Enzyme requires specific cofactors not available
- Competing metabolic pathways prioritized
- Inhibitory compounds present

**Recommendation:** Experimental validation required for organism-specific biodegradation claims.

---

### Limitation 3: No Pathway Completeness Validation

**Boundary:** Database does not verify completeness of biodegradation pathways.

**Implications:**

- ❌ **Incomplete pathways may be represented** — Presence of one enzyme does not guarantee full degradation pathway
- ❌ **No pathway gap analysis** — Missing intermediate steps not identified
- ❌ **No metabolic network context** — Relationships between pathways not modeled

**Example:** Database may include genes for initial oxidation of benzene (e.g., dioxygenase) but not downstream enzymes for ring cleavage or mineralization.

**Recommendation:** Consult KEGG Pathway maps or BioCyc for pathway context and completeness.

---

### Limitation 4: Single-Compound Focus

**Boundary:** Database represents compound-gene relationships individually, not compound mixtures or synergistic effects.

**Implications:**

- ❌ **No co-metabolism modeling** — Degradation of one compound may require presence of another (not captured)
- ❌ **No inhibition or competition** — Competitive inhibition between compounds not represented
- ❌ **No mixture toxicity** — Synergistic or antagonistic effects of pollutant mixtures not modeled

**Example:** Some compounds (e.g., chlorinated solvents) are degraded via co-metabolism with primary substrates like methane or toluene. Database does not capture these dependencies.

**Recommendation:** For mixture studies, consult experimental biodegradation literature.

---

## Data Source Dependency Limitations

### Limitation 5: Temporal Dependency on KEGG

**Boundary:** Database content reflects KEGG Release Dec,25; newer data not included.

**Implications:**

- ❌ **Static snapshot** — Database does not auto-update with new KEGG releases
- ❌ **Missing recent discoveries** — Genes, compounds, or pathways added to KEGG after Dec,25 are excluded
- ❌ **Deprecated entries** — KEGG may retire or merge entries; database does not reflect post-Dec,25 changes

**Impact on reproducibility:**

- ✅ **Positive:** Fixed KEGG version ensures reproducibility
- ⚠️ **Negative:** Database becomes outdated over time

**Recommendation:** Check KEGG release notes for significant updates; re-generate database annually.

---

### Limitation 6: Annotated Genes Only

**Boundary:** Database contains only genes with existing KEGG Orthology (KO) annotations; novel or predicted genes are not included by default.

**Scope of gene coverage:**

- ✅ **Annotated genes** — All genes with KO assignments in KEGG database (Dec,25)
- ❌ **Novel genes** — Newly discovered genes without KO annotations are excluded
- ❌ **Predicted genes** — Computationally predicted genes without experimental validation are excluded
- ⚠️ **Unannotated enzymes** — Biodegradation enzymes without KO assignments are not represented

**Implications:**

- **Database reflects current state of KEGG annotation** — Coverage depends on KEGG curation efforts
- **Emerging biodegradation mechanisms may be missing** — Recently discovered pathways not yet annotated in KEGG
- **Environmental microbes may be under-represented** — Specialized biodegradation organisms (e.g., Dehalococcoides, Geobacter) may have limited KO coverage

**Example:** Anaerobic biodegradation pathways are under-represented compared to aerobic pathways due to fewer annotated genes in KEGG.

**Extension mechanism:**

Novel genes or enzymes **can be added** through manual curation:

1. **Predict novel gene function** — Use homology modeling, structural prediction, or experimental validation
2. **Add to curation file** — Include in `missing_compounds_founds_curated.xlsx` with compound-KO relationship
3. **Re-generate database** — Pipeline will incorporate manually curated entries

**Recommendation:** 

- For novel genes: Predict function and add via manual curation
- For comprehensive coverage: Supplement with specialized databases (e.g., UM-BBD archives, BioCyc Environmental Genomes)

---

### Limitation 7: Agency List Currency

**Boundary:** Environmental agency compound lists reflect regulatory priorities at time of curation, not current scientific knowledge.

**Agency list characteristics:**

- **Regulatory focus:** Lists prioritize compounds with known health/environmental risks
- **Update frequency:** Varies by agency (EPA: irregular, IARC: ~5 years)
- **Geographic bias:** Lists reflect regional concerns (e.g., CONAMA for Brazil)

**Implications:**

- ❌ **Emerging contaminants under-represented** — Newly identified pollutants not yet regulated are excluded
- ❌ **Legacy pollutants over-represented** — Historical concerns (e.g., DDT) may dominate despite reduced current use
- ❌ **Regional gaps** — Pollutants of concern in under-represented regions (e.g., Africa, Asia) may be missing

**Example:** PFAS compounds are increasingly recognized as priority pollutants but may not appear in older agency lists.

**Recommendation:** Consult recent regulatory updates (e.g., EPA PFAS Action Plan, EU REACH).

---

## Annotation Coverage Limitations

### Limitation 8: Incomplete Compound Classification

**Boundary:** Compound chemical classifications are manually curated and may not cover all structural features.

**Classification limitations:**

- **Multi-class compounds:** Some compounds belong to multiple classes (e.g., chlorinated aromatics) — all classes represented, but may cause row duplication
- **Subjective boundaries:** Classification decisions (e.g., "Aromatic" vs. "Polyaromatic") involve expert judgment
- **Missing classes:** Emerging chemical classes (e.g., nanomaterials, ionic liquids) not represented

**Implications:**

- ⚠️ **Inconsistent granularity** — Some classes are broad (e.g., "Aliphatic"), others specific (e.g., "Organophosphorus")
- ⚠️ **No hierarchical classification** — No parent-child relationships between classes (e.g., "Polyaromatic" is subset of "Aromatic")

**Recommendation:** For detailed chemical classification, consult ChEBI ontology or PubChem classification.

---

### Limitation 9: Enzyme Activity Extraction Limitations

**Boundary:** Enzyme activities are extracted via pattern matching; not all enzymes are captured.

**Extraction method limitations:**

- **Pattern matching:** Relies on 218-term lexicon; novel enzyme names may be missed
- **Fallback behavior:** If no match, full gene name used (may be verbose)
- **Ambiguity:** Some gene names match multiple enzyme terms (first match used)

**Implications:**

- ⚠️ **Long-tail distribution** — 205 unique enzyme activities; many single-occurrence terms
- ⚠️ **Inconsistent granularity** — Some activities are specific (e.g., "cytochrome P450"), others generic (e.g., "oxidase")
- ⚠️ **No EC number mapping** — Enzyme activities are text terms, not standardized EC numbers

**Example:** Novel dehalogenase variants may not match lexicon and appear as full gene name.

**Recommendation:** For EC number-based analysis, map KO IDs to EC numbers via KEGG API.

---

### Limitation 10: Gene Symbol Simplification

**Boundary:** Gene symbols are simplified to single canonical identifier; isoform information is lost.

**Simplification strategy:**

- **Comma-separated isoforms collapsed:** `CYP1A1,CYP1A2` → `CYP1A1`
- **First symbol retained:** Arbitrary choice when multiple symbols exist

**Implications:**

- ❌ **Loss of isoform diversity** — Functional differences between isoforms not captured
- ❌ **Potential for misidentification** — Simplified symbol may not represent all KO group members

**Example:** Cytochrome P450 family has many isoforms with distinct substrate specificities; database collapses to single symbol per KO.

**Recommendation:** Consult KEGG KO database for full isoform lists.

---

## Interpretation Limitations for Downstream Analyses

### Limitation 11: No Quantitative Predictions

**Boundary:** Database provides qualitative compound-gene associations, not quantitative predictions.

**What database does NOT provide:**

- ❌ **Degradation rates** — No kinetic parameters (Km, Vmax, kcat)
- ❌ **Pathway flux** — No metabolic flux analysis or stoichiometry
- ❌ **Enzyme efficiency** — No comparative enzyme performance data
- ❌ **Environmental fate modeling** — No half-lives, bioavailability, or transport parameters

**Implications:**

- Database suitable for **hypothesis generation**, not **quantitative modeling**
- Experimental validation required for quantitative claims

**Recommendation:** For quantitative biodegradation modeling, consult QSAR models or experimental kinetics databases.

---

### Limitation 12: No Organism-Specific Annotations

**Boundary:** KO groups are organism-independent; database does not specify which organisms possess which genes.

**Implications:**

- ❌ **Cannot infer organism-specific biodegradation** — Presence of KO in database does not mean specific organism has gene
- ❌ **No taxonomic distribution** — Cannot determine if gene is widespread or rare
- ❌ **No horizontal gene transfer tracking** — Cannot identify mobile genetic elements

**Example:** KO:K07408 (cytochrome P450) is present in humans, bacteria, fungi, and plants. Database does not distinguish.

**Recommendation:** Map KO IDs to organism-specific genes via KEGG Organism database or UniProt.

---

### Limitation 13: No Experimental Validation

**Boundary:** Database is a **knowledge integration resource**, not an experimentally validated dataset.

**Validation status:**

- ✅ **KEGG-derived relationships:** Validated by KEGG curators (literature-based)
- ⚠️ **Manual curations:** Based on literature review but not experimentally re-validated
- ❌ **No wet-lab confirmation:** No enzyme assays, biodegradation experiments, or functional genomics performed

**Implications:**

- Database represents **predicted functional potential**, not **confirmed activity**
- Suitable for **in silico analysis** and **hypothesis generation**
- **Not suitable** as sole evidence for biodegradation claims

**Recommendation:** Experimental validation required for publication-quality biodegradation claims.

---

### Limitation 14: Multi-Class Compound Representation

**Boundary:** Compounds with multiple chemical classes appear in multiple rows.

**Implications:**

- ⚠️ **Row count ≠ unique compounds** — 10,871 rows represent 384 unique compounds
- ⚠️ **Potential for double-counting** — Naive aggregation may overcount compounds

**Correct analysis approach:**

```r
# INCORRECT: Count rows
nrow(db)  # 10,871 (inflated)

# CORRECT: Count unique compounds
length(unique(db$cpd))  # 384 (accurate)
```

**Recommendation:** Always use `distinct(cpd)` or `unique(cpd)` for compound counts.

---

## Implications for Reuse and Extension

### What BioRemPP Database IS Suitable For

✅ **Appropriate use cases:**

1. **Functional annotation of metagenomes** — Identify bioremediation potential in environmental samples
2. **Gene-centric biodegradation analysis** — Explore enzyme diversity for specific pollutants
3. **Regulatory compliance screening** — Check if organisms possess genes for agency-listed compounds
4. **Comparative genomics** — Compare biodegradation gene repertoires across organisms (after KO-to-organism mapping)
5. **Hypothesis generation** — Identify candidate genes for experimental validation
6. **Educational purposes** — Teach biodegradation pathways and enzyme families

---

### What BioRemPP Database is NOT Suitable For

❌ **Inappropriate use cases:**

1. **Quantitative biodegradation modeling** — No kinetic or thermodynamic data
2. **Organism-specific pathway reconstruction** — No taxonomic annotations
3. **Real-time environmental monitoring** — Static snapshot, not live data
4. **Regulatory risk assessment** — No toxicity, bioavailability, or exposure data
5. **Comprehensive xenobiotic coverage** — Limited to agency-listed compounds
6. **Pathway completeness validation** — No gap analysis or intermediate verification
7. **Experimental biodegradation claims** — Requires wet-lab validation
8. **Mixture toxicity modeling** — No co-metabolism or synergistic effects

---

### Extending the Database

**Recommended extensions:**

| Extension | Benefit | Implementation |
|-----------|---------|----------------|
| **Organism-specific mapping** | Enable taxonomic analysis | Map KO IDs to KEGG Organism database |
| **EC number integration** | Standardize enzyme classification | Query KEGG API for KO-to-EC mappings |
| **Pathway context** | Validate pathway completeness | Integrate KEGG Pathway maps |
| **Quantitative data** | Enable kinetic modeling | Integrate BRENDA or experimental databases |
| **Emerging contaminants** | Expand compound coverage | Add PFAS, microplastics, novel pharmaceuticals |
| **Experimental validation** | Increase confidence | Conduct enzyme assays or biodegradation experiments |

---

### Data Update Recommendations

**Update frequency:**

- **Annual:** Re-generate database with latest KEGG release
- **Quarterly:** Check for major agency list updates (EPA, IARC)
- **Ad-hoc:** Add manual curations from recent literature

**Version control:**

- Semantic versioning (v1.x.x for data updates, v2.0.0 for schema changes)
- Changelog documenting all changes
- Git tags for reproducibility

---

## Limitations Summary Table

| Limitation Category | Key Limitations | Impact on Use |
|---------------------|-----------------|---------------|
| **Scope** | Environmental pollutants only; functional potential, not activity | Not comprehensive for all xenobiotics |
| **Data Sources** | KEGG Dec,25 snapshot; agency list currency | Becomes outdated; regional biases |
| **Annotations** | Manual curation; pattern-based enzyme extraction | Subjective classifications; incomplete coverage |
| **Interpretation** | No quantitative data; no organism-specificity | Hypothesis generation only; requires validation |

---

## Responsible Use Statement

**Users of BioRemPP Database should:**

- ✅ Understand and acknowledge limitations in publications
- ✅ Validate findings experimentally when making biodegradation claims
- ✅ Supplement with organism-specific and pathway-level data
- ✅ Check for database updates before critical analyses
- ✅ Report errors or inconsistencies via GitHub Issues

**Users should NOT:**

- ❌ Claim experimental validation without wet-lab confirmation
- ❌ Use database as sole evidence for regulatory decisions
- ❌ Assume pathway completeness without verification
- ❌ Ignore temporal dependency on KEGG release version

---

## Questions?

**GitHub Issues:** [https://github.com/BioRemPP/biorempp_db/issues](https://github.com/BioRemPP/biorempp_db/issues)  
**Email:** biorempp@gmail.com
