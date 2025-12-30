# How to Cite

This document provides citation guidelines for the BioRemPP Database and associated resources.

---

## Purpose of Citation

Citation is a **scientific requirement** to:

- Acknowledge the intellectual contribution of database creators
- Enable readers to access the original resource
- Track the impact and reuse of scientific data
- Support reproducibility of research findings

**Citation is not a legal requirement** but is expected under academic norms and journal policies.

---

## When Citation is Required

Users **must cite** BioRemPP Database when:

- Using the database in published research (articles, preprints, theses)
- Presenting results derived from BioRemPP data (conferences, posters, talks)
- Redistributing or integrating BioRemPP data into other resources
- Building tools or workflows that depend on BioRemPP annotations

Users **should cite** BioRemPP Database when:

- Mentioning the database in methods sections
- Comparing BioRemPP to other databases
- Discussing bioremediation gene-compound relationships

---

## Recommended Citation Format

### Database Citation (Primary)

**For general use of the BioRemPP Database:**

```
BioRemPP Development Team. (2025). BioRemPP Database v1.0.0: 
A FAIR-compliant resource integrating KEGG orthology, environmental agencies, 
and curated biodegradation data for bioremediation research [Data set]. 
Zenodo. https://doi.org/10.5281/zenodo.[PLACEHOLDER]
```

**BibTeX format:**

```bibtex
@dataset{biorempp_database_2025,
  author       = {{BioRemPP Development Team}},
  title        = {{BioRemPP Database v1.0.0: A FAIR-compliant resource 
                   integrating KEGG orthology, environmental agencies, 
                   and curated biodegradation data for bioremediation research}},
  year         = 2025,
  publisher    = {Zenodo},
  version      = {1.0.0},
  doi          = {10.5281/zenodo.[PLACEHOLDER]},
  url          = {https://doi.org/10.5281/zenodo.[PLACEHOLDER]}
}
```

---

### GitHub Repository Citation (Alternative)

**If DOI is not yet available:**

```
BioRemPP Development Team. (2025). BioRemPP Database v1.0.0. 
GitHub. https://github.com/BioRemPP/biorempp_db
```

**BibTeX format:**

```bibtex
@misc{biorempp_github_2025,
  author       = {{BioRemPP Development Team}},
  title        = {{BioRemPP Database v1.0.0}},
  year         = 2025,
  publisher    = {GitHub},
  version      = {1.0.0},
  url          = {https://github.com/BioRemPP/biorempp_db}
}
```

---

### Associated Publication Citation (When Available)

**If a peer-reviewed publication describes BioRemPP:**

```
[Authors]. ([Year]). [Title]. [Journal]. [Volume]([Issue]), [Pages]. 
https://doi.org/[DOI]
```

**Note:** As of v1.0.0, no peer-reviewed publication is available. This section will be updated upon publication.

---

## Dataset Citation Considerations

### Version-Specific Citation

**Always specify the database version** used in your research:

- ✅ Correct: "BioRemPP Database v1.0.0"
- ❌ Incorrect: "BioRemPP Database" (ambiguous version)

**Rationale:** Database content may change between versions; version-specific citation ensures reproducibility.

---

### KEGG Release Version

**Include KEGG release version** when relevant:

```
BioRemPP Database v1.0.0 (KEGG Release Dec,25)
```

**Rationale:** BioRemPP content depends on KEGG snapshot; specifying KEGG version enhances reproducibility.

---

### Multiple Database Versions

**If using multiple BioRemPP versions:**

```
BioRemPP Database v1.0.0 and v1.1.0 (BioRemPP Development Team, 2025)
```

**Or cite each version separately:**

```
BioRemPP Development Team. (2025). BioRemPP Database v1.0.0 [Data set]. 
Zenodo. https://doi.org/10.5281/zenodo.[PLACEHOLDER_V1]

BioRemPP Development Team. (2025). BioRemPP Database v1.1.0 [Data set]. 
Zenodo. https://doi.org/10.5281/zenodo.[PLACEHOLDER_V2]
```

---

### Derived Datasets

**If you create a derived dataset from BioRemPP:**

1. Cite the original BioRemPP Database
2. Describe the derivation process in your methods
3. Consider depositing your derived dataset with its own DOI

**Example citation:**

```
Derived dataset based on BioRemPP Database v1.0.0 (BioRemPP Development Team, 2025), 
filtered for aromatic compounds and deposited at [DOI].
```

---

## Citation in Different Contexts

### In Methods Sections

**Recommended phrasing:**

> "Functional annotation of biodegradation genes was performed using BioRemPP Database v1.0.0 (BioRemPP Development Team, 2025), a FAIR-compliant resource integrating KEGG orthology, environmental agency compound lists, and curated biodegradation data."

---

### In Data Availability Statements

**Recommended phrasing:**

> "BioRemPP Database v1.0.0 is publicly available at https://doi.org/10.5281/zenodo.[PLACEHOLDER] under a Creative Commons Attribution 4.0 International (CC BY 4.0) license."

---

### In Acknowledgments (Optional)

**If BioRemPP was essential to your research:**

> "We thank the BioRemPP Development Team for creating and maintaining the BioRemPP Database."

**Note:** Acknowledgment does not replace citation.

---

## Citing Underlying Data Sources

**BioRemPP integrates data from external sources.** Users should also cite:

### KEGG Database

**If using KEGG identifiers or annotations:**

```
Kanehisa M, Goto S. KEGG: Kyoto Encyclopedia of Genes and Genomes. 
Nucleic Acids Res. 2000;28(1):27-30. https://doi.org/10.1093/nar/28.1.27
```

---

### Environmental Agencies

**If focusing on agency-specific compounds:**

Cite the relevant agency's compound list (e.g., EPA Priority Pollutant List, IARC Monographs).

**Example:**

```
U.S. Environmental Protection Agency. (2014). Priority Pollutant List. 
https://www.epa.gov/eg/toxic-and-priority-pollutants-under-clean-water-act
```

---

## Questions About Citation?

**For citation-related questions:**

- **GitHub Issues:** [https://github.com/BioRemPP/biorempp_db/issues](https://github.com/BioRemPP/biorempp_db/issues)
- **Email:** biorempp@gmail.com

**For DOI-related questions:**

- Check the [Zenodo record](https://doi.org/10.5281/zenodo.[PLACEHOLDER]) for the most up-to-date citation information.
