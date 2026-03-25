from os.path import join

rule validate_keys_consistency:
    input:
        csv = join(RESULTS_DIR, "database", OUTPUTS["database_csv"])
    output:
        join(RESULTS_DIR, "metadata", "keys_consistency_report.json")
    params:
        config_file = "config/config.yaml",
        base_url = config["kegg"]["base_url"],
        ko_ec_endpoint = config["kegg"]["endpoints"]["ko_ec_links"],
        ko_reaction_endpoint = config["kegg"]["endpoints"]["ko_reaction_links"],
        cpd_ec_endpoint = config["kegg"]["endpoints"]["compound_ec_links"],
        cpd_reaction_endpoint = config["kegg"]["endpoints"]["compound_reaction_links"],
        ec_reaction_endpoint = config["kegg"]["endpoints"]["ec_reaction_links"]
    log:
        join(PATHS["logs_dir"], "validate_keys_consistency.log")
    shell:
        (
            "python3 workflow/scripts/validation/01_validate_keys_consistency_api.py "
            "--database-csv {input.csv} "
            "--base-url {params.base_url} "
            "--ko-ec-endpoint {params.ko_ec_endpoint} "
            "--ko-reaction-endpoint {params.ko_reaction_endpoint} "
            "--cpd-ec-endpoint {params.cpd_ec_endpoint} "
            "--cpd-reaction-endpoint {params.cpd_reaction_endpoint} "
            "--ec-reaction-endpoint {params.ec_reaction_endpoint} "
            "--output {output} "
            "--config {params.config_file} "
            "> {log} 2>&1"
        )


rule validate_links_groundtruth_policy:
    input:
        csv = join(RESULTS_DIR, "database", OUTPUTS["database_csv"])
    output:
        join(RESULTS_DIR, "metadata", "links_groundtruth_policy_report.json")
    params:
        config_file = "config/config.yaml",
        base_url = config["kegg"]["base_url"],
        ko_ec_endpoint = config["kegg"]["endpoints"]["ko_ec_links"],
        ko_reaction_endpoint = config["kegg"]["endpoints"]["ko_reaction_links"],
        cpd_ec_endpoint = config["kegg"]["endpoints"]["compound_ec_links"],
        cpd_reaction_endpoint = config["kegg"]["endpoints"]["compound_reaction_links"],
        ec_reaction_endpoint = config["kegg"]["endpoints"]["ec_reaction_links"]
    log:
        join(PATHS["logs_dir"], "validate_links_groundtruth_policy.log")
    shell:
        (
            "python3 workflow/scripts/validation/02_validate_links_groundtruth_policy_api.py "
            "--database-csv {input.csv} "
            "--base-url {params.base_url} "
            "--ko-ec-endpoint {params.ko_ec_endpoint} "
            "--ko-reaction-endpoint {params.ko_reaction_endpoint} "
            "--cpd-ec-endpoint {params.cpd_ec_endpoint} "
            "--cpd-reaction-endpoint {params.cpd_reaction_endpoint} "
            "--ec-reaction-endpoint {params.ec_reaction_endpoint} "
            "--output {output} "
            "--config {params.config_file} "
            "> {log} 2>&1"
        )
