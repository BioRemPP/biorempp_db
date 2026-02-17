from os.path import join

ANALYSIS_DIR = join(RESULTS_DIR, "analysis")
DATABASE_FILE = join(RESULTS_DIR, "database", OUTPUTS["database_csv"])

rule basic_statistics:
    input:
        DATABASE_FILE
    output:
        join(ANALYSIS_DIR, "basic_statistics.json")
    params:
        config_file = "config/config.yaml"
    log:
        join(PATHS["logs_dir"], "analysis_basic_statistics.log")
    shell:
        (
            "Rscript workflow/scripts/analysis/01_basic_statistics.R "
            "--input-csv {input} "
            "--output {output} "
            "--config {params.config_file} "
            "> {log} 2>&1"
        )


rule compound_statistics:
    input:
        DATABASE_FILE
    output:
        join(ANALYSIS_DIR, "compound_statistics.json")
    params:
        config_file = "config/config.yaml",
        top_n = config["analysis"]["top_n_compounds"]
    log:
        join(PATHS["logs_dir"], "analysis_compound_statistics.log")
    shell:
        (
            "Rscript workflow/scripts/analysis/02_compound_statistics.R "
            "--input-csv {input} "
            "--output {output} "
            "--top-n {params.top_n} "
            "--config {params.config_file} "
            "> {log} 2>&1"
        )


rule ko_statistics:
    input:
        DATABASE_FILE
    output:
        join(ANALYSIS_DIR, "ko_statistics.json")
    params:
        config_file = "config/config.yaml",
        top_n = config["analysis"]["top_n_ko"]
    log:
        join(PATHS["logs_dir"], "analysis_ko_statistics.log")
    shell:
        (
            "Rscript workflow/scripts/analysis/03_ko_statistics.R "
            "--input-csv {input} "
            "--output {output} "
            "--top-n {params.top_n} "
            "--config {params.config_file} "
            "> {log} 2>&1"
        )


rule enzyme_statistics:
    input:
        DATABASE_FILE
    output:
        join(ANALYSIS_DIR, "enzyme_statistics.json")
    params:
        config_file = "config/config.yaml",
        top_n = config["analysis"]["top_n_enzymes"]
    log:
        join(PATHS["logs_dir"], "analysis_enzyme_statistics.log")
    shell:
        (
            "Rscript workflow/scripts/analysis/04_enzyme_statistics.R "
            "--input-csv {input} "
            "--output {output} "
            "--top-n {params.top_n} "
            "--config {params.config_file} "
            "> {log} 2>&1"
        )


rule gene_statistics:
    input:
        DATABASE_FILE
    output:
        join(ANALYSIS_DIR, "gene_statistics.json")
    params:
        config_file = "config/config.yaml"
    log:
        join(PATHS["logs_dir"], "analysis_gene_statistics.log")
    shell:
        (
            "Rscript workflow/scripts/analysis/05_gene_statistics.R "
            "--input-csv {input} "
            "--output {output} "
            "--config {params.config_file} "
            "> {log} 2>&1"
        )


rule crosstab_statistics:
    input:
        DATABASE_FILE
    output:
        join(ANALYSIS_DIR, "crosstab_statistics.json")
    params:
        config_file = "config/config.yaml"
    log:
        join(PATHS["logs_dir"], "analysis_crosstab_statistics.log")
    shell:
        (
            "Rscript workflow/scripts/analysis/06_crosstab_statistics.R "
            "--input-csv {input} "
            "--output {output} "
            "--config {params.config_file} "
            "> {log} 2>&1"
        )


rule database_metadata:
    input:
        csv = DATABASE_FILE,
        kegg_info = join(RESULTS_DIR, "metadata", "kegg_release.json")
    output:
        join(ANALYSIS_DIR, "database_metadata.json")
    params:
        config_file = "config/config.yaml",
        version = config["version"]
    log:
        join(PATHS["logs_dir"], "analysis_database_metadata.log")
    shell:
        (
            "Rscript workflow/scripts/analysis/07_metadata.R "
            "--input-csv {input.csv} "
            "--kegg-info {input.kegg_info} "
            "--output {output} "
            "--version {params.version} "
            "--config {params.config_file} "
            "> {log} 2>&1"
        )


rule executive_summary:
    input:
        basic = join(ANALYSIS_DIR, "basic_statistics.json"),
        compound = join(ANALYSIS_DIR, "compound_statistics.json"),
        ko = join(ANALYSIS_DIR, "ko_statistics.json"),
        enzyme = join(ANALYSIS_DIR, "enzyme_statistics.json")
    output:
        join(ANALYSIS_DIR, "executive_summary.json")
    params:
        config_file = "config/config.yaml"
    log:
        join(PATHS["logs_dir"], "analysis_executive_summary.log")
    shell:
        (
            "Rscript workflow/scripts/analysis/08_executive_summary.R "
            "--basic {input.basic} "
            "--compound {input.compound} "
            "--ko {input.ko} "
            "--enzyme {input.enzyme} "
            "--output {output} "
            "--config {params.config_file} "
            "> {log} 2>&1"
        )


rule complete_analysis:
    input:
        metadata = join(ANALYSIS_DIR, "database_metadata.json"),
        basic = join(ANALYSIS_DIR, "basic_statistics.json"),
        compound = join(ANALYSIS_DIR, "compound_statistics.json"),
        ko = join(ANALYSIS_DIR, "ko_statistics.json"),
        enzyme = join(ANALYSIS_DIR, "enzyme_statistics.json"),
        gene = join(ANALYSIS_DIR, "gene_statistics.json"),
        crosstab = join(ANALYSIS_DIR, "crosstab_statistics.json"),
        executive = join(ANALYSIS_DIR, "executive_summary.json")
    output:
        join(ANALYSIS_DIR, "complete_analysis.json")
    params:
        config_file = "config/config.yaml"
    log:
        join(PATHS["logs_dir"], "analysis_complete_analysis.log")
    shell:
        (
            "Rscript workflow/scripts/analysis/09_merge_complete_analysis.R "
            "--metadata {input.metadata} "
            "--basic {input.basic} "
            "--compound {input.compound} "
            "--ko {input.ko} "
            "--enzyme {input.enzyme} "
            "--gene {input.gene} "
            "--crosstab {input.crosstab} "
            "--executive {input.executive} "
            "--output {output} "
            "--config {params.config_file} "
            "> {log} 2>&1"
        )
