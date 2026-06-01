#!/usr/bin/env Rscript

source("workflow/lib/utils.R")

load_required_packages(c("jsonlite", "dplyr", "stringr"))

args <- parse_cli_args()
require_cli_args(args, c("input-csv", "csv-sep", "kegg-info", "kegg-data", "output", "version"))

db <- read_database_csv(args[["input-csv"]], sep = args[["csv-sep"]])
kegg_info <- read_json_file(args[["kegg-info"]])
kegg_data <- readRDS(args[["kegg-data"]])

normalize_cpd <- function(value) {
  cleaned <- normalize_na_text(value)
  cleaned <- stringr::str_remove(cleaned, stringr::regex("^cpd\\s*:\\s*", ignore_case = TRUE))
  extracted <- stringr::str_extract(cleaned, stringr::regex("C\\d{5}", ignore_case = TRUE))
  dplyr::if_else(is_na_like(extracted), NA_character_, stringr::str_to_upper(extracted))
}

normalize_ko <- function(value) {
  cleaned <- normalize_na_text(value)
  cleaned <- stringr::str_remove(cleaned, stringr::regex("^ko\\s*:\\s*", ignore_case = TRUE))
  extracted <- stringr::str_extract(cleaned, stringr::regex("K\\d{5}", ignore_case = TRUE))
  dplyr::if_else(is_na_like(extracted), NA_character_, stringr::str_to_upper(extracted))
}

normalize_ec <- function(value) {
  cleaned <- normalize_na_text(value)
  cleaned <- stringr::str_remove(cleaned, stringr::regex("^ec\\s*:\\s*", ignore_case = TRUE))
  normalize_na_text(cleaned)
}

normalize_reaction <- function(value) {
  cleaned <- normalize_na_text(value)
  cleaned <- stringr::str_remove(cleaned, stringr::regex("^rn\\s*:\\s*", ignore_case = TRUE))
  extracted <- stringr::str_extract(cleaned, stringr::regex("R\\d{5}", ignore_case = TRUE))
  dplyr::if_else(is_na_like(extracted), NA_character_, stringr::str_to_upper(extracted))
}

sorted_unique <- function(values) {
  unique_values <- unique(values[is_present_value(values)])
  sort(unique_values)
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
      dplyr::distinct(),
    reaction_list = bundle$reaction_list %>%
      dplyr::transmute(
        reaction = normalize_reaction(reaction),
        reaction_description = normalize_na_text(reaction_description_raw)
      ) %>%
      dplyr::filter(!is.na(reaction), !is.na(reaction_description)) %>%
      dplyr::distinct()
  )
}

build_ko_complete <- function(links) {
  links$ko_ec %>%
    dplyr::inner_join(links$ec_reaction, by = "ec", relationship = "many-to-many") %>%
    dplyr::inner_join(links$ko_reaction, by = c("ko", "reaction")) %>%
    dplyr::transmute(ko, ec, reaction) %>%
    dplyr::distinct()
}

compute_completeness <- function(database) {
  if (nrow(database) == 0) {
    return(list())
  }
  completeness <- list()
  for (column_name in colnames(database)) {
    column_values <- database[[column_name]]
    missing <- is_na_like(column_values)
    completeness[[column_name]] <- (1 - sum(missing) / nrow(database)) * 100
  }
  completeness
}

