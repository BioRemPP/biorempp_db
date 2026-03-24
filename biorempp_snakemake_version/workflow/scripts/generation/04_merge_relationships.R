#!/usr/bin/env Rscript

source("workflow/lib/utils.R")

load_required_packages(c("dplyr", "stringr"))

args <- parse_cli_args()
require_cli_args(args, c("local-data", "kegg-data", "output", "audit-output", "config"))

local_data <- readRDS(args[["local-data"]])
kegg_data <- readRDS(args[["kegg-data"]])
output_file <- args[["output"]]
audit_output <- args[["audit-output"]]

normalize_cpd <- function(value) {
  cleaned <- stringr::str_trim(as.character(value))
  cleaned <- stringr::str_remove(cleaned, stringr::regex("^cpd\\s*:\\s*", ignore_case = TRUE))
  extracted <- stringr::str_extract(cleaned, stringr::regex("C\\d{5}", ignore_case = TRUE))
  dplyr::if_else(is.na(extracted), NA_character_, stringr::str_to_upper(extracted))
}

normalize_ko <- function(value) {
  cleaned <- stringr::str_trim(as.character(value))
  cleaned <- stringr::str_remove(cleaned, stringr::regex("^ko\\s*:\\s*", ignore_case = TRUE))
  extracted <- stringr::str_extract(cleaned, stringr::regex("K\\d{5}", ignore_case = TRUE))
  dplyr::if_else(is.na(extracted), NA_character_, stringr::str_to_upper(extracted))
}

normalize_ec <- function(value) {
  cleaned <- stringr::str_trim(as.character(value))
  cleaned <- stringr::str_remove(cleaned, stringr::regex("^ec\\s*:\\s*", ignore_case = TRUE))
  cleaned <- dplyr::if_else(cleaned == "" | is.na(cleaned), NA_character_, cleaned)
  cleaned
}

normalize_reaction <- function(value) {
  cleaned <- stringr::str_trim(as.character(value))
  cleaned <- stringr::str_remove(cleaned, stringr::regex("^rn\\s*:\\s*", ignore_case = TRUE))
  extracted <- stringr::str_extract(cleaned, stringr::regex("R\\d{5}", ignore_case = TRUE))
  dplyr::if_else(is.na(extracted), NA_character_, stringr::str_to_upper(extracted))
}

merge_ko_compound_via_links <- function(kegg_bundle) {
  ko_ec <- kegg_bundle$ko_ec_links %>%
    dplyr::transmute(
      ko = normalize_ko(ko),
      ec = normalize_ec(ec)
    ) %>%
    dplyr::filter(!is.na(ko), !is.na(ec)) %>%
    dplyr::distinct()

  cpd_ec <- kegg_bundle$compound_ec_links %>%
    dplyr::transmute(
      cpd = normalize_cpd(cpd),
      ec = normalize_ec(ec)
    ) %>%
    dplyr::filter(!is.na(cpd), !is.na(ec)) %>%
    dplyr::distinct()

  ko_reaction <- kegg_bundle$ko_reaction_links %>%
    dplyr::transmute(
      ko = normalize_ko(ko),
      reaction = normalize_reaction(reaction)
    ) %>%
    dplyr::filter(!is.na(ko), !is.na(reaction)) %>%
    dplyr::distinct()

  cpd_reaction <- kegg_bundle$compound_reaction_links %>%
    dplyr::transmute(
      cpd = normalize_cpd(cpd),
      reaction = normalize_reaction(reaction)
    ) %>%
    dplyr::filter(!is.na(cpd), !is.na(reaction)) %>%
    dplyr::distinct()

  ec_links <- ko_ec %>%
    dplyr::inner_join(cpd_ec, by = "ec") %>%
    dplyr::transmute(cpd, ko, ec, reaction = NA_character_) %>%
    dplyr::distinct()

  reaction_links <- ko_reaction %>%
    dplyr::inner_join(cpd_reaction, by = "reaction") %>%
    dplyr::transmute(cpd, ko, ec = NA_character_, reaction) %>%
    dplyr::distinct()

  dplyr::bind_rows(ec_links, reaction_links) %>%
    dplyr::filter(!is.na(cpd), !is.na(ko)) %>%
    dplyr::distinct()
}

integrate_compound_sources <- function(agency_compounds, ko_compound_links, curated_compounds) {
  agency_norm <- agency_compounds %>%
    dplyr::transmute(
      cpd = normalize_cpd(cpd),
      referenceAG = stringr::str_trim(as.character(referenceAG))
    ) %>%
    dplyr::filter(!is.na(cpd), cpd != "", !is.na(referenceAG), referenceAG != "") %>%
    dplyr::distinct()

  curated_norm <- curated_compounds %>%
    dplyr::transmute(
      cpd = normalize_cpd(cpd),
      ko = normalize_ko(ko)
    ) %>%
    dplyr::filter(!is.na(cpd), !is.na(ko)) %>%
    dplyr::distinct()

  compounds_from_api <- agency_norm %>%
    dplyr::inner_join(ko_compound_links, by = "cpd") %>%
    dplyr::transmute(cpd, ko, ec, reaction, referenceAG) %>%
    dplyr::distinct()

  curated_with_agency <- curated_norm %>%
    dplyr::inner_join(agency_norm, by = "cpd") %>%
    dplyr::mutate(
      ec = NA_character_,
      reaction = NA_character_
    ) %>%
    dplyr::select(cpd, ko, ec, reaction, referenceAG) %>%
    dplyr::distinct()

  curated_without_api <- curated_with_agency %>%
    dplyr::anti_join(
      compounds_from_api %>% dplyr::distinct(cpd, ko, referenceAG),
      by = c("cpd", "ko", "referenceAG")
    ) %>%
    dplyr::distinct()

  integrated <- dplyr::bind_rows(compounds_from_api, curated_without_api) %>%
    dplyr::distinct()

  list(
    integrated = integrated,
    compounds_from_api = compounds_from_api,
    curated_with_agency = curated_with_agency,
    curated_without_api = curated_without_api
  )
}

