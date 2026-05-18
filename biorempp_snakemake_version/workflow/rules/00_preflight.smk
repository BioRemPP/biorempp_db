from os.path import join

rule preflight_check_inputs:
    output:
        join(WORK_DIR, "preflight_ok.json")
    params:
        input_dir = PATHS["input_dir"]
    log:
        join(PATHS["logs_dir"], "preflight_check_inputs.log")
    shell:
        (
            "Rscript workflow/scripts/generation/00_check_inputs.R "
            "--input-dir {params.input_dir} "
            "--output {output} "
            "> {log} 2>&1"
        )
