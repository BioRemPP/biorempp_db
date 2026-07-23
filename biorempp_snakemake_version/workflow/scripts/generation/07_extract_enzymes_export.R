#!/usr/bin/env Rscript

source("workflow/lib/utils.R")
source("workflow/lib/io_contracts.R")

load_required_packages(c("dplyr", "stringr", "writexl"))

args <- parse_cli_args()
require_cli_args(args, c("enriched-data", "local-data", "kegg-data", "output-csv", "output-xlsx", "csv-sep", "csv-quote"))

enriched_data <- readRDS(args[["enriched-data"]])
local_data <- readRDS(args[["local-data"]])
kegg_data <- readRDS(args[["kegg-data"]])
output_csv <- args[["output-csv"]]
output_xlsx <- args[["output-xlsx"]]
csv_sep <- args[["csv-sep"]]
csv_quote <- tolower(args[["csv-quote"]]) %in% c("1", "true", "yes", "y")

build_enzyme_pattern <- function(enzyme_terms) {
  escaped_terms <- gsub("([\\^$.|?*+(){}\\[\\]\\\\])", "\\\\\\1", enzyme_terms, perl = TRUE)
  paste0("\\b(", paste(escaped_terms, collapse = "|"), ")\\b")
}

enzyme_pattern <- build_enzyme_pattern(local_data$enzyme_terms)

normalize_reaction <- function(value) {
  cleaned <- normalize_na_text(value)
  cleaned <- stringr::str_remove(cleaned, stringr::regex("^rn\\s*:\\s*", ignore_case = TRUE))
  extracted <- stringr::str_extract(cleaned, stringr::regex("R\\d{5}", ignore_case = TRUE))
  dplyr::if_else(is_na_like(extracted), NA_character_, stringr::str_to_upper(extracted))
}

build_reaction_descriptions <- function(kegg_bundle) {
  reaction_list <- kegg_bundle$reaction_list %>%
    dplyr::transmute(
      reaction = normalize_reaction(reaction),
      reaction_description = normalize_na_text(reaction_description_raw)
    ) %>%
    dplyr::filter(!is.na(reaction), !is.na(reaction_description)) %>%
    dplyr::group_by(reaction) %>%
    dplyr::summarise(reaction_description = dplyr::first(reaction_description), .groups = "drop")

  reaction_list
}

reaction_descriptions <- build_reaction_descriptions(kegg_data)

final_database <- enriched_data %>%
  dplyr::left_join(reaction_descriptions, by = "reaction") %>%
  dplyr::mutate(
    reaction_description = dplyr::if_else(is.na(reaction), NA_character_, reaction_description)
  ) %>%
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
