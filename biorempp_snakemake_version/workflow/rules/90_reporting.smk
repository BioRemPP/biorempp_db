from os.path import join

rule build_run_report:
    input:
        csv = join(RESULTS_DIR, "database", OUTPUTS["database_csv"]),
        xlsx = join(RESULTS_DIR, "database", OUTPUTS["database_xlsx"]),
        metadata = join(RESULTS_DIR, "analysis", "database_metadata.json"),
        complete = join(RESULTS_DIR, "analysis", "complete_analysis.json"),
        kegg = join(RESULTS_DIR, "metadata", "kegg_release.json"),
        keys_consistency = join(RESULTS_DIR, "metadata", "keys_consistency_report.json"),
        links_groundtruth_policy = join(RESULTS_DIR, "metadata", "links_groundtruth_policy_report.json")
    output:
        join(RESULTS_DIR, "reports", "workflow_summary.json")
    params:
        config_file = "config/config.yaml",
        version = config["version"]
    log:
        join(PATHS["logs_dir"], "build_run_report.log")
    shell:
        (
            "python3 workflow/scripts/reporting/build_run_report.py "
            "--database-csv {input.csv} "
            "--database-xlsx {input.xlsx} "
            "--metadata-json {input.metadata} "
            "--complete-json {input.complete} "
            "--kegg-json {input.kegg} "
            "--keys-consistency-json {input.keys_consistency} "
            "--links-groundtruth-policy-json {input.links_groundtruth_policy} "
            "--output {output} "
            "--version {params.version} "
            "--config {params.config_file} "
            "> {log} 2>&1"
        )
