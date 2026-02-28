from __future__ import annotations

import pandas as pd


def _safe_nunique(df: pd.DataFrame, column: str) -> int:
    if column not in df.columns:
        return -1
    return int(df[column].nunique())


def _safe_group_max_nunique(df: pd.DataFrame, group_col: str, value_col: str) -> int:
    if group_col not in df.columns or value_col not in df.columns:
        return -1
    return int(df.groupby(group_col)[value_col].nunique().max())


def build_cross_consistency_df(database_df: pd.DataFrame, basic_stats: dict) -> pd.DataFrame:
    metrics = [
        ("total_entries", int(len(database_df)), int(basic_stats.get("total_entries", -1))),
        ("total_columns", int(database_df.shape[1]), int(basic_stats.get("total_columns", -1))),
        ("unique_compounds", _safe_nunique(database_df, "cpd"), int(basic_stats.get("unique_compounds", -1))),
        ("unique_ko_entries", _safe_nunique(database_df, "ko"), int(basic_stats.get("unique_ko_entries", -1))),
        (
            "unique_compound_classes",
            _safe_nunique(database_df, "compoundclass"),
            int(basic_stats.get("unique_compound_classes", -1)),
        ),
        (
            "unique_reference_agencies",
            _safe_nunique(database_df, "referenceAG"),
            int(basic_stats.get("unique_reference_agencies", -1)),
        ),
        ("unique_gene_symbols", _safe_nunique(database_df, "genesymbol"), int(basic_stats.get("unique_gene_symbols", -1))),
        ("unique_gene_names", _safe_nunique(database_df, "genename"), int(basic_stats.get("unique_gene_names", -1))),
        (
            "unique_enzyme_activities",
            _safe_nunique(database_df, "enzyme_activity"),
            int(basic_stats.get("unique_enzyme_activities", -1)),
        ),
        (
            "max_compoundnames_per_cpd",
            _safe_group_max_nunique(database_df, "cpd", "compoundname"),
            1,
        ),
        (
            "max_genesymbols_per_ko",
            _safe_group_max_nunique(database_df, "ko", "genesymbol"),
            1,
        ),
        (
            "max_genenames_per_ko",
            _safe_group_max_nunique(database_df, "ko", "genename"),
            1,
        ),
    ]
    return pd.DataFrame(metrics, columns=["metric", "csv_value", "stats_value"])
