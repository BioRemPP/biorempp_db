<!--
Page status: verified
Audience: operators, maintainers, reviewers
Applies to: GX
Version scope: GX validator v1.1.0
Last verified on: 2026-06-24
Primary sources:
- biorempp_validation/config/validation.yaml
- biorempp_validation/pyproject.toml
- biorempp_validation/env/Dockerfile
- biorempp_validation/src/biorempp_validation/settings.py
- biorempp_validation/src/biorempp_validation/run_validation.py
- biorempp_validation/src/biorempp_validation/loaders.py
- biorempp_validation/src/biorempp_validation/json_to_dataframe.py
- biorempp_validation/src/biorempp_validation/consistency_checks.py
- biorempp_validation/src/biorempp_validation/gx_context.py
- biorempp_validation/src/biorempp_validation/report_builder.py
- biorempp_snakemake_version/env/docker-compose.yml
Observed artifacts:
- biorempp_validation/results/critical_checkpoint_result.json
- biorempp_validation/results/warning_checkpoint_result.json
- biorempp_validation/results/validation_summary.json
- biorempp_validation/results/data_docs/index.html
-->

# Architecture

The GX validator is a standalone validation project under `biorempp_validation/`. It reads the Snakemake results tree after the pipeline finishes and writes its own checkpoint outputs under `biorempp_validation/results/`.

## Runtime Surface

The validator exposes one packaged CLI entrypoint:

- `biorempp-validate --config biorempp_validation/config/validation.yaml`

The canonical container entrypoint is the `validation` service declared in `biorempp_snakemake_version/env/docker-compose.yml`.

## Execution Model

`run_validation.py` orchestrates the validator in five stages:

1. load `ValidationSettings` from `config/validation.yaml`
2. preflight the required current results and, when enabled, the regression baseline files
3. load the current CSV plus the JSON artifacts needed for the active modes
4. build derived pandas DataFrames for each validation dataset
5. run the configured suites through Great Expectations and write the checkpoint outputs

The validator is read-only against the upstream Snakemake results. It does not modify the pipeline outputs it validates.

## Dataset Model

The validator does not run suites directly against raw files except for the database CSV. Instead, it materializes a small set of named DataFrames:

| Dataset name | Built from | Used by |
|---|---|---|
| `database_csv` | current release CSV | `database_critical`, `database_warning` |
| `metadata_kegg` | current `metadata/kegg_release.json` | `metadata_kegg_critical` |
| `pipeline_reports` | current `keys_consistency_report.json`, `links_groundtruth_policy_report.json`, and `workflow_summary.json` | `pipeline_reports_critical` |
| `analysis_critical` | current database CSV plus current analysis JSON payloads | `analysis_json_critical` |
| `analysis_warning` | current analysis JSON payloads | `analysis_json_warning` |
| `analysis_internal_consistency` | current database CSV plus current analysis JSON payloads plus current KEGG release metadata | `analysis_json_internal_consistency_critical` |
| `analysis_regression` | current database CSV plus baseline analysis JSON payloads plus baseline KEGG release metadata | `analysis_json_regression_critical` |
| `cross_consistency` | current database CSV plus current `basic_statistics.json` | `cross_consistency_critical` |

This dataset layer is the core of the validator design. Great Expectations evaluates normalized tabular views, not arbitrary nested JSON documents directly.

## Checkpoint Model

Two checkpoint YAML files define the validator structure:

- `great_expectations/checkpoints/critical_gate.yml`
- `great_expectations/checkpoints/warning_report.yml`

At runtime, `run_validation.py` expands those checkpoint definitions according to the active validation modes. In the current observed critical checkpoint artifact, the executed suites are:

- `database_critical`
- `analysis_json_critical`
- `analysis_json_internal_consistency_critical`
- `analysis_json_regression_critical`
- `metadata_kegg_critical`
- `cross_consistency_critical`
- `pipeline_reports_critical`

The warning checkpoint currently runs:

- `database_warning`
- `analysis_json_warning`

## Great Expectations Integration Pattern

The validator ships a `great_expectations/` project tree, but the runtime is code-driven rather than store-driven.

The current Python path does all of the following directly:

- creates an ephemeral GX context with `gx.get_context(mode="ephemeral")`
- loads expectation suite JSON files from `expectations_dir`
- loads checkpoint YAML files from `checkpoints_dir`
- constructs a pandas datasource at runtime
- writes checkpoint payloads and summary outputs through Python code

In other words, the validator uses Great Expectations as the execution engine, but the orchestration contract lives in `run_validation.py`.

## Outputs

The validator currently writes four public artifacts under `biorempp_validation/results/`:

- `critical_checkpoint_result.json`
- `warning_checkpoint_result.json`
- `validation_summary.json`
- `data_docs/index.html`

`validation_summary.json` is the compact release verdict. The two checkpoint JSON files keep the full suite-level result structure.

`data_docs/index.html` is currently a lightweight HTML summary page generated by `run_validation.py`. The runtime code does not build a full Great Expectations Data Docs site.

## Exit Semantics

The exit code is determined after the checkpoint payloads are written:

- if `fail_on_critical: true` and the critical checkpoint failed, the process returns `1`
- if `fail_on_warning: true` and the warning checkpoint failed, the process also returns `1`
- otherwise it returns `0`

This means output artifacts are still available for inspection even when validation blocks the release.

## Boundary With Pipeline Validation

This validator is separate from the validation documented in [Pipeline Validation](../pipeline-validation/overview.md).

The Snakemake-integrated layer produces KEGG-linked JSON reports inside the pipeline DAG. The GX layer consumes the finished results tree after the DAG is complete and applies expectation suites plus optional regression comparison.

## Related Pages

- [Expectation Suites](expectation-suites.md)
- [Validation Modes](validation-modes.md)
- [Configuration Reference](configuration.md)
- [Baseline Management](baseline-management.md)
- [Testing](testing.md)
