# BioRemPP Validation (Great Expectations)

This project provides a standalone validation layer for BioRemPP outputs using Great Expectations.

It validates:
- Final database CSV contract (`v1.0.0`)
- Analysis JSON artifacts
- KEGG release traceability metadata

Validation policy is hybrid:
- `critical`: blocks the run (`exit 1`)
- `warning`: reported and can be configured to block (`fail_on_warning`)

Current default mode is strict exact (no drift):
- `strict_exact: true`
- `fail_on_warning: true`
- Expected values are validated exactly against `biorempp_snakemake_version/results/analysis` artifacts.

## Directory Architecture

```text
biorempp_validation/
|-- README.md
|-- pyproject.toml
|-- requirements.txt
|-- config/
|   `-- validation.yaml
|-- great_expectations/
|   |-- great_expectations.yml
|   |-- checkpoints/
|   |   |-- critical_gate.yml
|   |   `-- warning_report.yml
|   |-- expectations/
|   |   |-- analysis_json_exact_critical.json
|   |   |-- analysis_json_critical.json
|   |   |-- analysis_json_warning.json
|   |   |-- cross_consistency_critical.json
|   |   |-- database_critical.json
|   |   |-- database_warning.json
|   |   `-- metadata_kegg_critical.json
|   `-- plugins/
|       `-- .gitkeep
|-- src/
|   `-- biorempp_validation/
|       |-- __init__.py
|       |-- consistency_checks.py
|       |-- gx_context.py
|       |-- json_to_dataframe.py
|       |-- loaders.py
|       |-- report_builder.py
|       |-- run_validation.py
|       `-- settings.py
|-- tests/
|   |-- test_happy_path.py
|   |-- test_kegg_metadata.py
|   |-- test_missing_files.py
|   |-- test_schema_break.py
|   `-- test_warning_only_drift.py
`-- results/
    `-- .gitkeep
```

## Input Source and Path Consistency

By default, validation reads artifacts from:

`../biorempp_snakemake_version/results`

Important:
- This path is resolved relative to `biorempp_validation/` project root.
- It does **not** read from `input_data/`.
- This keeps behavior consistent with the Snakemake pipeline outputs.

Expected files under that results root:
- `database/biorempp_database_v1.0.0.csv`
- `analysis/basic_statistics.json`
- `analysis/compound_statistics.json`
- `analysis/ko_statistics.json`
- `analysis/enzyme_statistics.json`
- `analysis/gene_statistics.json`
- `analysis/crosstab_statistics.json`
- `analysis/database_metadata.json`
- `analysis/executive_summary.json`
- `analysis/complete_analysis.json`
- `metadata/kegg_release.json`

## Validation Suites

- `database_critical`: schema, nulls, regex IDs, duplicate full rows
- `database_warning`: controlled vocabulary + strict exact counts when `strict_exact=true`
- `analysis_json_critical`: required keys/types and core structural checks
- `analysis_json_warning`: top-N and summary quality checks
- `analysis_json_exact_critical`: exact parity checks for analytics metrics/top-N/crosstabs/executive summary
- `metadata_kegg_critical`: KEGG traceability contract
- `cross_consistency_critical`: parity checks between CSV and `basic_statistics.json`

## Checkpoints

- `critical_gate`: all blocking suites
- `warning_report`: warning suites (blocking when `fail_on_warning: true`)

## Installation

From repository root:

```bash
pip install -e biorempp_validation
```

or:

```bash
pip install -r biorempp_validation/requirements.txt
```

## Run

```bash
python -m biorempp_validation.run_validation --config biorempp_validation/config/validation.yaml
```

Alternative entrypoint:

```bash
biorempp-validate --config biorempp_validation/config/validation.yaml
```

## Outputs

Generated in `biorempp_validation/results/`:
- `critical_checkpoint_result.json`
- `warning_checkpoint_result.json`
- `validation_summary.json`
- `data_docs/index.html` (lightweight summary page)

Exit codes:
- `0`: no critical failures
- `1`: one or more critical failures

If `fail_on_warning: true`, any warning failure also returns `1`.

## Testing

```bash
pytest biorempp_validation/tests -q
```

## Notes

- Validation is read-only against upstream Snakemake results.
- Warning thresholds and vocabularies are configurable in `config/validation.yaml`.
- KEGG source URL is enforced as `https://rest.kegg.jp/info/kegg`.
