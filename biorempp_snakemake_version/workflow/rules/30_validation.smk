from os.path import join

KEGG_LINK_CACHE_DIR = join(WORK_DIR, "kegg_link_cache")
KEGG_LINK_CACHE = {name: join(KEGG_LINK_CACHE_DIR, f"{name}.tsv")
                   for name in ("ko_ec", "ko_reaction", "cpd_ec", "cpd_reaction", "ec_reaction")}


rule fetch_kegg_link_cache:
    output:
        ko_ec        = KEGG_LINK_CACHE["ko_ec"],
        ko_reaction  = KEGG_LINK_CACHE["ko_reaction"],
        cpd_ec       = KEGG_LINK_CACHE["cpd_ec"],
        cpd_reaction = KEGG_LINK_CACHE["cpd_reaction"],
        ec_reaction  = KEGG_LINK_CACHE["ec_reaction"],
    params:
        base_url              = config["kegg"]["base_url"],
        ko_ec_endpoint        = config["kegg"]["endpoints"]["ko_ec_links"],
        ko_reaction_endpoint  = config["kegg"]["endpoints"]["ko_reaction_links"],
        cpd_ec_endpoint       = config["kegg"]["endpoints"]["compound_ec_links"],
        cpd_reaction_endpoint = config["kegg"]["endpoints"]["compound_reaction_links"],
        ec_reaction_endpoint  = config["kegg"]["endpoints"]["ec_reaction_links"],
        output_dir            = KEGG_LINK_CACHE_DIR,
    log:
        join(PATHS["logs_dir"], "fetch_kegg_link_cache.log")
    shell:
        (
            "python3 workflow/scripts/validation/cache_kegg_links.py "
            "--base-url {params.base_url} "
            "--ko-ec-endpoint {params.ko_ec_endpoint} "
            "--ko-reaction-endpoint {params.ko_reaction_endpoint} "
            "--cpd-ec-endpoint {params.cpd_ec_endpoint} "
            "--cpd-reaction-endpoint {params.cpd_reaction_endpoint} "
            "--ec-reaction-endpoint {params.ec_reaction_endpoint} "
            "--output-dir {params.output_dir} "
            "> {log} 2>&1"
        )


rule validate_keys_consistency:
    input:
        csv          = join(RESULTS_DIR, "database", OUTPUTS["database_csv"]),
        ko_ec        = KEGG_LINK_CACHE["ko_ec"],
        ko_reaction  = KEGG_LINK_CACHE["ko_reaction"],
        cpd_ec       = KEGG_LINK_CACHE["cpd_ec"],
        cpd_reaction = KEGG_LINK_CACHE["cpd_reaction"],
        ec_reaction  = KEGG_LINK_CACHE["ec_reaction"],
    output:
        join(RESULTS_DIR, "metadata", "keys_consistency_report.json")
    params:
        config_file            = "config/config.yaml",
        csv_delimiter          = OUTPUTS["database_csv_delimiter"],
        max_invalid_line_ratio = config["validation"]["max_invalid_line_ratio"],
    log:
        join(PATHS["logs_dir"], "validate_keys_consistency.log")
    shell:
        (
            "python3 workflow/scripts/validation/01_validate_keys_consistency_api.py "
            "--database-csv {input.csv} "
            "--csv-delimiter \"{params.csv_delimiter}\" "
            "--ko-ec-cache {input.ko_ec} "
            "--ko-reaction-cache {input.ko_reaction} "
            "--cpd-ec-cache {input.cpd_ec} "
            "--cpd-reaction-cache {input.cpd_reaction} "
            "--ec-reaction-cache {input.ec_reaction} "
            "--output {output} "
            "--config {params.config_file} "
            "--max-invalid-line-ratio {params.max_invalid_line_ratio} "
            "> {log} 2>&1"
        )


rule validate_links_groundtruth_policy:
    input:
        csv          = join(RESULTS_DIR, "database", OUTPUTS["database_csv"]),
        ko_ec        = KEGG_LINK_CACHE["ko_ec"],
        ko_reaction  = KEGG_LINK_CACHE["ko_reaction"],
        cpd_ec       = KEGG_LINK_CACHE["cpd_ec"],
        cpd_reaction = KEGG_LINK_CACHE["cpd_reaction"],
        ec_reaction  = KEGG_LINK_CACHE["ec_reaction"],
    output:
        join(RESULTS_DIR, "metadata", "links_groundtruth_policy_report.json")
    params:
        config_file            = "config/config.yaml",
        csv_delimiter          = OUTPUTS["database_csv_delimiter"],
        max_invalid_line_ratio = config["validation"]["max_invalid_line_ratio"],
    log:
        join(PATHS["logs_dir"], "validate_links_groundtruth_policy.log")
    shell:
        (
            "python3 workflow/scripts/validation/02_validate_links_groundtruth_policy_api.py "
            "--database-csv {input.csv} "
            "--csv-delimiter \"{params.csv_delimiter}\" "
            "--ko-ec-cache {input.ko_ec} "
            "--ko-reaction-cache {input.ko_reaction} "
            "--cpd-ec-cache {input.cpd_ec} "
            "--cpd-reaction-cache {input.cpd_reaction} "
            "--ec-reaction-cache {input.ec_reaction} "
            "--output {output} "
            "--config {params.config_file} "
            "--max-invalid-line-ratio {params.max_invalid_line_ratio} "
            "> {log} 2>&1"
        )
