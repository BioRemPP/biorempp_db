from os.path import join

rule fetch_kegg_info:
    output:
        join(RESULTS_DIR, "metadata", "kegg_release.json")
    params:
        config_file = "config/config.yaml",
        base_url = config["kegg"]["base_url"],
        info_endpoint = config["kegg"]["info_endpoint"]
    log:
        join(PATHS["logs_dir"], "fetch_kegg_info.log")
    shell:
        (
            "Rscript workflow/scripts/generation/02_fetch_kegg_info.R "
            "--output {output} "
            "--config {params.config_file} "
            "--base-url {params.base_url} "
            "--endpoint {params.info_endpoint} "
            "> {log} 2>&1"
        )


rule load_local_data:
    input:
        preflight = join(WORK_DIR, "preflight_ok.json")
    output:
        join(WORK_DIR, "local_data.rds")
    params:
        input_dir = PATHS["input_dir"],
        config_file = "config/config.yaml"
    log:
        join(PATHS["logs_dir"], "load_local_data.log")
    shell:
        (
            "Rscript workflow/scripts/generation/01_load_local_data.R "
            "--input-dir {params.input_dir} "
            "--output {output} "
            "--config {params.config_file} "
            "> {log} 2>&1"
        )


rule fetch_kegg_data:
    input:
        preflight = join(WORK_DIR, "preflight_ok.json")
    output:
        join(WORK_DIR, "kegg_data.rds")
    params:
        config_file = "config/config.yaml",
        base_url = config["kegg"]["base_url"]
    log:
        join(PATHS["logs_dir"], "fetch_kegg_data.log")
    shell:
        (
            "Rscript workflow/scripts/generation/03_fetch_kegg_data.R "
            "--output {output} "
            "--config {params.config_file} "
            "--base-url {params.base_url} "
            "> {log} 2>&1"
        )


rule merge_relationships:
    input:
        local_data = join(WORK_DIR, "local_data.rds"),
        kegg_data = join(WORK_DIR, "kegg_data.rds")
    output:
        join(WORK_DIR, "merged_compounds.rds")
    params:
        config_file = "config/config.yaml"
    log:
        join(PATHS["logs_dir"], "merge_relationships.log")
    shell:
        (
            "Rscript workflow/scripts/generation/04_merge_relationships.R "
            "--local-data {input.local_data} "
            "--kegg-data {input.kegg_data} "
            "--output {output} "
            "--config {params.config_file} "
            "> {log} 2>&1"
        )


rule add_classifications:
    input:
        merged_data = join(WORK_DIR, "merged_compounds.rds"),
        local_data = join(WORK_DIR, "local_data.rds")
    output:
        join(WORK_DIR, "classified_compounds.rds")
    params:
        config_file = "config/config.yaml"
    log:
        join(PATHS["logs_dir"], "add_classifications.log")
    shell:
        (
            "Rscript workflow/scripts/generation/05_add_classifications.R "
            "--merged-data {input.merged_data} "
            "--local-data {input.local_data} "
            "--output {output} "
            "--config {params.config_file} "
            "> {log} 2>&1"
        )


rule enrich_gene_info:
    input:
        classified_data = join(WORK_DIR, "classified_compounds.rds"),
        local_data = join(WORK_DIR, "local_data.rds")
    output:
        join(WORK_DIR, "enriched_compounds.rds")
    params:
        config_file = "config/config.yaml"
    log:
        join(PATHS["logs_dir"], "enrich_gene_info.log")
    shell:
        (
            "Rscript workflow/scripts/generation/06_enrich_gene_info.R "
            "--classified-data {input.classified_data} "
            "--local-data {input.local_data} "
            "--output {output} "
            "--config {params.config_file} "
            "> {log} 2>&1"
        )


rule extract_enzymes_export:
    input:
        enriched_data = join(WORK_DIR, "enriched_compounds.rds"),
        local_data = join(WORK_DIR, "local_data.rds"),
        kegg_info = join(RESULTS_DIR, "metadata", "kegg_release.json")
    output:
        csv = join(RESULTS_DIR, "database", OUTPUTS["database_csv"]),
        xlsx = join(RESULTS_DIR, "database", OUTPUTS["database_xlsx"])
    params:
        config_file = "config/config.yaml",
        csv_sep = OUTPUTS["database_csv_delimiter"],
        csv_quote = OUTPUTS["database_csv_quote"]
    log:
        join(PATHS["logs_dir"], "extract_enzymes_export.log")
    shell:
        (
            "Rscript workflow/scripts/generation/07_extract_enzymes_export.R "
            "--enriched-data {input.enriched_data} "
            "--local-data {input.local_data} "
            "--output-csv {output.csv} "
            "--output-xlsx {output.xlsx} "
            "--csv-sep \"{params.csv_sep}\" "
            "--csv-quote \"{params.csv_quote}\" "
            "--config {params.config_file} "
            "> {log} 2>&1"
        )
