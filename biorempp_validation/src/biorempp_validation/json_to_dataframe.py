from __future__ import annotations

from collections import OrderedDict
from typing import Any

import pandas as pd


def _has_keys(payload: dict[str, Any], required_keys: list[str]) -> bool:
    return all(key in payload for key in required_keys)


def build_analysis_critical_df(
    database_df: pd.DataFrame,
    analysis_payloads: dict[str, dict[str, Any]],
    expected_columns: list[str],
) -> pd.DataFrame:
    basic = analysis_payloads["basic_statistics"]
    compound = analysis_payloads["compound_statistics"]
    ko = analysis_payloads["ko_statistics"]
    enzyme = analysis_payloads["enzyme_statistics"]
    gene = analysis_payloads["gene_statistics"]
    crosstab = analysis_payloads["crosstab_statistics"]
    metadata = analysis_payloads["database_metadata"]
    executive = analysis_payloads["executive_summary"]
    complete = analysis_payloads["complete_analysis"]

    missing_values = basic.get("missing_values", {})
    optional_na_columns = {"ec", "reaction", "reaction_description"}
    reaction_description_consistent_with_reaction = bool(
        (
            (database_df["reaction"].isna() | (database_df["reaction"].astype(str).str.strip().str.upper() == "NA"))
            | (
                ~database_df["reaction_description"].isna()
                & (database_df["reaction_description"].astype(str).str.strip() != "")
                & (database_df["reaction_description"].astype(str).str.strip().str.upper() != "NA")
            )
        ).all()
    ) if {"reaction", "reaction_description"}.issubset(database_df.columns) else False
    all_missing_zero = (
        all(float(value) == 0 for key, value in missing_values.items() if key not in optional_na_columns)
        if missing_values
        else False
    )

    row = {
        "basic_required_keys_present": _has_keys(
            basic, ["total_entries", "total_columns", "column_names", "missing_values"]
        ),
        "compound_required_keys_present": _has_keys(
            compound, ["total_unique_compounds", "top_20_compounds", "class_distribution_summary"]
        ),
        "ko_required_keys_present": _has_keys(ko, ["total_unique_ko", "top_20_ko"]),
        "enzyme_required_keys_present": _has_keys(enzyme, ["total_unique_enzymes", "top_30_enzymes"]),
        "gene_required_keys_present": _has_keys(
            gene, ["total_unique_genesymbols", "total_unique_genenames", "top_20_genesymbols", "top_20_genenames"]
        ),
        "crosstab_required_keys_present": _has_keys(
            crosstab,
            ["top_20_class_agency_combinations", "top_20_enzyme_class_combinations", "top_10_classes_by_ko_diversity"],
        ),
        "metadata_required_keys_present": _has_keys(metadata, ["database_info", "data_sources", "schema", "data_quality"]),
        "executive_required_keys_present": _has_keys(executive, ["overview", "highlights", "coverage"]),
        "complete_required_keys_present": _has_keys(
            complete,
            [
                "metadata",
                "basic_stats",
                "compound_stats",
                "ko_stats",
                "enzyme_stats",
                "gene_stats",
                "crosstab_stats",
                "executive_summary",
            ],
        ),
        "basic_total_entries": int(basic.get("total_entries", -1)),
        "basic_total_columns": int(basic.get("total_columns", -1)),
        "basic_expected_columns_match": list(basic.get("column_names", [])) == expected_columns,
        "basic_all_missing_values_zero": all_missing_zero,
        "reaction_description_consistent_with_reaction": reaction_description_consistent_with_reaction,
    }
    return pd.DataFrame([row])


