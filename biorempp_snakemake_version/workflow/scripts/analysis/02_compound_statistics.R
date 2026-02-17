#!/usr/bin/env Rscript

source("workflow/lib/utils.R")

load_required_packages(c("dplyr", "jsonlite"))

args <- parse_cli_args()
require_cli_args(args, c("input-csv", "output", "top-n", "config"))

db <- read.csv(args[["input-csv"]], stringsAsFactors = FALSE)
top_n <- as.integer(args[["top-n"]])

compounds_per_class <- db %>%
  dplyr::group_by(compoundclass) %>%
  dplyr::summarise(count = dplyr::n_distinct(cpd), .groups = "drop") %>%
  dplyr::arrange(dplyr::desc(count))

compounds_per_agency <- db %>%
  dplyr::group_by(referenceAG) %>%
  dplyr::summarise(count = dplyr::n_distinct(cpd), .groups = "drop") %>%
  dplyr::arrange(dplyr::desc(count))

top_compounds <- db %>%
  dplyr::group_by(cpd, compoundname) %>%
  dplyr::summarise(frequency = dplyr::n(), .groups = "drop") %>%
  dplyr::arrange(dplyr::desc(frequency)) %>%
  utils::head(top_n)

stats <- list(
  total_unique_compounds = length(unique(db$cpd)),
  compounds_per_class = as.list(setNames(compounds_per_class$count, compounds_per_class$compoundclass)),
  compounds_per_agency = as.list(setNames(compounds_per_agency$count, compounds_per_agency$referenceAG)),
  top_20_compounds = list(
    compound_ids = top_compounds$cpd,
    compound_names = top_compounds$compoundname,
    frequencies = top_compounds$frequency
  ),
  class_distribution_summary = list(
    total_classes = nrow(compounds_per_class),
    min_compounds_per_class = min(compounds_per_class$count),
    max_compounds_per_class = max(compounds_per_class$count),
    mean_compounds_per_class = mean(compounds_per_class$count),
    median_compounds_per_class = stats::median(compounds_per_class$count)
  )
)

write_json_file(stats, args[["output"]])
log_message("Saved compound statistics", "SUCCESS")
