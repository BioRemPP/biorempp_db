#!/usr/bin/env Rscript

source("workflow/lib/utils.R")

load_required_packages(c("dplyr", "jsonlite"))

args <- parse_cli_args()
require_cli_args(args, c("input-csv", "csv-sep", "output", "top-n", "config"))

db <- read_database_csv(args[["input-csv"]], sep = args[["csv-sep"]])
top_n <- as.integer(args[["top-n"]])

enzyme_frequency <- db %>%
  dplyr::group_by(enzyme_activity) %>%
  dplyr::summarise(
    frequency = dplyr::n(),
    unique_compounds = dplyr::n_distinct(cpd),
    unique_ko = dplyr::n_distinct(ko),
    .groups = "drop"
  ) %>%
  dplyr::arrange(dplyr::desc(frequency))

top_enzymes <- utils::head(enzyme_frequency, top_n)

stats <- list(
  total_unique_enzymes = length(unique(db$enzyme_activity)),
  top_30_enzymes = list(
    enzyme_names = top_enzymes$enzyme_activity,
    frequencies = top_enzymes$frequency,
    unique_compounds = top_enzymes$unique_compounds,
    unique_ko = top_enzymes$unique_ko
  ),
  enzyme_frequency_summary = list(
    min_frequency = min(enzyme_frequency$frequency),
    max_frequency = max(enzyme_frequency$frequency),
    mean_frequency = mean(enzyme_frequency$frequency),
    median_frequency = stats::median(enzyme_frequency$frequency)
  )
)

write_json_file(stats, args[["output"]])
log_message("Saved enzyme statistics", "SUCCESS")
