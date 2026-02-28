from __future__ import annotations

import json

from biorempp_validation.loaders import load_json
from biorempp_validation.run_validation import main
from biorempp_validation.settings import load_settings


def test_kegg_metadata_missing_source_url_fails(config_path, sample_results_root):
    kegg_path = sample_results_root / "metadata" / "kegg_release.json"
    payload = load_json(kegg_path)
    payload.pop("source_url", None)
    kegg_path.write_text(json.dumps(payload, indent=2), encoding="utf-8")

    exit_code = main(["--config", str(config_path)])
    assert exit_code == 1

    settings = load_settings(config_path)
    summary = json.loads((settings.output_dir / "validation_summary.json").read_text(encoding="utf-8"))
    metadata_failures = [item for item in summary["failed_expectations"] if item["suite"] == "metadata_kegg_critical"]
    assert metadata_failures
