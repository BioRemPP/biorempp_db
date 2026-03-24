# Configuration Reference

All runtime behaviour of the validation module is controlled by a single
YAML file located at `biorempp_validation/config/validation.yaml`.

---

## Full Annotated Configuration

Below is the shipped `validation.yaml` with inline annotations for every key.

```yaml
# ── Metadata ────────────────────────────────────────────────────────
version: "1.0.0"                # Tracks the configuration schema version.

# ── Policy Flags ────────────────────────────────────────────────────
policy:
  fail_on_critical: true        # Exit code ≠ 0 when any critical expectation fails.
  fail_on_warning: true         # Exit code ≠ 0 when any warning expectation fails.
  generate_data_docs: true      # Produce the GX HTML Data Docs site after validation.

# ── Strict Exact ────────────────────────────────────────────────────
strict_exact: true              # Pin warning-level drift thresholds to exact observed
                                # values (min == max == actual). See below.

# ── Paths ───────────────────────────────────────────────────────────
paths:
  input_results_root: ../biorempp_snakemake_version/results
                                # Where the Snakemake pipeline writes its outputs.
                                # Relative to the biorempp_validation/ project root.
  output_dir: results           # Where validation artefacts are written.
  expectations_dir: great_expectations/expectations
                                # Directory containing the 7 expectation-suite JSONs.
  checkpoints_dir: great_expectations/checkpoints
                                # Directory containing the 2 checkpoint YAMLs.

# ── Required Files ──────────────────────────────────────────────────
required_files:
  - database/biorempp_database_v1.0.0.csv
  - analysis/basic_statistics.json
  - analysis/compound_statistics.json
  - analysis/ko_statistics.json
  - analysis/enzyme_statistics.json
  - analysis/gene_statistics.json
  - analysis/crosstab_statistics.json
  - analysis/database_metadata.json
  - analysis/executive_summary.json
  - analysis/complete_analysis.json
  - metadata/kegg_release.json

# ── Database Contract ───────────────────────────────────────────────
database_contract:
  expected_columns:             # Column names the CSV must contain (order matters).
    - cpd
    - compoundclass
    - ko
    - referenceAG
    - compoundname
    - genesymbol
    - genename
    - enzyme_activity
  expected_reference_agencies:  # Valid values for the referenceAG column.
    - ATSDR
    - CONAMA
    - EPA
    - EPC
    - IARC1
    - IARC2A
    - IARC2B
    - PSL
    - WFD
  expected_compound_classes:    # Valid values for the compoundclass column.
    - Aliphatic
    - Aromatic
    - Chlorinated
    - Halogenated
    - Inorganic
    - Metal
    - Nitrogen-containing
    - Organometallic
    - Organophosphorus
    - Organosulfur
    - Polyaromatic
    - Sulfur-containing

# ── Drift Thresholds ───────────────────────────────────────────────
drift_thresholds:
  row_count:              {min: 7000,  max: 20000}
  unique_compounds:       {min: 250,   max: 700}
  unique_ko:              {min: 900,   max: 2500}
  unique_genesymbol:      {min: 1000,  max: 2200}
  unique_genename:        {min: 900,   max: 2200}
  unique_enzyme_activity: {min: 120,   max: 400}
```

---

## Section Reference

### `version`

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `version` | string | `"1.0.0"` | Configuration schema version. Currently informational only. |

### `policy`

Controls how the orchestrator translates validation results into exit codes.

| Key | Type | Code Default | Shipped Value | Description |
|-----|------|-------------|---------------|-------------|
| `fail_on_critical` | bool | `True` | `true` | When `true`, any critical expectation failure causes a non-zero exit code. |
| `fail_on_warning` | bool | `False` | `true` | When `true`, any warning expectation failure also causes a non-zero exit code. |
| `generate_data_docs` | bool | `True` | `true` | When `true`, generates `data_docs/` HTML site in the output directory after validation completes. |

!!! note "Code default vs shipped value"
    The code default for `fail_on_warning` is `False` (tolerant), but the
    shipped configuration sets it to `true` for release-grade strictness.
    Developers may override it to `false` during iteration.

### `strict_exact`

| Key | Type | Code Default | Shipped Value | Description |
|-----|------|-------------|---------------|-------------|
| `strict_exact` | bool | `False` | `true` | Controls how warning-level drift thresholds are computed. |

