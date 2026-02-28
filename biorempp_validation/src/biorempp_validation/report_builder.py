from __future__ import annotations

from datetime import datetime, timezone
from typing import Any


def _extract_failed_expectations(checkpoint_payload: dict[str, Any], severity: str) -> list[dict[str, Any]]:
    failed: list[dict[str, Any]] = []
    for suite_result in checkpoint_payload.get("suite_results", []):
        suite_name = suite_result["suite_name"]
        dataset = suite_result["dataset"]
        for expectation_result in suite_result.get("result", {}).get("results", []):
            if expectation_result.get("success", False):
                continue
            config = expectation_result.get("expectation_config", {})
            failed.append(
                {
                    "severity": severity,
                    "suite": suite_name,
                    "dataset": dataset,
                    "expectation_type": config.get("type"),
                    "kwargs": config.get("kwargs", {}),
                }
            )
    return failed


def build_validation_summary(
    critical_payload: dict[str, Any],
    warning_payload: dict[str, Any],
) -> dict[str, Any]:
    critical_failed = _extract_failed_expectations(critical_payload, severity="critical")
    warning_failed = _extract_failed_expectations(warning_payload, severity="warning")

    summary = {
        "run_timestamp_utc": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "critical_checkpoint_success": bool(critical_payload.get("success", False)),
        "warning_checkpoint_success": bool(warning_payload.get("success", False)),
        "counts": {
            "critical_failed_expectations": len(critical_failed),
            "warning_failed_expectations": len(warning_failed),
        },
        "failed_expectations": critical_failed + warning_failed,
        "recommendation": _build_recommendation(critical_failed, warning_failed),
    }
    return summary


def _build_recommendation(critical_failed: list[dict[str, Any]], warning_failed: list[dict[str, Any]]) -> str:
    if critical_failed:
        return "Critical expectations failed. Block release and fix data contract violations before publishing."
    if warning_failed:
        return "No critical failures. Review warning-level drift and decide whether to recalibrate thresholds."
    return "All critical and warning expectations passed."
