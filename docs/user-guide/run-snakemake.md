<!--
Page status: verified
Audience: operators, maintainers
Applies to: Snakemake
Version scope: Snakemake output contract v1.1.0
Last verified on: 2026-06-24
Primary sources:
- biorempp_snakemake_version/Snakefile
- biorempp_snakemake_version/config/config.yaml
- biorempp_snakemake_version/env/docker-compose.yml
- biorempp_snakemake_version/scripts/run_snakemake.sh
- biorempp_snakemake_version/scripts/run_snakemake.bat
- biorempp_snakemake_version/workflow/rules/00_preflight.smk
- biorempp_snakemake_version/workflow/rules/10_generation.smk
- biorempp_snakemake_version/workflow/rules/20_analysis.smk
- biorempp_snakemake_version/workflow/rules/30_validation.smk
- biorempp_snakemake_version/workflow/rules/90_reporting.smk
-->

# Running The Snakemake Pipeline

This page covers operational execution of the active BioRemPP workflow after the environment and input contract are already in place.

## Supported Entry Points

### Windows helper script

```bat
biorempp_snakemake_version\scripts\run_snakemake.bat 2
```

### POSIX helper script

```bash
./biorempp_snakemake_version/scripts/run_snakemake.sh 2
```

### Direct compose invocation

```bash
docker compose -f biorempp_snakemake_version/env/docker-compose.yml run --rm snakemake
```

All three entry points run the same workflow contract defined by:

- `Snakefile`
- `config/config.yaml`

The helper scripts also create the expected `results/`, `work/`, and `logs/` directories before invoking Snakemake.

## Workflow Structure

The `all` rule requires the full release output set:

- database exports
- analysis JSON artifacts
- KEGG release metadata
- integrated validation reports
- the final workflow summary

Operationally, the workflow is split into five rule modules:

1. `00_preflight.smk`
2. `10_generation.smk`
3. `20_analysis.smk`
4. `30_validation.smk`
5. `90_reporting.smk`

This means a complete run does more than generate the final CSV and XLSX. It also produces analysis, validation, and reporting artifacts required by the downstream GX validator.

## Useful Execution Modes

### Full run

```bash
docker compose -f biorempp_snakemake_version/env/docker-compose.yml run --rm snakemake
```

### Dry run

```bash
docker compose -f biorempp_snakemake_version/env/docker-compose.yml run --rm snakemake \
  snakemake -n --snakefile Snakefile --configfile config/config.yaml --cores 1
```

### Run a specific target rule

Example: rebuild only the final workflow report after upstream outputs already exist.

```bash
docker compose -f biorempp_snakemake_version/env/docker-compose.yml run --rm snakemake \
  snakemake --snakefile Snakefile --configfile config/config.yaml --cores 1 build_run_report
```

Use target-specific execution only when you understand the dependency chain and the upstream artifacts are already valid.

## Runtime Directories

During execution, the main working directories are:

| Path | Purpose |
|---|---|
| `biorempp_snakemake_version/results/` | final pipeline outputs |
| `biorempp_snakemake_version/work/` | intermediate serialized bundles such as `local_data.rds` and `kegg_data.rds` |
| `biorempp_snakemake_version/logs/` | per-rule execution logs |
| `biorempp_snakemake_version/cache/kegg_link_cache/` | KEGG link cache files used by the integrated validation rules |

## Recommended Post-Run Check

After the pipeline finishes, confirm that the final rule contract is satisfied by checking at minimum:

- `results/database/biorempp_database_v1.1.0.csv`
- `results/database/biorempp_database_v1.1.0.xlsx`
- `results/analysis/complete_analysis.json`
- `results/metadata/kegg_release.json`
- `results/metadata/keys_consistency_report.json`
- `results/metadata/links_groundtruth_policy_report.json`
- `results/reports/workflow_summary.json`

The next operational step is to run the GX validator against this results tree.

## Related Pages

- [Input Data Contract](input-data.md)
- [Understanding Outputs](understanding-output.md)
- [Troubleshooting](troubleshooting.md)