build_link_match <- function(database, links) {
  db_norm <- database %>%
    dplyr::transmute(
      cpd = normalize_cpd(cpd),
      ko = normalize_ko(ko),
      ec = normalize_ec(ec),
      reaction = normalize_reaction(reaction),
      reaction_description = normalize_na_text(reaction_description)
    ) %>%
    dplyr::filter(!is.na(cpd), !is.na(ko))

  db_kos <- sorted_unique(db_norm$ko)
  db_cpds <- sorted_unique(db_norm$cpd)

  ko_supported <- sorted_unique(c(links$ko_ec$ko, links$ko_reaction$ko))
  cpd_supported <- sorted_unique(c(links$cpd_ec$cpd, links$cpd_reaction$cpd))
  ko_complete <- build_ko_complete(links)
  ko_resolvable <- sorted_unique(ko_complete$ko)

  ko_matched <- intersect(db_kos, ko_supported)
  ko_unmatched <- setdiff(db_kos, ko_supported)
  cpd_matched <- intersect(db_cpds, cpd_supported)
  cpd_unmatched <- setdiff(db_cpds, cpd_supported)

  direct_pairs <- dplyr::bind_rows(
    links$ko_ec %>%
      dplyr::inner_join(links$cpd_ec, by = "ec", relationship = "many-to-many") %>%
      dplyr::transmute(cpd, ko),
    links$ko_reaction %>%
      dplyr::inner_join(links$cpd_reaction, by = "reaction", relationship = "many-to-many") %>%
      dplyr::transmute(cpd, ko)
  ) %>%
    dplyr::distinct()
  direct_pair_keys <- paste(direct_pairs$cpd, direct_pairs$ko, sep = "|")

  pair_summary <- db_norm %>%
    dplyr::mutate(
      has_ec = is_present_value(ec),
      has_reaction = is_present_value(reaction),
      dense = has_ec & has_reaction,
      ec_only = has_ec & !has_reaction,
      reaction_only = !has_ec & has_reaction,
      both_na = !has_ec & !has_reaction
    ) %>%
    dplyr::group_by(cpd, ko) %>%
    dplyr::summarise(
      has_dense = any(dense),
      has_ec_only = any(ec_only),
      has_reaction_only = any(reaction_only),
      has_both_na = any(both_na),
      .groups = "drop"
    ) %>%
    dplyr::mutate(
      has_sparse = has_ec_only | has_reaction_only,
      support_direct = paste(cpd, ko, sep = "|") %in% direct_pair_keys,
      support_ko = ko %in% ko_supported,
      support_class = dplyr::case_when(
        support_direct ~ "direct_compound_supported",
        support_ko ~ "ko_supported_only",
        TRUE ~ "unsupported"
      )
    )

  has_ec <- is_present_value(db_norm$ec)
  has_reaction <- is_present_value(db_norm$reaction)
  row_shape_counts <- list(
    dense = as.integer(sum(has_ec & has_reaction)),
    ec_only = as.integer(sum(has_ec & !has_reaction)),
    reaction_only = as.integer(sum(!has_ec & has_reaction)),
    both_na = as.integer(sum(!has_ec & !has_reaction))
  )

  false_na_pairs <- pair_summary %>%
    dplyr::filter(!has_dense, !has_sparse, has_both_na, support_ko) %>%
    dplyr::select(cpd, ko)

  resolvable_pairs <- pair_summary %>%
    dplyr::filter(ko %in% ko_resolvable)
  mixed_sparse_on_resolvable <- resolvable_pairs %>%
    dplyr::filter(has_sparse | has_both_na) %>%
    dplyr::select(cpd, ko, has_dense, has_ec_only, has_reaction_only, has_both_na)

  cpd_ec_keys <- paste(links$cpd_ec$cpd, links$cpd_ec$ec, sep = "|")
  cpd_reaction_keys <- paste(links$cpd_reaction$cpd, links$cpd_reaction$reaction, sep = "|")
  ko_ec_keys <- paste(links$ko_ec$ko, links$ko_ec$ec, sep = "|")
  ko_reaction_keys <- paste(links$ko_reaction$ko, links$ko_reaction$reaction, sep = "|")
  ko_complete_keys <- paste(ko_complete$ko, ko_complete$ec, ko_complete$reaction, sep = "|")

  row_provenance <- db_norm %>%
    dplyr::mutate(
      has_ec = is_present_value(ec),
      has_reaction = is_present_value(reaction),
      dense = has_ec & has_reaction,
      cpd_ec_key = paste(cpd, ec, sep = "|"),
      cpd_reaction_key = paste(cpd, reaction, sep = "|"),
      ko_ec_key = paste(ko, ec, sep = "|"),
      ko_reaction_key = paste(ko, reaction, sep = "|"),
      ko_complete_key = paste(ko, ec, reaction, sep = "|"),
      is_direct = dplyr::case_when(
        dense ~ (cpd_ec_key %in% cpd_ec_keys) | (cpd_reaction_key %in% cpd_reaction_keys),
        has_ec ~ cpd_ec_key %in% cpd_ec_keys,
        has_reaction ~ cpd_reaction_key %in% cpd_reaction_keys,
        TRUE ~ FALSE
      ),
      is_ko_supported = dplyr::case_when(
        dense ~ (ko_complete_key %in% ko_complete_keys) | ((ko_ec_key %in% ko_ec_keys) & (ko_reaction_key %in% ko_reaction_keys)),
        has_ec ~ ko_ec_key %in% ko_ec_keys,
        has_reaction ~ ko_reaction_key %in% ko_reaction_keys,
        TRUE ~ ko %in% ko_supported
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

  duplicate_full_rows <- as.integer(nrow(database) - nrow(dplyr::distinct(database)))
  # counts duplicate 5-col link signatures (cpd+ko+ec+reaction+reaction_description), non-NA cpd+ko only
  duplicate_link_signature_rows <- as.integer(nrow(db_norm) - nrow(dplyr::distinct(db_norm)))

  list(
    policy = list(
      source_of_truth = "KEGG REST API",
      mapping_join_key = "cpd+ko",
      reference_ag_join_key = FALSE,
      replicate_by_reference_ag = TRUE,
      ko_dense_priority = TRUE,
      synthetic_ec_reaction_cartesian = TRUE,
      ko_fallback_pairing_for_non_resolvable = TRUE,
      compound_bridge_fallback = TRUE
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
    row_shapes = row_shape_counts,
    row_provenance = row_provenance_named,
    consistency_sentinels = list(
      duplicate_full_rows = duplicate_full_rows,
      duplicate_link_signature_rows = duplicate_link_signature_rows,
      resolvable_pair_count = nrow(resolvable_pairs),
      mixed_sparse_on_resolvable_pairs = nrow(mixed_sparse_on_resolvable),
      mixed_sparse_on_resolvable_examples = utils::head(mixed_sparse_on_resolvable, 50)
    ),
    reaction_description = list(
      with_reaction_rows = as.integer(sum(is_present_value(db_norm$reaction))),
      with_reaction_description_rows = as.integer(sum(is_present_value(db_norm$reaction_description))),
      unmatched_reaction_id_count = as.integer({
        reaction_ids_in_db <- sort(unique(db_norm$reaction[is_present_value(db_norm$reaction)]))
        reaction_ids_with_description <- sort(unique(links$reaction_list$reaction))
        length(setdiff(reaction_ids_in_db, reaction_ids_with_description))
      })
    )
  )
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
      reaction_description = list(
        name = "reaction_description",
        type = "character",
        description = "KEGG reaction textual description and equation",
        example = "polyphosphate polyphosphohydrolase; Polyphosphate + n H2O <=> (n+1) Oligophosphate"
      ),
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