When **`true`**, the `drift_thresholds` section is ignored for warning suites.
Instead, min and max are pinned to the **exact observed values** from the
analysis JSON payloads.  Any deviation — even adding a single row — triggers a
warning failure.

When **`false`**, the wider `drift_thresholds` ranges below are used, allowing
natural variation between KEGG releases.

See [Severity Policy](severity-policy.md#strict_exact-mode) for a detailed
explanation.

### `paths`

All paths are resolved relative to the `biorempp_validation/` **project root**
(the parent of the `config/` directory).  Absolute paths are also accepted.

| Key | Type | Shipped Value | Description |
|-----|------|---------------|-------------|
| `input_results_root` | string | `../biorempp_snakemake_version/results` | Root directory containing pipeline outputs (CSV, JSON files). |
| `output_dir` | string | `results` | Directory where validation artefacts are written. |
| `expectations_dir` | string | `great_expectations/expectations` | Directory containing the 7 expectation-suite JSON files. |
| `checkpoints_dir` | string | `great_expectations/checkpoints` | Directory containing the 2 checkpoint YAML files. |

### `required_files`

A flat list of 11 file paths (relative to `input_results_root`) that must exist
before validation begins.  The preflight check in `loaders.py` verifies
presence of every file and reports all missing files at once.

### `database_contract`

Defines the structural and domain-value contracts for the CSV database.

| Sub-Key | Type | Count | Description |
|---------|------|-------|-------------|
| `expected_columns` | list[str] | 8 | Column names the CSV must contain, in order. |
| `expected_reference_agencies` | list[str] | 9 | Closed vocabulary for the `referenceAG` column. |
| `expected_compound_classes` | list[str] | 12 | Closed vocabulary for the `compoundclass` column. |

See [Data Contracts](data-contracts.md) for the full semantics of each
vocabulary entry.

### `drift_thresholds`

Defines acceptable ranges for cardinality metrics.  These ranges are used
**only** when `strict_exact: false`.

| Metric | Min | Max | Description |
|--------|----:|----:|-------------|
| `row_count` | 7,000 | 20,000 | Total rows in the CSV. |
| `unique_compounds` | 250 | 700 | Distinct `cpd` identifiers. |
| `unique_ko` | 900 | 2,500 | Distinct `ko` identifiers. |
| `unique_genesymbol` | 1,000 | 2,200 | Distinct gene symbols. |
| `unique_genename` | 900 | 2,200 | Distinct gene names. |
| `unique_enzyme_activity` | 120 | 400 | Distinct enzyme activities. |

!!! tip "Choosing threshold ranges"
    Ranges should be wide enough to absorb normal KEGG release fluctuations
    but narrow enough to catch data-pipeline regressions.  Monitor the values
    across several releases to calibrate appropriate bounds.

---

## Path Resolution Logic

The `settings.py` loader resolves paths as follows:

```
project_root = config_path.parent.parent   # e.g., biorempp_validation/
resolved     = (project_root / relative_path).resolve()
```

This means all paths in the `paths:` section are anchored to the
`biorempp_validation/` directory, **not** to the YAML file's own directory.

---

## Common Configuration Scenarios

### Release Validation (default)

```yaml
policy:
  fail_on_critical: true
  fail_on_warning: true
strict_exact: true
```

Strictest mode.  Every expectation must pass, drift thresholds are pinned to
exact values, and both warning and critical failures produce a non-zero exit
code.

### CI / Nightly Builds

```yaml
policy:
  fail_on_critical: true
  fail_on_warning: false
strict_exact: true
```

Critical failures block the pipeline.  Warning-level drift (e.g., cardinality
shifts) is logged but does not fail the build.

### Development / Exploration

```yaml
policy:
  fail_on_critical: true
  fail_on_warning: false
strict_exact: false
```

Wide drift bands from `drift_thresholds` are used.  Schema and
reproducibility checks still run at critical severity; only warnings are
relaxed.

### Custom Pipeline Output Location

```yaml
paths:
  input_results_root: /data/pipeline_runs/2026-02-18/results
```

Point `input_results_root` to any directory containing the expected 11 files.
Absolute paths are resolved as-is.
