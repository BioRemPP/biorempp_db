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

kegg_data <- list(
  ko_ec_links = fetch_endpoint(KEGG_ENDPOINTS$ko_ec_links$endpoint, KEGG_ENDPOINTS$ko_ec_links$columns, KEGG_ENDPOINTS$ko_ec_links$sep),
  ko_reaction_links = fetch_endpoint(KEGG_ENDPOINTS$ko_reaction_links$endpoint, KEGG_ENDPOINTS$ko_reaction_links$columns, KEGG_ENDPOINTS$ko_reaction_links$sep),
  compound_ec_links = fetch_endpoint(KEGG_ENDPOINTS$compound_ec_links$endpoint, KEGG_ENDPOINTS$compound_ec_links$columns, KEGG_ENDPOINTS$compound_ec_links$sep),
  compound_reaction_links = fetch_endpoint(KEGG_ENDPOINTS$compound_reaction_links$endpoint, KEGG_ENDPOINTS$compound_reaction_links$columns, KEGG_ENDPOINTS$compound_reaction_links$sep),
  compound_list = fetch_endpoint(KEGG_ENDPOINTS$compound_list$endpoint, KEGG_ENDPOINTS$compound_list$columns, KEGG_ENDPOINTS$compound_list$sep)
)

kegg_data$compound_list$compoundname <- sub(";.*$", "", kegg_data$compound_list$compoundname)

ensure_parent_dir(output_file)
saveRDS(kegg_data, output_file)
log_message(sprintf("Saved KEGG data bundle to %s", output_file), "SUCCESS")
