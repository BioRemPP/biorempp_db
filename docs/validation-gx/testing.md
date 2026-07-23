<!--
Page status: verified
Audience: maintainers, reviewers, advanced operators
Applies to: GX
Version scope: GX validator v1.1.0
Last verified on: 2026-06-24
Primary sources:
- biorempp_snakemake_version/env/docker-compose.yml
- biorempp_validation/pyproject.toml
- biorempp_validation/env/Dockerfile
- biorempp_validation/tests/conftest.py
- biorempp_validation/tests/test_happy_path.py
- biorempp_validation/tests/test_dual_mode_validation.py
- biorempp_validation/tests/test_missing_files.py
- biorempp_validation/tests/test_schema_break.py
- biorempp_validation/tests/test_kegg_metadata.py
- biorempp_validation/tests/test_warning_only_drift.py
-->

# Testing

The GX validator ships a pytest suite under `biorempp_validation/tests/`. These tests exercise the validator as an integration-style Python entrypoint rather than as isolated unit mocks.

## Canonical Test Command

The verified containerized command path is:

```powershell
docker compose -f biorempp_snakemake_version/env/docker-compose.yml run --rm validation python -m pytest biorempp_validation/tests -q
```

This uses the same `validation` service that runs the packaged CLI, so the tests execute against the pinned validator environment declared by:

- `biorempp_validation/env/Dockerfile`
- `biorempp_validation/requirements-dev.lock.txt`

## Test Harness Design

The fixtures in `tests/conftest.py` build temporary test environments by:

- copying the real Snakemake `results/` tree into a temp directory
- copying the real regression baseline into a temp directory
- rewriting `validation.yaml` so that all runtime paths point at those temp copies

This means the tests exercise the validator against repository-realistic artifacts, not against synthetic toy schemas alone.

## Invocation Style

The tests call the validator in-process through:

- `from biorempp_validation.run_validation import main`

They do not shell out to a subprocess. Each test passes a temporary `--config` path directly into `main([...])`.

## Test Coverage By File

| Test file | Main coverage |
|---|---|
| `test_happy_path.py` | passing end-to-end run and presence of both analysis modes in the critical checkpoint payload |
| `test_dual_mode_validation.py` | isolation between `internal_consistency` and `regression_detection`, missing baseline preflight failure, and rejection of legacy `strict_exact` |
| `test_missing_files.py` | current-results preflight failure when required files are absent |
| `test_schema_break.py` | critical schema failure after dropping the `ko` column from the CSV |
| `test_kegg_metadata.py` | KEGG metadata contract failure when `source_url` is missing |
| `test_warning_only_drift.py` | warning-threshold behavior, shipped drift-window coverage, and blocking on warning failure when configured |

## What The Tests Inspect

The current tests validate behavior through the same public artifacts the validator writes in normal operation:

- `validation_summary.json`
- `critical_checkpoint_result.json`
- `warning_checkpoint_result.json`

This keeps the test contract aligned with the operator-facing outputs.

## Why These Tests Matter

The GX validator has several moving parts that are easy to oversimplify in prose:

- mode-specific suite wiring
- preflight failure behavior
- config-driven overrides
- blocking policy for warnings
- baseline isolation from current-artifact checks

The pytest suite is the strongest executable evidence that those behaviors are wired correctly.

## Related Pages

- [Architecture](architecture.md)
- [Validation Modes](validation-modes.md)
- [Configuration Reference](configuration.md)
- [Baseline Management](baseline-management.md)
