# Contributing

This document describes how external contributors can engage with the BioRemPP Database project.

---

## Purpose of Contributions

BioRemPP Database is a **scientific resource** maintained to support bioremediation research. Contributions are welcome to:

- **Improve data quality** — Correct errors, add missing relationships, or update outdated information
- **Expand data coverage** — Add new compounds, genes, or curations from recent literature
- **Enhance documentation** — Clarify existing documentation or add missing explanations
- **Report issues** — Identify bugs, inconsistencies, or reproducibility problems
- **Suggest improvements** — Propose new features or methodological enhancements

**Contributions are subject to scientific review** to ensure quality, accuracy, and consistency with project goals.

---

## Types of Acceptable Contributions

### 1. Data Contributions

**Acceptable:**

- **Manual curations** — New compound-KO relationships derived from peer-reviewed literature
- **Compound classifications** — Chemical class assignments for unclassified compounds
- **Error corrections** — Fixes to incorrect identifiers, names, or relationships
- **Agency list updates** — New compounds from environmental agency priority lists

**Requirements:**

- Must cite peer-reviewed literature or official agency sources
- Must include KEGG Compound ID and KEGG Orthology ID
- Must follow existing data schema and controlled vocabularies
- Must be submitted via GitHub Pull Request with documentation

**Not acceptable:**

- Unpublished or proprietary data
- Speculative or unvalidated relationships
- Data from non-peer-reviewed sources (unless official agency lists)

---

### 2. Documentation Contributions

**Acceptable:**

- **Clarifications** — Improve unclear or ambiguous documentation
- **Error corrections** — Fix typos, broken links, or incorrect information
- **Examples** — Add usage examples or code snippets
- **Translations** — Translate documentation to other languages (future)

**Requirements:**

- Must maintain scientific tone and accuracy
- Must follow existing documentation structure and style
- Must be submitted via GitHub Pull Request

**Not acceptable:**

- Marketing or promotional language
- Speculative claims or unsupported statements
- Major structural changes without prior discussion

---

### 3. Code Contributions

**Acceptable:**

- **Bug fixes** — Correct errors in pipeline scripts
- **Performance improvements** — Optimize data processing without changing outputs
- **Documentation improvements** — Add code comments or docstrings
- **Test additions** — Add validation tests or reproducibility checks

**Requirements:**

- Must preserve bit-for-bit reproducibility of outputs
- Must include comments explaining changes
- Must pass existing validation tests
- Must be submitted via GitHub Pull Request

**Not acceptable:**

- Changes that alter database content without justification
- Introduction of stochastic or non-deterministic components
- Breaking changes to schema or output format

---

### 4. Issue Reports

**Acceptable:**

- **Data errors** — Incorrect identifiers, names, or relationships
- **Reproducibility issues** — Inability to reproduce documented results
- **Documentation errors** — Typos, broken links, or unclear explanations
- **Feature requests** — Suggestions for new functionality or data sources

**Requirements:**

- Must include sufficient detail to reproduce the issue
- Must specify BioRemPP version and KEGG release version
- Must be submitted via GitHub Issues with appropriate labels

---

## Contribution Workflow

### Step 1: Discuss Before Contributing

**For major contributions (new data sources, schema changes, new features):**

1. Open a GitHub Issue describing the proposed contribution
2. Wait for maintainer feedback before proceeding
3. Discuss implementation approach and requirements

**For minor contributions (bug fixes, typos, small curations):**

- Proceed directly to Pull Request

---

### Step 2: Fork and Clone Repository

```bash
# Fork repository via GitHub web interface
# Clone your fork
git clone https://github.com/YOUR_USERNAME/biorempp_db.git
cd biorempp_db
```

---

### Step 3: Create a Feature Branch

```bash
# Create branch with descriptive name
git checkout -b fix/compound-name-typo
# or
git checkout -b feature/add-pfas-compounds
```

---

### Step 4: Make Changes

**For data contributions:**

- Edit appropriate input files (e.g., `missing_compounds_founds_curated.xlsx`)
- Document source of data (literature DOI, agency URL)
- Re-generate database to validate changes

**For documentation contributions:**

- Edit markdown files in `docs/` directory
- Build documentation locally to verify rendering

**For code contributions:**

- Edit R scripts with clear comments
- Test changes to ensure reproducibility

---

### Step 5: Commit Changes

```bash
# Add changed files
git add input_data/missing_compounds_founds_curated.xlsx

# Commit with descriptive message
git commit -m "Add biodegradation pathway for PFOA (DOI: 10.xxxx/xxxxx)"
```

