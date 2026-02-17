#!/usr/bin/env Rscript

source("workflow/lib/utils.R")

load_required_packages(c("dplyr", "tidyr", "stringr"))

args <- parse_cli_args()
require_cli_args(args, c("merged-data", "local-data", "output", "config"))

merged_compounds <- readRDS(args[["merged-data"]])
local_data <- readRDS(args[["local-data"]])
output_file <- args[["output"]]


tidy_classes <- local_data$compound_classes %>%
  tidyr::separate_rows(compoundclass, sep = ",") %>%
  dplyr::mutate(
    compoundclass = stringr::str_trim(compoundclass),
    compoundclass = stringr::str_replace_all(compoundclass, " \\(repeated\\)", ""),
    compoundclass = stringr::str_replace_all(compoundclass, "Organometalic", "Organometallic")
  ) %>%
  dplyr::filter(!is.na(compoundclass), compoundclass != "")

classified <- merge(tidy_classes, merged_compounds, by = "cpd") %>%
  dplyr::distinct() %>%
  dplyr::arrange(ko)

sanitized <- classified %>%
  dplyr::mutate(
    ko = stringr::str_trim(as.character(ko)),
    ko = stringr::str_remove(ko, stringr::regex("^ko\\s*:\\s*", ignore_case = TRUE)),
    ko_extracted = stringr::str_extract(ko, stringr::regex("K\\d{5}", ignore_case = TRUE)),
    ko = dplyr::if_else(!is.na(ko_extracted), paste0("K", stringr::str_extract(ko_extracted, "\\d{5}")), NA_character_)
  ) %>%
  dplyr::filter(!is.na(ko)) %>%
  dplyr::select(-ko_extracted)

ensure_parent_dir(output_file)
saveRDS(sanitized, output_file)
log_message(sprintf("Saved classified data to %s", output_file), "SUCCESS")
