#!/usr/bin/env Rscript

source("workflow/lib/utils.R")
source("workflow/lib/io_contracts.R")

load_required_packages(c("jsonlite"))

args <- parse_cli_args()
require_cli_args(args, c("input-dir", "output"))

input_dir <- args[["input-dir"]]
output_file <- args[["output"]]

if (!dir.exists(input_dir)) {
  stop("Input directory not found: ", input_dir, call. = FALSE)
}

present_files <- REQUIRED_INPUT_FILES[file.exists(file.path(input_dir, REQUIRED_INPUT_FILES))]
missing_files <- REQUIRED_INPUT_FILES[!file.exists(file.path(input_dir, REQUIRED_INPUT_FILES))]

if (length(missing_files) > 0) {
  stop(
    "Missing required input files: ",
    paste(missing_files, collapse = ", "),
    call. = FALSE
  )
}

report <- list(
  status = "ok",
  input_dir = normalizePath(input_dir),
  present_files = unname(present_files),
  checked_at_utc = format(as.POSIXct(Sys.time(), tz = "UTC"), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
)

write_json_file(report, output_file)
log_message(sprintf("Validated %d input files", length(present_files)), "SUCCESS")