def build_analysis_warning_df(analysis_payloads: dict[str, dict[str, Any]]) -> pd.DataFrame:
    compound = analysis_payloads["compound_statistics"]
    ko = analysis_payloads["ko_statistics"]
    enzyme = analysis_payloads["enzyme_statistics"]
    executive = analysis_payloads["executive_summary"]
    crosstab = analysis_payloads["crosstab_statistics"]

    executive_strings = [
        executive.get("highlights", {}).get("most_represented_class"),
        executive.get("highlights", {}).get("most_frequent_enzyme"),
    ]
    executive_text_fields_non_empty = all(isinstance(v, str) and v.strip() for v in executive_strings)

    crosstab_required_sections_present = _has_keys(
        crosstab,
        ["top_20_class_agency_combinations", "top_20_enzyme_class_combinations", "top_10_classes_by_ko_diversity"],
    )

    row = {
        "compound_top_n": len(compound.get("top_20_compounds", {}).get("compound_ids", [])),
        "ko_top_n": len(ko.get("top_20_ko", {}).get("ko_ids", [])),
        "enzyme_top_n": len(enzyme.get("top_30_enzymes", {}).get("enzyme_names", [])),
        "executive_text_fields_non_empty": executive_text_fields_non_empty,
        "crosstab_required_sections_present": crosstab_required_sections_present,
        "reaction_description_fill_rate_percent": (
            float(
                analysis_payloads.get("database_metadata", {})
                .get("data_quality", {})
                .get("completeness", {})
                .get("reaction_description", 0.0)
            )
        ),
    }
    return pd.DataFrame([row])


def build_kegg_metadata_df(kegg_release: dict[str, Any]) -> pd.DataFrame:
    row = {
        "release_text": kegg_release.get("release_text"),
        "parsed_version": kegg_release.get("parsed_version"),
        "retrieved_at_utc": kegg_release.get("retrieved_at_utc"),
        "source_url": kegg_release.get("source_url"),
        "raw_response_len": len(kegg_release.get("raw_response", []))
        if isinstance(kegg_release.get("raw_response"), list)
        else 0,
    }
    return pd.DataFrame([row])


def build_pipeline_reports_critical_df(
    keys_consistency: dict[str, Any],
    links_groundtruth_policy: dict[str, Any],
    workflow_summary: dict[str, Any],
) -> pd.DataFrame:
    na_justified = keys_consistency["results"]["all_remaining_na_justified"]
    policy_metrics = links_groundtruth_policy["policy_aware_metrics"]
    artifacts = workflow_summary["artifacts"]
    hashes_present = all(
        isinstance(v.get("sha256"), str) and len(v["sha256"]) == 64
        for v in artifacts.values()
    )
    return pd.DataFrame([{
        "keys_consistency_na_justified": bool(na_justified),
        "links_policy_union_rate_percent": float(policy_metrics["policy_union_rate_percent"]),
        "links_no_policy_support": int(policy_metrics["no_policy_support"]),
        "workflow_artifact_hashes_present": hashes_present,
    }])


def _ordered_dict_from_series(
    series: pd.Series,
    key_name: str,
    value_name: str,
    top_n: int | None = None,
    secondary_keys: list[str] | None = None,
) -> OrderedDict:
    df = series.reset_index(name=value_name).rename(columns={"index": key_name})
    sort_cols = [value_name, key_name]
    ascending = [False, True]
    if secondary_keys:
        sort_cols = [value_name, *secondary_keys]
        ascending = [False, *([True] * len(secondary_keys))]
    df = df.sort_values(sort_cols, ascending=ascending)
    if top_n is not None:
        df = df.head(top_n)
    return OrderedDict((str(row[key_name]), int(row[value_name])) for _, row in df.iterrows())


def _top_compounds_exact(database_df: pd.DataFrame, top_n: int) -> dict[str, list[Any]]:
    counts_df = (
        database_df.groupby("cpd")
        .size()
        .reset_index(name="frequency")
        .sort_values(["frequency", "cpd"], ascending=[False, True])
        .head(top_n)
    )
    compound_names = (
        database_df[["cpd", "compoundname"]]
        .drop_duplicates()
        .sort_values(["cpd", "compoundname"], ascending=[True, True])
        .drop_duplicates(subset=["cpd"], keep="first")
    )
    merged = counts_df.merge(compound_names, on="cpd", how="left")
    return {
        "compound_ids": merged["cpd"].tolist(),
        "compound_names": merged["compoundname"].tolist(),
        "frequencies": [int(v) for v in merged["frequency"].tolist()],
    }


