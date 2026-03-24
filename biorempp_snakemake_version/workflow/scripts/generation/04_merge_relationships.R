#!/usr/bin/env Rscript

source("workflow/lib/utils.R")

load_required_packages(c("dplyr", "stringr"))

args <- parse_cli_args()
require_cli_args(args, c("local-data", "kegg-data", "output", "config"))

local_data <- readRDS(args[["local-data"]])
kegg_data <- readRDS(args[["kegg-data"]])
output_file <- args[["output"]]

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
  dplyr::if_else(cleaned == "" | is.na(cleaned), NA_character_, cleaned)
}

normalize_reaction <- function(value) {
  cleaned <- stringr::str_trim(as.character(value))
  cleaned <- stringr::str_remove(cleaned, stringr::regex("^rn\\s*:\\s*", ignore_case = TRUE))
  extracted <- stringr::str_extract(cleaned, stringr::regex("R\\d{5}", ignore_case = TRUE))
  dplyr::if_else(is.na(extracted), NA_character_, stringr::str_to_upper(extracted))
}

normalize_agency_compounds <- function(agency_compounds) {
  agency_compounds %>%
    dplyr::transmute(
      cpd = normalize_cpd(cpd),
      referenceAG = stringr::str_trim(as.character(referenceAG))
    ) %>%
    dplyr::filter(!is.na(cpd), cpd != "", !is.na(referenceAG), referenceAG != "") %>%
    dplyr::distinct()
}

normalize_curated_compounds <- function(curated_compounds) {
  curated_compounds %>%
    dplyr::transmute(
      cpd = normalize_cpd(cpd),
      ko = normalize_ko(ko)
    ) %>%
    dplyr::filter(!is.na(cpd), cpd != "", !is.na(ko), ko != "") %>%
    dplyr::distinct()
}

extract_kegg_links <- function(kegg_bundle) {
  list(
    ko_ec = kegg_bundle$ko_ec_links %>%
      dplyr::transmute(
        ko = normalize_ko(ko),
        ec = normalize_ec(ec)
      ) %>%
      dplyr::filter(!is.na(ko), !is.na(ec)) %>%
      dplyr::distinct(),
    ko_reaction = kegg_bundle$ko_reaction_links %>%
      dplyr::transmute(
        ko = normalize_ko(ko),
        reaction = normalize_reaction(reaction)
      ) %>%
      dplyr::filter(!is.na(ko), !is.na(reaction)) %>%
      dplyr::distinct(),
    cpd_ec = kegg_bundle$compound_ec_links %>%
      dplyr::transmute(
        cpd = normalize_cpd(cpd),
        ec = normalize_ec(ec)
      ) %>%
      dplyr::filter(!is.na(cpd), !is.na(ec)) %>%
      dplyr::distinct(),
    cpd_reaction = kegg_bundle$compound_reaction_links %>%
      dplyr::transmute(
        cpd = normalize_cpd(cpd),
        reaction = normalize_reaction(reaction)
      ) %>%
      dplyr::filter(!is.na(cpd), !is.na(reaction)) %>%
      dplyr::distinct(),
    ec_reaction = kegg_bundle$ec_reaction_links %>%
      dplyr::transmute(
        ec = normalize_ec(ec),
        reaction = normalize_reaction(reaction)
      ) %>%
      dplyr::filter(!is.na(ec), !is.na(reaction)) %>%
      dplyr::distinct()
  )
}

build_key_universe <- function(agency_norm, curated_norm, links) {
  direct_ec_keys <- agency_norm %>%
    dplyr::inner_join(links$cpd_ec, by = "cpd", relationship = "many-to-many") %>%
    dplyr::inner_join(links$ko_ec, by = "ec", relationship = "many-to-many") %>%
    dplyr::transmute(cpd, ko, referenceAG) %>%
    dplyr::distinct()

  direct_reaction_keys <- agency_norm %>%
    dplyr::inner_join(links$cpd_reaction, by = "cpd", relationship = "many-to-many") %>%
    dplyr::inner_join(links$ko_reaction, by = "reaction", relationship = "many-to-many") %>%
    dplyr::transmute(cpd, ko, referenceAG) %>%
    dplyr::distinct()

  curated_keys <- curated_norm %>%
    dplyr::inner_join(agency_norm, by = "cpd", relationship = "many-to-many") %>%
    dplyr::transmute(cpd, ko, referenceAG) %>%
    dplyr::distinct()

  key_universe <- dplyr::bind_rows(direct_ec_keys, direct_reaction_keys, curated_keys) %>%
    dplyr::distinct()

  if (nrow(key_universe) < 1) {
    stop("No cpd-ko-referenceAG keys were generated from direct or curated sources.", call. = FALSE)
  }

  list(
    key_universe = key_universe,
    direct_ec_keys = direct_ec_keys,
    direct_reaction_keys = direct_reaction_keys,
    curated_keys = curated_keys
  )
}

expand_keys_with_ko_fallback <- function(key_universe, links) {
  ec_rows <- key_universe %>%
    dplyr::inner_join(links$ko_ec, by = "ko", relationship = "many-to-many") %>%
    dplyr::transmute(cpd, ko, ec, reaction = NA_character_, referenceAG) %>%
    dplyr::distinct()

  reaction_rows <- key_universe %>%
    dplyr::inner_join(links$ko_reaction, by = "ko", relationship = "many-to-many") %>%
    dplyr::transmute(cpd, ko, ec = NA_character_, reaction, referenceAG) %>%
    dplyr::distinct()

  supported_keys <- dplyr::bind_rows(
    ec_rows %>% dplyr::distinct(cpd, ko, referenceAG),
    reaction_rows %>% dplyr::distinct(cpd, ko, referenceAG)
  ) %>%
    dplyr::distinct()

  unsupported_rows <- key_universe %>%
    dplyr::anti_join(supported_keys, by = c("cpd", "ko", "referenceAG")) %>%
    dplyr::mutate(
      ec = NA_character_,
      reaction = NA_character_
    ) %>%
    dplyr::select(cpd, ko, ec, reaction, referenceAG)

  dplyr::bind_rows(ec_rows, reaction_rows, unsupported_rows) %>%
    dplyr::distinct()
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

agency_norm <- normalize_agency_compounds(local_data$agency_compounds)
curated_norm <- normalize_curated_compounds(local_data$curated_compounds)
links <- extract_kegg_links(kegg_data)

universe <- build_key_universe(agency_norm, curated_norm, links)
integrated <- expand_keys_with_ko_fallback(universe$key_universe, links)
merged_compounds <- add_compound_names(integrated, kegg_data$compound_list)

log_message(
  sprintf(
    "Universe keys: %d | Direct EC keys: %d | Direct reaction keys: %d | Curated keys: %d | Merged rows: %d",
    nrow(universe$key_universe),
    nrow(universe$direct_ec_keys),
    nrow(universe$direct_reaction_keys),
    nrow(universe$curated_keys),
    nrow(merged_compounds)
  ),
  "INFO"
)

ensure_parent_dir(output_file)
saveRDS(merged_compounds, output_file)
log_message(sprintf("Saved merged data to %s", output_file), "SUCCESS")
