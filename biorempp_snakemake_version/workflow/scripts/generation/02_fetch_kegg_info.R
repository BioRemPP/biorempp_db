#!/usr/bin/env Rscript

source("workflow/lib/utils.R")

load_required_packages(c("jsonlite", "stringr"))

args <- parse_cli_args()
require_cli_args(args, c("output", "config", "base-url", "endpoint"))

output_file <- args[["output"]]
base_url <- sub("/$", "", args[["base-url"]])
endpoint <- sub("^/", "", args[["endpoint"]])
source_url <- paste0(base_url, "/", endpoint)

response <- tryCatch(
  readLines(source_url, warn = FALSE),
  error = function(e) {
    stop("Failed to fetch KEGG info endpoint: ", e$message, call. = FALSE)
  }
)

if (length(response) == 0) {
  stop("Empty response from KEGG info endpoint.", call. = FALSE)
}

release_line <- response[grepl("Release", response, ignore.case = TRUE)]
release_text <- if (length(release_line) > 0) release_line[[1]] else response[[1]]

parsed_version <- stringr::str_extract(release_text, "[0-9]+(?:\\.[0-9]+)?(?:\\+)?")
if (is.na(parsed_version) || parsed_version == "") {
  parsed_version <- "unknown"
}

result <- list(
  release_text = release_text,
  parsed_version = parsed_version,
  retrieved_at_utc = format(as.POSIXct(Sys.time(), tz = "UTC"), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
  source_url = source_url,
  raw_response = response
)

write_json_file(result, output_file)
log_message(sprintf("Saved KEGG release metadata to %s", output_file), "SUCCESS")