def _top_ko_exact(database_df: pd.DataFrame, top_n: int) -> dict[str, list[Any]]:
    ko_df = (
        database_df.groupby("ko")
        .agg(frequency=("ko", "size"), unique_compounds_per_ko=("cpd", "nunique"))
        .reset_index()
        .sort_values(["frequency", "ko"], ascending=[False, True])
        .head(top_n)
    )
    return {
        "ko_ids": ko_df["ko"].tolist(),
        "frequencies": [int(v) for v in ko_df["frequency"].tolist()],
        "unique_compounds_per_ko": [int(v) for v in ko_df["unique_compounds_per_ko"].tolist()],
    }


def _top_enzymes_exact(database_df: pd.DataFrame, top_n: int) -> dict[str, list[Any]]:
    enzyme_df = (
        database_df.groupby("enzyme_activity")
        .agg(frequency=("enzyme_activity", "size"), unique_compounds=("cpd", "nunique"), unique_ko=("ko", "nunique"))
        .reset_index()
        .sort_values(["frequency", "enzyme_activity"], ascending=[False, True])
        .head(top_n)
    )
    return {
        "enzyme_names": enzyme_df["enzyme_activity"].tolist(),
        "frequencies": [int(v) for v in enzyme_df["frequency"].tolist()],
        "unique_compounds": [int(v) for v in enzyme_df["unique_compounds"].tolist()],
        "unique_ko": [int(v) for v in enzyme_df["unique_ko"].tolist()],
    }


def _top_genes_exact(database_df: pd.DataFrame, top_n: int) -> dict[str, dict[str, list[Any]]]:
    symbols_df = (
        database_df.groupby("genesymbol")
        .size()
        .reset_index(name="frequency")
        .sort_values(["frequency", "genesymbol"], ascending=[False, True])
        .head(top_n)
    )
    names_df = (
        database_df.groupby("genename")
        .size()
        .reset_index(name="frequency")
        .sort_values(["frequency", "genename"], ascending=[False, True])
        .head(top_n)
    )
    return {
        "top_20_genesymbols": {
            "symbols": symbols_df["genesymbol"].tolist(),
            "frequencies": [int(v) for v in symbols_df["frequency"].tolist()],
        },
        "top_20_genenames": {
            "names": names_df["genename"].tolist(),
            "frequencies": [int(v) for v in names_df["frequency"].tolist()],
        },
    }


def _crosstab_exact(database_df: pd.DataFrame) -> dict[str, Any]:
    class_agency_df = (
        database_df[["compoundclass", "referenceAG", "cpd"]]
        .drop_duplicates()
        .groupby(["compoundclass", "referenceAG"])
        .size()
        .reset_index(name="compound_counts")
        .sort_values(["compound_counts", "compoundclass", "referenceAG"], ascending=[False, True, True])
        .head(20)
    )
    enzyme_class_df = (
        database_df.groupby(["compoundclass", "enzyme_activity"])
        .size()
        .reset_index(name="counts")
        .sort_values(["counts", "compoundclass", "enzyme_activity"], ascending=[False, True, True])
        .head(20)
    )
    ko_diversity_df = (
        database_df.groupby("compoundclass")["ko"]
        .nunique()
        .reset_index(name="unique_ko_counts")
        .sort_values(["unique_ko_counts", "compoundclass"], ascending=[False, True])
        .head(10)
    )

    return {
        "top_20_class_agency_combinations": {
            "compound_classes": class_agency_df["compoundclass"].tolist(),
            "agencies": class_agency_df["referenceAG"].tolist(),
            "compound_counts": [int(v) for v in class_agency_df["compound_counts"].tolist()],
        },
        "top_20_enzyme_class_combinations": {
            "compound_classes": enzyme_class_df["compoundclass"].tolist(),
            "enzymes": enzyme_class_df["enzyme_activity"].tolist(),
            "counts": [int(v) for v in enzyme_class_df["counts"].tolist()],
        },
        "top_10_classes_by_ko_diversity": {
            "compound_classes": ko_diversity_df["compoundclass"].tolist(),
            "unique_ko_counts": [int(v) for v in ko_diversity_df["unique_ko_counts"].tolist()],
        },
    }


