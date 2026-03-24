/#!/usr/bin/env Rscript

source("workflow/lib/utils.R")

load_required_packages(c("jsonlite", "dplyr", "stringr"))

args <- parse_cli_args()
require_cli_args(args, c("input-csv", "kegg-info", "kegg-data", "output", "version", "config"))

db <- read.csv(args[["input-csv"]], stringsAsFactors = FALSE)
kegg_info <- read_json_file(args[["kegg-info"]])
kegg_data <- readRDS(args[["kegg-data"]])

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

build_link_tables <- function(bundle) {
  list(
    ko_ec = bundle$ko_ec_links %>%
      dplyr::transmute(
        ko = normalize_ko(ko),
        ec = normalize_ec(ec)
      ) %>%
      dplyr::filter(!is.na(ko), !is.na(ec)) %>%
      dplyr::distinct(),
    ko_reaction = bundle$ko_reaction_links %>%
      dplyr::transmute(
        ko = normalize_ko(ko),
        reaction = normalize_reaction(reaction)
      ) %>%
      dplyr::filter(!is.na(ko), !is.na(reaction)) %>%
      dplyr::distinct(),
    cpd_ec = bundle$compound_ec_links %>%
      dplyr::transmute(
        cpd = normalize_cpd(cpd),
        ec = normalize_ec(ec)
      ) %>%
      dplyr::filter(!is.na(cpd), !is.na(ec)) %>%
      dplyr::distinct(),
    cpd_reaction = bundle$compound_reaction_links %>%
      dplyr::transmute(
        cpd = normalize_cpd(cpd),
        reaction = normalize_reaction(reaction)
      ) %>%
      dplyr::filter(!is.na(cpd), !is.na(reaction)) %>%
      dplyr::distinct(),
    ec_reaction = bundle$ec_reaction_links %>%
      dplyr::transmute(
        ec = normalize_ec(ec),
        reaction = normalize_reaction(reaction)
      ) %>%
      dplyr::filter(!is.na(ec), !is.na(reaction)) %>%
      dplyr::distinct()
  )
}

sorted_unique <- function(values) {
  unique_values <- unique(values[!is.na(values) & values != ""])
  sort(unique_values)
}

build_link_match <- function(database, links) {
  db_norm <- database %>%
    dplyr::transmute(
      cpd = normalize_cpd(cpd),
      ko = normalize_ko(ko),
      ec = normalize_ec(ec),
      reaction = normalize_reaction(reaction)
    ) %>%
    dplyr::filter(!is.na(cpd), !is.na(ko))

  db_kos <- sorted_unique(db_norm$ko)
  db_cpds <- sorted_unique(db_norm$cpd)

  ko_supported <- sorted_unique(c(links$ko_ec$ko, links$ko_reaction$ko))
  cpd_supported <- sorted_unique(c(links$cpd_ec$cpd, links$cpd_reaction$cpd))

  ko_matched <- intersect(db_kos, ko_supported)
  ko_unmatched <- setdiff(db_kos, ko_supported)
  cpd_matched <- intersect(db_cpds, cpd_supported)
  cpd_unmatched <- setdiff(db_cpds, cpd_supported)

  direct_pairs <- dplyr::bind_rows(
    links$ko_ec %>%
      dplyr::inner_join(links$cpd_ec, by = "ec") %>%
      dplyr::transmute(cpd, ko),
    links$ko_reaction %>%
      dplyr::inner_join(links$cpd_reaction, by = "reaction") %>%
      dplyr::transmute(cpd, ko)
  ) %>%
    dplyr::distinct()

  direct_pair_keys <- paste(direct_pairs$cpd, direct_pairs$ko, sep = "|")
  ko_supported_set <- unique(ko_supported)

  pair_summary <- db_norm %>%
    dplyr::mutate(
      has_ec = !is.na(ec) & ec != "",
      has_reaction = !is.na(reaction) & reaction != ""
    ) %>%
    dplyr::group_by(cpd, ko) %>%
    dplyr::summarise(
      any_ec = any(has_ec),
      any_reaction = any(has_reaction),
      .groups = "drop"
    ) %>%
    dplyr::mutate(
      pair_key = paste(cpd, ko, sep = "|"),
      support_direct = pair_key %in% direct_pair_keys,
      support_ko = ko %in% ko_supported_set,
      support_class = dplyr::case_when(
        support_direct ~ "direct_compound_supported",
        support_ko ~ "ko_supported_only",
        TRUE ~ "unsupported"
      )
    )

  false_na_pairs <- pair_summary %>%
    dplyr::filter(!any_ec, !any_reaction, support_ko) %>%
    dplyr::select(cpd, ko)

  cpd_ec_keys <- paste(links$cpd_ec$cpd, links$cpd_ec$ec, sep = "|")
  cpd_reaction_keys <- paste(links$cpd_reaction$cpd, links$cpd_reaction$reaction, sep = "|")
  ko_ec_keys <- paste(links$ko_ec$ko, links$ko_ec$ec, sep = "|")
  ko_reaction_keys <- paste(links$ko_reaction$ko, links$ko_reaction$reaction, sep = "|")

  bridge_ko_reaction <- links$ko_ec %>%
    dplyr::inner_join(links$ec_reaction, by = "ec") %>%
    dplyr::transmute(ko, reaction) %>%
    dplyr::distinct()
  bridge_ko_ec <- links$ko_reaction %>%
    dplyr::inner_join(links$ec_reaction, by = "reaction") %>%
    dplyr::transmute(ko, ec) %>%
    dplyr::distinct()

  bridge_ko_reaction_keys <- paste(bridge_ko_reaction$ko, bridge_ko_reaction$reaction, sep = "|")
  bridge_ko_ec_keys <- paste(bridge_ko_ec$ko, bridge_ko_ec$ec, sep = "|")

  row_provenance <- db_norm %>%
    dplyr::mutate(
      has_ec = !is.na(ec) & ec != "",
      has_reaction = !is.na(reaction) & reaction != "",
      cpd_ec_key = paste(cpd, ec, sep = "|"),
      cpd_reaction_key = paste(cpd, reaction, sep = "|"),
      ko_ec_key = paste(ko, ec, sep = "|"),
      ko_reaction_key = paste(ko, reaction, sep = "|"),
      is_direct = dplyr::case_when(
        has_ec ~ cpd_ec_key %in% cpd_ec_keys,
        has_reaction ~ cpd_reaction_key %in% cpd_reaction_keys,
        TRUE ~ FALSE
      ),
      is_ko_supported = dplyr::case_when(
        has_ec ~ (ko_ec_key %in% ko_ec_keys) | (ko_ec_key %in% bridge_ko_ec_keys),
        has_reaction ~ (ko_reaction_key %in% ko_reaction_keys) | (ko_reaction_key %in% bridge_ko_reaction_keys),
        TRUE ~ FALSE
      ),
      provenance = dplyr::case_when(
        is_direct ~ "direct_compound_supported",
        is_ko_supported ~ "ko_supported_only",
        TRUE ~ "unsupported"
      )
    ) %>%
    dplyr::count(provenance, name = "count")

  row_provenance_named <- list(
    direct_compound_supported = 0L,
    ko_supported_only = 0L,
    unsupported = 0L
  )
  for (i in seq_len(nrow(row_provenance))) {
    row_name <- row_provenance$provenance[[i]]
    row_provenance_named[[row_name]] <- as.integer(row_provenance$count[[i]])
  }

  pair_class_counts <- pair_summary %>%
    dplyr::count(support_class, name = "count")
  pair_class_named <- list(
    direct_compound_supported = 0L,
    ko_supported_only = 0L,
    unsupported = 0L
  )
  for (i in seq_len(nrow(pair_class_counts))) {
    class_name <- pair_class_counts$support_class[[i]]
    pair_class_named[[class_name]] <- as.integer(pair_class_counts$count[[i]])
  }

  duplicate_full_rows <- as.integer(nrow(db_norm) - nrow(dplyr::distinct(db_norm)))

  list(
    policy = list(
      source_of_truth = "KEGG REST API",
      ko_fallback_all_keys = TRUE,
      synthetic_ec_reaction_cartesian = FALSE
    ),
    coverage = list(
      kos = list(
        total_in_database = length(db_kos),
        matched_count = length(ko_matched),
        unmatched_count = length(ko_unmatched),
        matched = ko_matched,
        unmatched = ko_unmatched
      ),
      cpds = list(
        total_in_database = length(db_cpds),
        matched_count = length(cpd_matched),
        unmatched_count = length(cpd_unmatched),
        matched = cpd_matched,
        unmatched = cpd_unmatched
      )
    ),
    pair_support = list(
      total_pairs = nrow(pair_summary),
      class_counts = pair_class_named,
      false_na_pairs_count = nrow(false_na_pairs),
      false_na_pairs_examples = utils::head(false_na_pairs, 50)
    ),
    row_provenance = row_provenance_named,
    consistency_sentinels = list(
      duplicate_full_rows = duplicate_full_rows
    )
  )
}

