#!/usr/bin/env Rscript

source("workflow/lib/utils.R")

load_required_packages(c("dplyr"))

args <- parse_cli_args()
require_cli_args(args, c("local-data", "kegg-data", "output", "config"))

local_data <- readRDS(args[["local-data"]])
kegg_data <- readRDS(args[["kegg-data"]])
output_file <- args[["output"]]

merge_ko_compound_via_links <- function(kegg_bundle) {
  ko_ec_cpd <- merge(kegg_bundle$ko_ec_links, kegg_bundle$compound_ec_links, by = "ec", all = TRUE)
  ko_reaction_cpd <- merge(kegg_bundle$ko_reaction_links, kegg_bundle$compound_reaction_links, by = "reaction", all = TRUE)

  combined <- rbind(
    ko_ec_cpd[, c("ko", "cpd")],
    ko_reaction_cpd[, c("ko", "cpd")]
  )

  combined %>%
    dplyr::distinct() %>%
    dplyr::mutate(cpd = gsub("cpd:", "", cpd))
}

integrate_compound_sources <- function(agency_compounds, ko_compound_links, curated_compounds) {
  compounds_from_kegg <- merge(agency_compounds, ko_compound_links, by = "cpd")
  compounds_from_kegg <- compounds_from_kegg[, c("cpd", "ko", "referenceAG")]

  curated_with_agency <- merge(curated_compounds, agency_compounds, by = "cpd")

  rbind(curated_with_agency, compounds_from_kegg)
}

add_compound_names <- function(compounds, compound_list) {
  merge(compounds, compound_list, by = "cpd")
}

ko_compound_links <- merge_ko_compound_via_links(kegg_data)
integrated <- integrate_compound_sources(
  local_data$agency_compounds,
  ko_compound_links,
  local_data$curated_compounds
)
merged_compounds <- add_compound_names(integrated, kegg_data$compound_list)

ensure_parent_dir(output_file)
saveRDS(merged_compounds, output_file)
log_message(sprintf("Saved merged data to %s", output_file), "SUCCESS")
