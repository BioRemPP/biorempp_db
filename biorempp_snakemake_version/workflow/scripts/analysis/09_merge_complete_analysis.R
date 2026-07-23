#!/usr/bin/env Rscript

source("workflow/lib/utils.R")

load_required_packages(c("jsonlite"))

args <- parse_cli_args()
require_cli_args(
  args,
  c("metadata", "basic", "compound", "ko", "enzyme", "gene", "crosstab", "executive", "output")
)

results <- list(
  metadata = read_json_file(args[["metadata"]]),
  basic_stats = read_json_file(args[["basic"]]),
  compound_stats = read_json_file(args[["compound"]]),
  ko_stats = read_json_file(args[["ko"]]),
  enzyme_stats = read_json_file(args[["enzyme"]]),
  gene_stats = read_json_file(args[["gene"]]),
  crosstab_stats = read_json_file(args[["crosstab"]]),
  executive_summary = read_json_file(args[["executive"]])
)

write_json_file(results, args[["output"]])
log_message("Saved complete analysis JSON", "SUCCESS")
