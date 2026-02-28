from __future__ import annotations

import json
from pathlib import Path
from typing import Any

import great_expectations as gx
from great_expectations.core.expectation_suite import ExpectationSuite
import pandas as pd
import yaml


def create_context() -> gx.EphemeralDataContext:
    return gx.get_context(mode="ephemeral")


def create_pandas_datasource(context: gx.EphemeralDataContext, name: str = "biorempp_validation"):
    return context.data_sources.add_or_update_pandas(name=name)


def load_expectation_suite(path: Path) -> ExpectationSuite:
    with path.open("r", encoding="utf-8") as handle:
        payload = json.load(handle)
    return ExpectationSuite(**payload)


def load_checkpoint_config(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as handle:
        return yaml.safe_load(handle)


def run_suite_on_dataframe(
    datasource,
    dataframe: pd.DataFrame,
    suite: ExpectationSuite,
    asset_name: str,
) -> dict[str, Any]:
    batch = datasource.read_dataframe(dataframe=dataframe, asset_name=asset_name)
    result = batch.validate(suite, result_format="SUMMARY")
    return result.to_json_dict()
