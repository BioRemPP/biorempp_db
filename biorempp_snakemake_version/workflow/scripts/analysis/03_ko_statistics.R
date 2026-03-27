#!/usr/bin/env Rscript

source("workflow/lib/utils.R")

load_required_packages(c("dplyr", "jsonlite"))

args <- parse_cli_args()
require_cli_args(args, c("input-csv", "csv-sep", "output", "top-n", "config"))

db <- read_database_csv(args[["input-csv"]], sep = args[["csv-sep"]])
top_n <- as.integer(args[["top-n"]])

ko_frequency <- db %>%
  dplyr::group_by(ko) %>%
  dplyr::summarise(
    frequency = dplyr::n(),
    unique_compounds = dplyr::n_distinct(cpd),
    .groups = "drop"
  ) %>%
  dplyr::arrange(dplyr::desc(frequency))

top_kos <- utils::head(ko_frequency, top_n)

stats <- list(
  total_unique_ko = length(unique(db$ko)),
  top_20_ko = list(
    ko_ids = top_kos$ko,
    frequencies = top_kos$frequency,
    unique_compounds_per_ko = top_kos$unique_compounds
  ),
  ko_frequency_summary = list(
    min_frequency = min(ko_frequency$frequency),
    max_frequency = max(ko_frequency$frequency),
    mean_frequency = mean(ko_frequency$frequency),
    median_frequency = stats::median(ko_frequency$frequency)
  ),
  compounds_per_ko_summary = list(
    min_compounds = min(ko_frequency$unique_compounds),
    max_compounds = max(ko_frequency$unique_compounds),
    mean_compounds = mean(ko_frequency$unique_compounds),
    median_compounds = stats::median(ko_frequency$unique_compounds)
  )
)

write_json_file(stats, args[["output"]])
log_message("Saved KO statistics", "SUCCESS")