compute_completeness <- function(database) {
  if (nrow(database) == 0) {
    return(list())
  }
  completeness <- list()
  for (column_name in colnames(database)) {
    column_values <- database[[column_name]]
    missing <- is.na(column_values) | trimws(as.character(column_values)) == ""
    completeness[[column_name]] <- (1 - sum(missing) / nrow(database)) * 100
  }
  completeness
}

links <- build_link_tables(kegg_data)
link_match <- build_link_match(db, links)

metadata <- list(
  database_info = list(
    name = "BioRemPP Database",
    version = args[["version"]],
    generation_date = as.character(Sys.Date()),
    description = "Comprehensive biological remediation database integrating KEGG data, environmental agency compound lists, manual curations, and enzyme classifications"
  ),
  data_sources = list(
    kegg_api = "https://rest.kegg.jp/",
    kegg_release = kegg_info,
    environmental_agencies = "9 agencies",
    manual_curations = "Manually curated compounds and classifications",
    enzyme_terms = "Local curated enzyme activity terms"
  ),
  schema = list(
    columns = list(
      cpd = list(name = "cpd", type = "character", description = "KEGG compound identifier", example = "C00001"),
      compoundclass = list(name = "compoundclass", type = "character", description = "Chemical class of the compound", example = "Organic"),
      ko = list(name = "ko", type = "character", description = "KEGG Orthology identifier", example = "K00001"),
      ec = list(name = "ec", type = "character", description = "Enzyme Commission identifier", example = "1.1.1.1"),
      reaction = list(name = "reaction", type = "character", description = "KEGG reaction identifier", example = "R00623"),
      referenceAG = list(name = "referenceAG", type = "character", description = "Reference environmental agency", example = "EPA"),
      compoundname = list(name = "compoundname", type = "character", description = "Compound name", example = "Water"),
      genesymbol = list(name = "genesymbol", type = "character", description = "Gene symbol", example = "ADH1"),
      genename = list(name = "genename", type = "character", description = "Gene name", example = "alcohol dehydrogenase"),
      enzyme_activity = list(name = "enzyme_activity", type = "character", description = "Extracted enzyme activity term", example = "dehydrogenase")
    )
  ),
  data_quality = list(
    completeness = compute_completeness(db)
  ),
  link_match = link_match
)

write_json_file(metadata, args[["output"]])
log_message("Saved database metadata", "SUCCESS")