add_compound_names <- function(compounds, compound_list) {
  normalized_compound_list <- compound_list %>%
    dplyr::transmute(
      cpd = normalize_cpd(cpd),
      compoundname = stringr::str_trim(as.character(compoundname))
    ) %>%
    dplyr::filter(!is.na(cpd), cpd != "", !is.na(compoundname), compoundname != "") %>%
    dplyr::group_by(cpd) %>%
    dplyr::summarise(compoundname = dplyr::first(compoundname), .groups = "drop")

  compounds %>%
    dplyr::inner_join(normalized_compound_list, by = "cpd") %>%
    dplyr::distinct()
}

build_link_consistency_audit <- function(integrated_data, compounds_from_api, curated_with_agency, curated_without_api) {
  api_keys <- compounds_from_api %>%
    dplyr::distinct(cpd, ko, referenceAG)

  final_keys <- integrated_data %>%
    dplyr::distinct(cpd, ko, referenceAG)

  final_pairs <- integrated_data %>%
    dplyr::distinct(cpd, ko)

  api_pairs <- compounds_from_api %>%
    dplyr::distinct(cpd, ko)

  rows_both_na <- integrated_data %>%
    dplyr::filter(is.na(ec) & is.na(reaction))

  improper_na_rows <- rows_both_na %>%
    dplyr::inner_join(api_keys, by = c("cpd", "ko", "referenceAG"))

  if (nrow(improper_na_rows) > 0) {
    stop(
      sprintf(
        "Compliance violation: found %d rows with ec/reaction as NA despite API support for the same cpd-ko-referenceAG key.",
        nrow(improper_na_rows)
      ),
      call. = FALSE
    )
  }

  list(
    generated_at_utc = format(as.POSIXct(Sys.time(), tz = "UTC"), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
    source_of_truth = "KEGG REST API",
    policy = list(
      synthetic_ec_reaction_combinations = FALSE,
      curated_na_allowed_only_without_api_support = TRUE
    ),
    row_counts = list(
      total_rows = nrow(integrated_data),
      ec_only = nrow(integrated_data %>% dplyr::filter(!is.na(ec) & is.na(reaction))),
      reaction_only = nrow(integrated_data %>% dplyr::filter(is.na(ec) & !is.na(reaction))),
      both_na = nrow(rows_both_na),
      both_present = nrow(integrated_data %>% dplyr::filter(!is.na(ec) & !is.na(reaction)))
    ),
    key_counts = list(
      distinct_cpd_ko_referenceAG = nrow(final_keys),
      distinct_cpd_ko_referenceAG_with_api_support = nrow(dplyr::inner_join(final_keys, api_keys, by = c("cpd", "ko", "referenceAG"))),
      distinct_cpd_ko_referenceAG_without_api_support = nrow(dplyr::anti_join(final_keys, api_keys, by = c("cpd", "ko", "referenceAG"))),
      distinct_cpd_ko = nrow(final_pairs),
      distinct_cpd_ko_with_api_support = nrow(dplyr::inner_join(final_pairs, api_pairs, by = c("cpd", "ko"))),
      distinct_cpd_ko_without_api_support = nrow(dplyr::anti_join(final_pairs, api_pairs, by = c("cpd", "ko")))
    ),
    curated_counts = list(
      curated_with_agency_rows = nrow(curated_with_agency),
      curated_without_api_support_rows = nrow(curated_without_api),
      curated_removed_due_to_api_support = nrow(curated_with_agency) - nrow(curated_without_api)
    ),
    compliance_checks = list(
      improper_na_rows_for_supported_keys = nrow(improper_na_rows),
      improper_na_examples = if (nrow(improper_na_rows) > 0) {
        utils::head(improper_na_rows, 20)
      } else {
        list()
      }
    )
  )
}

ko_compound_links <- merge_ko_compound_via_links(kegg_data)
integration_result <- integrate_compound_sources(
  local_data$agency_compounds,
  ko_compound_links,
  local_data$curated_compounds
)
merged_compounds <- add_compound_names(integration_result$integrated, kegg_data$compound_list)
audit <- build_link_consistency_audit(
  integration_result$integrated,
  integration_result$compounds_from_api,
  integration_result$curated_with_agency,
  integration_result$curated_without_api
)

ensure_parent_dir(output_file)
saveRDS(merged_compounds, output_file)
write_json_file(audit, audit_output)
log_message(sprintf("Saved merged data to %s", output_file), "SUCCESS")
log_message(sprintf("Saved link consistency audit to %s", audit_output), "SUCCESS")