def build_analysis_exact_df(
    database_df: pd.DataFrame,
    analysis_payloads: dict[str, dict[str, Any]],
    kegg_release: dict[str, Any],
    expected_columns: list[str],
    observed_kegg_release: dict[str, Any] | None = None,
) -> pd.DataFrame:
    basic = analysis_payloads["basic_statistics"]
    compound = analysis_payloads["compound_statistics"]
    ko = analysis_payloads["ko_statistics"]
    enzyme = analysis_payloads["enzyme_statistics"]
    gene = analysis_payloads["gene_statistics"]
    crosstab = analysis_payloads["crosstab_statistics"]
    metadata = analysis_payloads["database_metadata"]
    executive = analysis_payloads["executive_summary"]

    required_cols = set(expected_columns)
    if not required_cols.issubset(set(database_df.columns)):
        return pd.DataFrame(
            [
                {
                    "basic_stats_exact_match": False,
                    "basic_expected_columns_exact_match": False,
                    "compound_total_exact_match": False,
                    "compound_class_distribution_exact_match": False,
                    "compound_agency_distribution_exact_match": False,
                    "compound_top20_exact_match": False,
                    "ko_total_exact_match": False,
                    "ko_top20_exact_match": False,
                    "enzyme_total_exact_match": False,
                    "enzyme_top30_exact_match": False,
                    "gene_totals_exact_match": False,
                    "gene_top20_exact_match": False,
                    "crosstab_exact_match": False,
                    "executive_summary_exact_match": False,
                    "metadata_kegg_exact_match": False,
                }
            ]
        )

    observed_basic = {
        "total_entries": int(len(database_df)),
        "total_columns": int(database_df.shape[1]),
        "column_names": list(database_df.columns),
        "unique_compounds": int(database_df["cpd"].nunique()),
        "unique_ko_entries": int(database_df["ko"].nunique()),
        "unique_compound_classes": int(database_df["compoundclass"].nunique()),
        "unique_gene_symbols": int(database_df["genesymbol"].nunique()),
        "unique_gene_names": int(database_df["genename"].nunique()),
        "unique_enzyme_activities": int(database_df["enzyme_activity"].nunique()),
        "unique_reference_agencies": int(database_df["referenceAG"].nunique()),
        "missing_values": {column: int(database_df[column].isna().sum()) for column in expected_columns},
    }
    expected_basic = {
        "total_entries": int(basic.get("total_entries", -1)),
        "total_columns": int(basic.get("total_columns", -1)),
        "column_names": list(basic.get("column_names", [])),
        "unique_compounds": int(basic.get("unique_compounds", -1)),
        "unique_ko_entries": int(basic.get("unique_ko_entries", -1)),
        "unique_compound_classes": int(basic.get("unique_compound_classes", -1)),
        "unique_gene_symbols": int(basic.get("unique_gene_symbols", -1)),
        "unique_gene_names": int(basic.get("unique_gene_names", -1)),
        "unique_enzyme_activities": int(basic.get("unique_enzyme_activities", -1)),
        "unique_reference_agencies": int(basic.get("unique_reference_agencies", -1)),
        "missing_values": {str(k): int(v) for k, v in basic.get("missing_values", {}).items()},
    }

    observed_compounds_per_class = _ordered_dict_from_series(
        database_df[["cpd", "compoundclass"]].drop_duplicates().groupby("compoundclass").size(),
        key_name="compoundclass",
        value_name="count",
    )
    observed_compounds_per_agency = _ordered_dict_from_series(
        database_df[["cpd", "referenceAG"]].drop_duplicates().groupby("referenceAG").size(),
        key_name="referenceAG",
        value_name="count",
    )
    expected_compounds_per_class = OrderedDict(
        (str(k), int(v)) for k, v in (compound.get("compounds_per_class", {}) or {}).items()
    )
    expected_compounds_per_agency = OrderedDict(
        (str(k), int(v)) for k, v in (compound.get("compounds_per_agency", {}) or {}).items()
    )

    observed_ko_total = observed_basic["unique_ko_entries"]
    observed_enzyme_total = observed_basic["unique_enzyme_activities"]
    observed_gene_symbol_total = observed_basic["unique_gene_symbols"]
    observed_gene_name_total = observed_basic["unique_gene_names"]

    observed_top_compounds = _top_compounds_exact(database_df, top_n=20)
    observed_top_ko = _top_ko_exact(database_df, top_n=20)
    observed_top_enzymes = _top_enzymes_exact(database_df, top_n=30)
    observed_top_genes = _top_genes_exact(database_df, top_n=20)
    observed_crosstab = _crosstab_exact(database_df)

    expected_top_compounds = compound.get("top_20_compounds", {})
    expected_top_ko = ko.get("top_20_ko", {})
    expected_top_enzymes = enzyme.get("top_30_enzymes", {})
    expected_top_genes = {
        "top_20_genesymbols": gene.get("top_20_genesymbols", {}),
        "top_20_genenames": gene.get("top_20_genenames", {}),
    }
    expected_crosstab = crosstab

    computed_overview = {
        "total_entries": observed_basic["total_entries"],
        "unique_compounds": observed_basic["unique_compounds"],
        "unique_ko_entries": observed_basic["unique_ko_entries"],
        "unique_enzyme_activities": observed_basic["unique_enzyme_activities"],
        "unique_compound_classes": observed_basic["unique_compound_classes"],
    }
    top_class_name = next(iter(observed_compounds_per_class.keys())) if observed_compounds_per_class else ""
    top_class_count = next(iter(observed_compounds_per_class.values())) if observed_compounds_per_class else 0
    top_enzyme_name = observed_top_enzymes["enzyme_names"][0] if observed_top_enzymes["enzyme_names"] else ""
    top_enzyme_count = observed_top_enzymes["frequencies"][0] if observed_top_enzymes["frequencies"] else 0
    computed_highlights = {
        "most_represented_class": top_class_name,
        "compounds_in_top_class": int(top_class_count),
        "most_frequent_enzyme": top_enzyme_name,
        "enzyme_frequency": int(top_enzyme_count),
        "total_classes": int(len(observed_compounds_per_class)),
    }
    computed_coverage = {
        "environmental_agencies": observed_basic["unique_reference_agencies"],
        "compound_classes_covered": observed_basic["unique_compound_classes"],
        "enzyme_types_identified": observed_basic["unique_enzyme_activities"],
        "gene_symbols_mapped": observed_basic["unique_gene_symbols"],
    }
    expected_metadata_kegg = metadata.get("data_sources", {}).get("kegg_release", {})
    metadata_kegg_exact_match = expected_metadata_kegg == kegg_release
    if observed_kegg_release is not None:
        metadata_kegg_exact_match = metadata_kegg_exact_match and observed_kegg_release == kegg_release

    row = {
        "basic_stats_exact_match": observed_basic == expected_basic,
        "basic_expected_columns_exact_match": observed_basic["column_names"] == expected_columns,
        "compound_total_exact_match": int(compound.get("total_unique_compounds", -1)) == observed_basic["unique_compounds"],
        "compound_class_distribution_exact_match": observed_compounds_per_class == expected_compounds_per_class,
        "compound_agency_distribution_exact_match": observed_compounds_per_agency == expected_compounds_per_agency,
        "compound_top20_exact_match": observed_top_compounds == expected_top_compounds,
        "ko_total_exact_match": observed_ko_total == int(ko.get("total_unique_ko", -1)),
        "ko_top20_exact_match": observed_top_ko == expected_top_ko,
        "enzyme_total_exact_match": observed_enzyme_total == int(enzyme.get("total_unique_enzymes", -1)),
        "enzyme_top30_exact_match": observed_top_enzymes == expected_top_enzymes,
        "gene_totals_exact_match": (
            observed_gene_symbol_total == int(gene.get("total_unique_genesymbols", -1))
            and observed_gene_name_total == int(gene.get("total_unique_genenames", -1))
        ),
        "gene_top20_exact_match": observed_top_genes == expected_top_genes,
        "crosstab_exact_match": observed_crosstab == expected_crosstab,
        "executive_summary_exact_match": (
            executive.get("overview", {}) == computed_overview
            and executive.get("highlights", {}) == computed_highlights
            and executive.get("coverage", {}) == computed_coverage
        ),
        "metadata_kegg_exact_match": metadata_kegg_exact_match,
    }
    return pd.DataFrame([row])
