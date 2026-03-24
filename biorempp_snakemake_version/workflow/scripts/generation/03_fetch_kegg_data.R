#!/usr/bin/env Rscript

source("workflow/lib/utils.R")
source("workflow/lib/io_contracts.R")

load_required_packages(c("readr", "stringr"))

args <- parse_cli_args()
require_cli_args(args, c("output", "config", "base-url"))

output_file <- args[["output"]]
base_url <- sub("/$", "", args[["base-url"]])

fetch_endpoint <- function(endpoint, columns, sep = "\t", max_retries = 3) {
  url <- paste0(base_url, "/", endpoint)

  for (attempt in seq_len(max_retries)) {
    result <- tryCatch(
      {
        read.csv(
          url,
          header = FALSE,
          sep = sep,
          col.names = columns,
          stringsAsFactors = FALSE,
          quote = ""
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

validate_endpoint_structure <- function(endpoint_name, data_frame) {
  expected_columns <- KEGG_ENDPOINTS[[endpoint_name]]$columns
  prefix_rules <- KEGG_ENDPOINT_PREFIX_RULES[[endpoint_name]]

  if (!is.data.frame(data_frame)) {
    stop(sprintf("Endpoint %s did not return a data.frame.", endpoint_name), call. = FALSE)
  }
  if (!identical(colnames(data_frame), expected_columns)) {
    stop(
      sprintf(
        "Endpoint %s returned unexpected columns. Expected [%s], got [%s].",
        endpoint_name,
        paste(expected_columns, collapse = ", "),
        paste(colnames(data_frame), collapse = ", ")
      ),
      call. = FALSE
    )
  }
  if (nrow(data_frame) < 1) {
    stop(sprintf("Endpoint %s returned zero rows.", endpoint_name), call. = FALSE)
  }

  for (column_name in names(prefix_rules)) {
    values <- trimws(as.character(data_frame[[column_name]]))
    invalid <- is.na(values) | values == "" | !grepl(prefix_rules[[column_name]], values, ignore.case = TRUE)
    if (any(invalid)) {
      sample_invalid <- unique(values[invalid])[1]
      stop(
        sprintf(
          "Endpoint %s failed structural validation in column '%s'. Invalid rows: %d. Example: '%s'.",
          endpoint_name,
          column_name,
          sum(invalid),
          sample_invalid
        ),
        call. = FALSE
      )
    }
  }

  if ("compoundname" %in% colnames(data_frame)) {
    names_raw <- trimws(as.character(data_frame$compoundname))
    invalid_names <- is.na(names_raw) | names_raw == ""
    if (any(invalid_names)) {
      stop(
        sprintf(
          "Endpoint %s has empty compound names (%d rows).",
          endpoint_name,
          sum(invalid_names)
        ),
        call. = FALSE
      )
    }
  }

  invisible(TRUE)
}

validate_kegg_bundle <- function(bundle) {
  endpoint_names <- names(KEGG_ENDPOINT_PREFIX_RULES)
  for (endpoint_name in endpoint_names) {
    if (!endpoint_name %in% names(bundle)) {
      stop(sprintf("Missing endpoint in KEGG bundle: %s", endpoint_name), call. = FALSE)
    }
    validate_endpoint_structure(endpoint_name, bundle[[endpoint_name]])
  }
  invisible(TRUE)
}

kegg_data <- list(
  ko_ec_links = fetch_endpoint(KEGG_ENDPOINTS$ko_ec_links$endpoint, KEGG_ENDPOINTS$ko_ec_links$columns, KEGG_ENDPOINTS$ko_ec_links$sep),
  ko_reaction_links = fetch_endpoint(KEGG_ENDPOINTS$ko_reaction_links$endpoint, KEGG_ENDPOINTS$ko_reaction_links$columns, KEGG_ENDPOINTS$ko_reaction_links$sep),
  compound_ec_links = fetch_endpoint(KEGG_ENDPOINTS$compound_ec_links$endpoint, KEGG_ENDPOINTS$compound_ec_links$columns, KEGG_ENDPOINTS$compound_ec_links$sep),
  compound_reaction_links = fetch_endpoint(KEGG_ENDPOINTS$compound_reaction_links$endpoint, KEGG_ENDPOINTS$compound_reaction_links$columns, KEGG_ENDPOINTS$compound_reaction_links$sep),
  compound_list = fetch_endpoint(KEGG_ENDPOINTS$compound_list$endpoint, KEGG_ENDPOINTS$compound_list$columns, KEGG_ENDPOINTS$compound_list$sep)
)

validate_kegg_bundle(kegg_data)
kegg_data$compound_list$compoundname <- sub(";.*$", "", kegg_data$compound_list$compoundname)

ensure_parent_dir(output_file)
saveRDS(kegg_data, output_file)
log_message(sprintf("Saved KEGG data bundle to %s", output_file), "SUCCESS")
