#!/usr/bin/env Rscript

source("workflow/lib/utils.R")
source("workflow/lib/io_contracts.R")

load_required_packages(c("stringr"))

args <- parse_cli_args()
require_cli_args(args, c("output", "config", "base-url"))

output_file <- args[["output"]]
base_url <- sub("/$", "", args[["base-url"]])

fetch_endpoint_raw <- function(endpoint, sep = "\t", max_retries = 3) {
  url <- paste0(base_url, "/", endpoint)

  for (attempt in seq_len(max_retries)) {
    result <- tryCatch(
      {
        read.delim(
          url,
          header = FALSE,
          sep = sep,
          stringsAsFactors = FALSE,
          quote = "",
          fill = TRUE,
          comment.char = ""
        )
      },
      error = function(e) {
        if (attempt == max_retries) {
          stop(sprintf("Failed to fetch %s after %d attempts: %s", endpoint, max_retries, e$message), call. = FALSE)
        }
        Sys.sleep(attempt)
        NULL
      }
    )

    if (!is.null(result)) {
      return(result)
    }
  }

  stop("Unreachable retry state for endpoint: ", endpoint, call. = FALSE)
}

all_values_match <- function(values, pattern) {
  clean <- trimws(as.character(values))
  if (length(clean) == 0) {
    return(FALSE)
  }
  non_empty <- !is.na(clean) & clean != ""
  if (!all(non_empty)) {
    return(FALSE)
  }
  all(grepl(pattern, clean, ignore.case = TRUE))
}

canonicalize_link_endpoint <- function(endpoint_name, data_frame) {
  expected_columns <- KEGG_ENDPOINTS[[endpoint_name]]$columns

  if (!is.data.frame(data_frame)) {
    stop(sprintf("Endpoint %s did not return a data.frame.", endpoint_name), call. = FALSE)
  }
  if (nrow(data_frame) < 1) {
    stop(sprintf("Endpoint %s returned zero rows.", endpoint_name), call. = FALSE)
  }
  if (ncol(data_frame) < 2) {
    stop(
      sprintf(
        "Endpoint %s returned fewer than 2 columns (got %d).",
        endpoint_name,
        ncol(data_frame)
      ),
      call. = FALSE
    )
  }

  col_a <- data_frame[[1]]
  col_b <- data_frame[[2]]

  if (endpoint_name == "compound_list") {
    col_a_is_cpd <- all_values_match(col_a, KEGG_VALUE_PATTERNS$cpd)
    col_b_is_cpd <- all_values_match(col_b, KEGG_VALUE_PATTERNS$cpd)

    if (col_a_is_cpd && !col_b_is_cpd) {
      canonical <- data.frame(cpd = col_a, compoundname = col_b, stringsAsFactors = FALSE)
    } else if (col_b_is_cpd && !col_a_is_cpd) {
      canonical <- data.frame(cpd = col_b, compoundname = col_a, stringsAsFactors = FALSE)
    } else {
      stop(
        sprintf(
          "Endpoint %s has invalid orientation/content for columns cpd/compoundname. Sample: '%s' | '%s'.",
          endpoint_name,
          as.character(col_a[[1]]),
          as.character(col_b[[1]])
        ),
        call. = FALSE
      )
    }

    names_clean <- trimws(as.character(canonical$compoundname))
    if (any(is.na(names_clean) | names_clean == "")) {
      stop(
        sprintf("Endpoint %s has empty compound names.", endpoint_name),
        call. = FALSE
      )
    }
    return(canonical)
  }

  if (length(expected_columns) != 2) {
    stop(sprintf("Endpoint %s expected 2 canonical columns.", endpoint_name), call. = FALSE)
  }

  first_name <- expected_columns[[1]]
  second_name <- expected_columns[[2]]
  first_pattern <- KEGG_VALUE_PATTERNS[[first_name]]
  second_pattern <- KEGG_VALUE_PATTERNS[[second_name]]

  if (is.null(first_pattern) || is.null(second_pattern)) {
    stop(sprintf("Endpoint %s has missing value pattern mapping.", endpoint_name), call. = FALSE)
  }

  first_is_first <- all_values_match(col_a, first_pattern)
  second_is_second <- all_values_match(col_b, second_pattern)
  first_is_second <- all_values_match(col_a, second_pattern)
  second_is_first <- all_values_match(col_b, first_pattern)

  canonical <- NULL
  if (first_is_first && second_is_second) {
    canonical <- data.frame(col_a, col_b, stringsAsFactors = FALSE)
  } else if (first_is_second && second_is_first) {
    canonical <- data.frame(col_b, col_a, stringsAsFactors = FALSE)
  } else {
    stop(
      sprintf(
        "Endpoint %s failed structural validation/orientation. Sample: '%s' | '%s'.",
        endpoint_name,
        as.character(col_a[[1]]),
        as.character(col_b[[1]])
      ),
      call. = FALSE
    )
  }

  colnames(canonical) <- expected_columns
  canonical
}

validate_kegg_bundle <- function(bundle) {
  endpoint_names <- names(KEGG_ENDPOINTS)
  for (endpoint_name in endpoint_names) {
    if (!endpoint_name %in% names(bundle)) {
      stop(sprintf("Missing endpoint in KEGG bundle: %s", endpoint_name), call. = FALSE)
    }
    if (!is.data.frame(bundle[[endpoint_name]]) || nrow(bundle[[endpoint_name]]) < 1) {
      stop(sprintf("Endpoint %s bundle is empty or invalid.", endpoint_name), call. = FALSE)
    }
  }
  invisible(TRUE)
}

fetch_and_normalize_endpoint <- function(endpoint_name) {
  endpoint_cfg <- KEGG_ENDPOINTS[[endpoint_name]]
  raw <- fetch_endpoint_raw(endpoint_cfg$endpoint, endpoint_cfg$sep)
  canonicalize_link_endpoint(endpoint_name, raw)
}

kegg_data <- list(
  ko_ec_links = fetch_and_normalize_endpoint("ko_ec_links"),
  ko_reaction_links = fetch_and_normalize_endpoint("ko_reaction_links"),
  compound_ec_links = fetch_and_normalize_endpoint("compound_ec_links"),
  compound_reaction_links = fetch_and_normalize_endpoint("compound_reaction_links"),
  ec_reaction_links = fetch_and_normalize_endpoint("ec_reaction_links"),
  compound_list = fetch_and_normalize_endpoint("compound_list")
)

validate_kegg_bundle(kegg_data)
kegg_data$compound_list$compoundname <- sub(";.*$", "", kegg_data$compound_list$compoundname)

ensure_parent_dir(output_file)
saveRDS(kegg_data, output_file)
log_message(sprintf("Saved KEGG data bundle to %s", output_file), "SUCCESS")
