# BioRemPP Validation (Great Expectations)

This project provides a standalone validation layer for BioRemPP outputs using Great Expectations.

It validates:
- Final database CSV contract (`v1.1.0`, delimiter `;`)
- Analysis JSON artifacts
- KEGG release traceability metadata
- Reaction textual annotation consistency (`reaction` vs `reaction_description`)

Validation policy is hybrid:
- `critical`: blocks the run (`exit 1`)
- `warning`: reported and can be configured to block (`fail_on_warning`)

Validation now has two explicit and independent modes:
- `internal_consistency`: validates the current CSV against the current run's analysis JSON artifacts and KEGG metadata.
- `regression_detection`: validates the current CSV against a frozen baseline snapshot committed in this repo.

Default shipped behavior enables both modes:
- `validation_modes.internal_consistency: true`
- `validation_modes.regression_detection: true`
- `fail_on_warning: true`

## Directory Architecture

```text
biorempp_validation/
|-- README.md
|-- requirements.lock.txt
|-- requirements-dev.lock.txt
|-- pyproject.toml
|-- config/
|   `-- validation.yaml
|-- env/
|   `-- Dockerfile
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
- CSV delimiter is configured in `config/validation.yaml` (`csv.delimiter`, default `;`).

Expected files under that results root:
- `database/biorempp_database_v1.1.0.csv`
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
- `metadata/keys_consistency_report.json`
- `metadata/links_groundtruth_policy_report.json`
- `reports/workflow_summary.json`

Expected regression baseline root:

`baselines/release_v1_1_0_kegg_118_0plus`

Expected files under that baseline root:
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
- `database_warning`: controlled vocabulary + drift thresholds from `validation.yaml`
- `analysis_json_critical`: required keys/types and core structural checks
- `analysis_json_warning`: top-N and summary quality checks
- `analysis_json_exact_critical`: exact parity checks for analytics metrics/top-N/crosstabs/executive summary
- `metadata_kegg_critical`: KEGG traceability contract
- `cross_consistency_critical`: parity checks between CSV and `basic_statistics.json`
- `pipeline_reports_critical`: sentinel checks for three first-class pipeline report outputs

At runtime, `analysis_json_exact_critical` is expanded into two concrete uses:
- `analysis_json_internal_consistency_critical`
- `analysis_json_regression_critical`

## Checkpoints

- `critical_gate`: all blocking suites
- `warning_report`: warning suites (blocking when `fail_on_warning: true`)

## Installation

Recommended interface: Docker.

Build the validator image from repository root:

```bash
docker compose -f biorempp_snakemake_version/env/docker-compose.yml build validation
```

## Run

Recommended:

```bash
docker compose -f biorempp_snakemake_version/env/docker-compose.yml run --rm validation
```

Explicit entrypoint inside the container:

```bash
docker compose -f biorempp_snakemake_version/env/docker-compose.yml run --rm validation \
  biorempp-validate --config biorempp_validation/config/validation.yaml
```

## Testing

Run the validator test suite in the same pinned container:

```bash
docker compose -f biorempp_snakemake_version/env/docker-compose.yml run --rm validation \
  python -m pytest biorempp_validation/tests -q
```

## Dependency Lockfiles

The validator image installs from exact lockfiles generated from `pyproject.toml`:

- `requirements.lock.txt`: runtime only
- `requirements-dev.lock.txt`: runtime + test tooling

Refresh them from the container:

```bash
docker compose -f biorempp_snakemake_version/env/docker-compose.yml run --rm validation \
  pip-compile biorempp_validation/pyproject.toml -o biorempp_validation/requirements.lock.txt
```

```bash
docker compose -f biorempp_snakemake_version/env/docker-compose.yml run --rm validation \
  pip-compile biorempp_validation/pyproject.toml --extra dev -o biorempp_validation/requirements-dev.lock.txt
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

`validation_summary.json` includes `validation_mode` per failed expectation so it is clear whether a failure came from `internal_consistency`, `regression_detection`, or `current_artifacts`.

Operational details for the dual-mode contract live in [docs/validation_modes.md](docs/validation_modes.md).

## Baseline Refresh

The regression baseline is a release artifact, not a runtime by-product. Update it only when a pipeline change is intentional and has been reviewed.

Recommended refresh flow:
- regenerate the upstream Snakemake results for the intended release;
- review the validation diff and confirm the new outputs are expected;
- replace the files under `baselines/<baseline_id>/`;
- adjust warning thresholds in `config/validation.yaml` only when the drift window itself should change;
- commit the baseline refresh together with the pipeline change that justifies it.

## Notes

- Validation is read-only against upstream Snakemake results.
- `validation_modes` is the only supported mode-selection interface.
- Warning thresholds and vocabularies are configurable in `config/validation.yaml`.
- KEGG source URL is enforced as `https://rest.kegg.jp/info/kegg`.
- Docker is the canonical runtime for consistent execution and pinned dependencies.
