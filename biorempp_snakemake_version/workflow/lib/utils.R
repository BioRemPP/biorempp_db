#!/usr/bin/env Rscript

load_required_packages <- function(required_packages) {
  missing <- vapply(required_packages, function(pkg) {
    !requireNamespace(pkg, quietly = TRUE)
  }, logical(1))

  missing_names <- names(missing[missing])
  if (length(missing_names) > 0) {
    stop(
      "Missing required packages: ",
      paste(missing_names, collapse = ", "),
      "\nInstall with: install.packages(c('",
      paste(missing_names, collapse = "', '"),
      "'))",
      call. = FALSE
    )
  }

  suppressPackageStartupMessages({
    for (pkg in required_packages) {
      library(pkg, character.only = TRUE)
    }
  })

  invisible(NULL)
}

parse_cli_args <- function(args = commandArgs(trailingOnly = TRUE)) {
  if (length(args) %% 2 != 0) {
    stop("Arguments must be provided as --key value pairs.", call. = FALSE)
  }

  parsed <- list()
  i <- 1
  while (i <= length(args)) {
    key <- args[[i]]
    value <- args[[i + 1]]

    if (!startsWith(key, "--")) {
      stop("Invalid argument key: ", key, call. = FALSE)
    }

    parsed[[sub("^--", "", key)]] <- value
    i <- i + 2
  }

  parsed
}

require_cli_args <- function(parsed_args, required_keys) {
  missing <- required_keys[!required_keys %in% names(parsed_args)]
  if (length(missing) > 0) {
    stop("Missing required arguments: ", paste(missing, collapse = ", "), call. = FALSE)
  }
}

log_message <- function(msg, level = "INFO") {
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  message(sprintf("%s [%s] %s", timestamp, level, msg))
}

ensure_parent_dir <- function(path) {
  parent <- dirname(path)
  if (!dir.exists(parent)) {
    dir.create(parent, recursive = TRUE)
  }
  invisible(TRUE)
}

write_json_file <- function(object, path) {
  ensure_parent_dir(path)
  jsonlite::write_json(object, path, pretty = TRUE, auto_unbox = TRUE)
}

read_json_file <- function(path) {
  if (!file.exists(path)) {
    stop("JSON file not found: ", path, call. = FALSE)
  }
  jsonlite::fromJSON(path, simplifyVector = FALSE)
}