**Commit message format:**

- Use imperative mood ("Add", "Fix", "Update")
- Reference issue number if applicable (`Fixes #123`)
- Include DOI or source for data contributions

---

### Step 6: Push and Create Pull Request

```bash
# Push to your fork
git push origin fix/compound-name-typo

# Create Pull Request via GitHub web interface
```

**Pull Request description should include:**

- Summary of changes
- Rationale for contribution
- Source of data (for data contributions)
- Impact on reproducibility (if any)

---

### Step 7: Respond to Review

- Maintainers will review your contribution
- Address any requested changes
- Update Pull Request as needed

---

## Quality and Documentation Requirements

### Data Quality Standards

**All data contributions must:**

- ✅ Use valid KEGG Compound IDs (format: `C#####`)
- ✅ Use valid KEGG Orthology IDs (format: `K#####`)
- ✅ Cite peer-reviewed literature or official sources
- ✅ Follow existing controlled vocabularies
- ✅ Include rationale in Pull Request description

**Data contributions will be rejected if:**

- ❌ Identifiers are invalid or non-existent in KEGG
- ❌ Sources are not peer-reviewed or official
- ❌ Data conflicts with existing entries without justification
- ❌ Controlled vocabularies are violated

---

### Documentation Standards

**All documentation contributions must:**

- ✅ Use clear, concise, scientific language
- ✅ Follow existing markdown formatting conventions
- ✅ Include references for factual claims
- ✅ Maintain consistency with existing documentation

**Documentation contributions will be rejected if:**

- ❌ Language is promotional or marketing-oriented
- ❌ Claims are speculative or unsupported
- ❌ Formatting is inconsistent with existing docs
- ❌ Major structural changes are made without discussion

---

### Code Standards

**All code contributions must:**

- ✅ Preserve deterministic behavior (no randomness)
- ✅ Maintain bit-for-bit reproducibility
- ✅ Include comments explaining logic
- ✅ Follow existing code style and structure

**Code contributions will be rejected if:**

- ❌ Reproducibility is compromised
- ❌ Schema or output format is changed without justification
- ❌ Code introduces dependencies not already used
- ❌ Changes are not adequately documented

---

## Review and Acceptance Criteria

### Review Process

1. **Initial screening** — Maintainers check for completeness and adherence to guidelines
2. **Scientific review** — Data contributions are validated against sources
3. **Technical review** — Code contributions are tested for reproducibility
4. **Documentation review** — Documentation contributions are checked for accuracy
5. **Acceptance or revision** — Contributors are notified of decision or requested changes

**Review timeline:** Maintainers aim to respond within **2 weeks** of submission.

---

### Acceptance Criteria

**Contributions will be accepted if:**

- ✅ Quality standards are met
- ✅ Documentation is complete
- ✅ Sources are valid and accessible
- ✅ Changes are scientifically justified
- ✅ Reproducibility is preserved

**Contributions will be rejected if:**

- ❌ Quality standards are not met
- ❌ Sources are invalid or inaccessible
- ❌ Changes are not scientifically justified
- ❌ Reproducibility is compromised
- ❌ Contributor does not respond to review feedback

---

## Code of Conduct

**BioRemPP Database project adheres to scientific community standards:**

- **Respectful communication** — Treat all contributors with respect
- **Constructive feedback** — Provide actionable, specific feedback
- **Scientific integrity** — Do not submit fraudulent or plagiarized data
- **Transparency** — Disclose conflicts of interest or data sources

**Violations of these standards may result in:**

- Rejection of contributions
- Removal from contributor list
- Reporting to institutional authorities (for serious violations)

---

## Contributor Recognition

**Contributors will be acknowledged in:**

- `CONTRIBUTORS.md` file (if created)
- Changelog for specific version
- Acknowledgments section of associated publications (for major contributions)

**Contribution does not grant:**

- Authorship on publications (unless substantial intellectual contribution)
- Decision-making authority over project direction
- Ownership of contributed data (data is licensed under CC BY 4.0)

---

## Questions About Contributing?

**For contribution-related questions:**

- **GitHub Discussions:** [https://github.com/BioRemPP/biorempp_db/discussions](https://github.com/BioRemPP/biorempp_db/discussions)
- **GitHub Issues:** [https://github.com/BioRemPP/biorempp_db/issues](https://github.com/BioRemPP/biorempp_db/issues)
- **Email:** biorempp@gmail.com

**Before contributing, please:**

- Read this contributing guide thoroughly
- Review existing issues and pull requests
- Discuss major contributions before starting work
