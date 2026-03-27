#!/usr/bin/env Rscript

source("workflow/lib/utils.R")
source("workflow/lib/io_contracts.R")

load_required_packages(c("dplyr", "stringr", "writexl"))

args <- parse_cli_args()
require_cli_args(args, c("enriched-data", "local-data", "output-csv", "output-xlsx", "csv-sep", "csv-quote", "config"))

enriched_data <- readRDS(args[["enriched-data"]])
local_data <- readRDS(args[["local-data"]])
output_csv <- args[["output-csv"]]
output_xlsx <- args[["output-xlsx"]]
csv_sep <- args[["csv-sep"]]
csv_quote <- tolower(args[["csv-quote"]]) %in% c("1", "true", "yes", "y")

build_enzyme_pattern <- function(enzyme_terms) {
  escaped_terms <- gsub("([\\^$.|?*+(){}\\[\\]\\\\])", "\\\\\\1", enzyme_terms, perl = TRUE)
  paste0("\\b(", paste(escaped_terms, collapse = "|"), ")\\b")
}

enzyme_pattern <- build_enzyme_pattern(local_data$enzyme_terms)

final_database <- enriched_data %>%
  dplyr::mutate(
    enzyme_activity = stringr::str_extract(genename, stringr::regex(enzyme_pattern, ignore_case = TRUE)),
    enzyme_activity = dplyr::if_else(is.na(enzyme_activity), genename, enzyme_activity),
    genename = stringr::str_remove(genename, stringr::regex("\\s*\\[EC.*$", ignore_case = TRUE)),
    genesymbol = stringr::str_remove(genesymbol, ",.*$")
  ) %>%
  dplyr::distinct() %>%
  dplyr::select(dplyr::all_of(EXPECTED_DATABASE_COLUMNS))

ensure_parent_dir(output_csv)
ensure_parent_dir(output_xlsx)
write_database_csv(final_database, output_csv, sep = csv_sep, quote = csv_quote)

writexl::write_xlsx(final_database, output_xlsx)

log_message(sprintf("Saved final database to %s", output_csv), "SUCCESS")
if (file.exists(output_xlsx)) {
  log_message(sprintf("Saved final database to %s", output_xlsx), "SUCCESS")
}
