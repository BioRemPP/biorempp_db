#!/usr/bin/env Rscript

source("workflow/lib/utils.R")

load_required_packages(c("dplyr", "stringr"))

args <- parse_cli_args()
require_cli_args(args, c("classified-data", "local-data", "output", "config"))

classified_data <- readRDS(args[["classified-data"]])
local_data <- readRDS(args[["local-data"]])
output_file <- args[["output"]]

kegg_reference <- local_data$ko_list %>%
  dplyr::transmute(
    ko = stringr::str_trim(stringr::str_to_upper(ko)),
    genesymbol = stringr::str_trim(genesymbol),
    genename = stringr::str_trim(genename)
  ) %>%
  dplyr::group_by(ko) %>%
  dplyr::summarise(
    genesymbol = dplyr::first(genesymbol),
    genename = dplyr::first(genename),
    .groups = "drop"
  )

enriched <- classified_data %>%
  dplyr::filter(!is.na(ko), ko != "") %>%
  dplyr::mutate(ko = stringr::str_trim(stringr::str_to_upper(ko))) %>%
  dplyr::left_join(
    kegg_reference %>%
      dplyr::filter(!is.na(ko), ko != "") %>%
      dplyr::mutate(ko = stringr::str_trim(stringr::str_to_upper(ko))),
    by = "ko"
  ) %>%
  dplyr::filter(!is.na(genesymbol), genesymbol != "", !is.na(genename), genename != "")

ensure_parent_dir(output_file)
saveRDS(enriched, output_file)
log_message(sprintf("Saved enriched data to %s", output_file), "SUCCESS")
