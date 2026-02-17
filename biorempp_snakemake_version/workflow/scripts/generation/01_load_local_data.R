#!/usr/bin/env Rscript

source("workflow/lib/utils.R")
source("workflow/lib/io_contracts.R")

load_required_packages(c("readxl", "dplyr", "stringr"))

args <- parse_cli_args()
require_cli_args(args, c("input-dir", "output", "config"))

input_dir <- args[["input-dir"]]
output_file <- args[["output"]]

missing_files <- REQUIRED_INPUT_FILES[!file.exists(file.path(input_dir, REQUIRED_INPUT_FILES))]
if (length(missing_files) > 0) {
  stop("Missing required input files: ", paste(missing_files, collapse = ", "), call. = FALSE)
}

load_kegg_compounds <- function(base_dir) {
  file_path <- file.path(base_dir, "kegglistcompounds.xlsx")
  data <- readxl::read_excel(file_path, col_names = FALSE)
  colnames(data) <- c("cpd", "compoundname")
  data
}

load_agency_compounds <- function(base_dir) {
  file_path <- file.path(base_dir, "compostos_todasagencias.xlsx")
  data <- readxl::read_excel(file_path, col_names = FALSE)
  colnames(data) <- c("cpd", "referenceAG")
  data
}

load_curated_compounds <- function(base_dir) {
  file_path <- file.path(base_dir, "missing_compounds_founds_curated.xlsx")
  data <- readxl::read_excel(file_path)
  colnames(data) <- c("cpd", "ko")
  data[, c("cpd", "ko")]
}

load_compound_classes <- function(base_dir) {
  file_path <- file.path(base_dir, "confirm_class_CURATED.xlsx")
  readxl::read_excel(file_path)
}

load_kegg_ko_list <- function(base_dir) {
  file_path <- file.path(base_dir, "kegglistko.txt")
  data <- read.delim(
    file = file_path,
    header = TRUE,
    sep = "\t",
    stringsAsFactors = FALSE,
    quote = "\"",
    fill = TRUE,
    comment.char = ""
  )
  names(data) <- tolower(names(data))
  data[, c("ko", "genesymbol", "genename")]
}

load_enzyme_terms <- function(base_dir) {
  file_path <- file.path(base_dir, "enzymes_unique.txt")
  terms <- readLines(file_path, warn = FALSE)
  terms <- trimws(terms)
  unique(terms[terms != ""])
}

local_data <- list(
  kegg_compounds = load_kegg_compounds(input_dir),
  agency_compounds = load_agency_compounds(input_dir),
  curated_compounds = load_curated_compounds(input_dir),
  compound_classes = load_compound_classes(input_dir),
  ko_list = load_kegg_ko_list(input_dir),
  enzyme_terms = load_enzyme_terms(input_dir)
)

ensure_parent_dir(output_file)
saveRDS(local_data, output_file)

log_message(sprintf("Saved local data bundle to %s", output_file), "SUCCESS")
