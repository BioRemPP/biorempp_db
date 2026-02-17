#!/usr/bin/env Rscript

source("workflow/lib/utils.R")

load_required_packages(c("jsonlite"))

args <- parse_cli_args()
require_cli_args(args, c("basic", "compound", "ko", "enzyme", "output", "config"))

basic_stats <- read_json_file(args[["basic"]])
compound_stats <- read_json_file(args[["compound"]])
ko_stats <- read_json_file(args[["ko"]])
enzyme_stats <- read_json_file(args[["enzyme"]])

compounds_per_class <- unlist(compound_stats$compounds_per_class)
most_represented_class <- names(which.max(compounds_per_class))

summary <- list(
  overview = list(
    total_entries = basic_stats$total_entries,
    unique_compounds = basic_stats$unique_compounds,
    unique_ko_entries = basic_stats$unique_ko_entries,
    unique_enzyme_activities = basic_stats$unique_enzyme_activities,
    unique_compound_classes = basic_stats$unique_compound_classes
  ),
  highlights = list(
    most_represented_class = most_represented_class,
    compounds_in_top_class = as.numeric(max(compounds_per_class)),
    most_frequent_enzyme = enzyme_stats$top_30_enzymes$enzyme_names[[1]],
    enzyme_frequency = as.numeric(enzyme_stats$top_30_enzymes$frequencies[[1]]),
    total_classes = compound_stats$class_distribution_summary$total_classes
  ),
  coverage = list(
    environmental_agencies = basic_stats$unique_reference_agencies,
    compound_classes_covered = basic_stats$unique_compound_classes,
    enzyme_types_identified = basic_stats$unique_enzyme_activities,
    gene_symbols_mapped = basic_stats$unique_gene_symbols
  )
)

write_json_file(summary, args[["output"]])
log_message("Saved executive summary", "SUCCESS")
