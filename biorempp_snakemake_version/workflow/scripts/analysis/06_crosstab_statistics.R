#!/usr/bin/env Rscript

source("workflow/lib/utils.R")

load_required_packages(c("dplyr", "jsonlite"))

args <- parse_cli_args()
require_cli_args(args, c("input-csv", "csv-sep", "output", "config"))

db <- read_database_csv(args[["input-csv"]], sep = args[["csv-sep"]])

class_agency_crosstab <- db %>%
  dplyr::group_by(compoundclass, referenceAG) %>%
  dplyr::summarise(count = dplyr::n_distinct(cpd), .groups = "drop") %>%
  dplyr::arrange(dplyr::desc(count)) %>%
  utils::head(20)

enzyme_class_crosstab <- db %>%
  dplyr::group_by(compoundclass, enzyme_activity) %>%
  dplyr::summarise(count = dplyr::n(), .groups = "drop") %>%
  dplyr::arrange(dplyr::desc(count)) %>%
  utils::head(20)

ko_class_summary <- db %>%
  dplyr::group_by(compoundclass) %>%
  dplyr::summarise(unique_ko = dplyr::n_distinct(ko), .groups = "drop") %>%
  dplyr::arrange(dplyr::desc(unique_ko)) %>%
  utils::head(10)

stats <- list(
  top_20_class_agency_combinations = list(
    compound_classes = class_agency_crosstab$compoundclass,
    agencies = class_agency_crosstab$referenceAG,
    compound_counts = class_agency_crosstab$count
  ),
  top_20_enzyme_class_combinations = list(
    compound_classes = enzyme_class_crosstab$compoundclass,
    enzymes = enzyme_class_crosstab$enzyme_activity,
    counts = enzyme_class_crosstab$count
  ),
  top_10_classes_by_ko_diversity = list(
    compound_classes = ko_class_summary$compoundclass,
    unique_ko_counts = ko_class_summary$unique_ko
  )
)

write_json_file(stats, args[["output"]])
log_message("Saved crosstab statistics", "SUCCESS")
