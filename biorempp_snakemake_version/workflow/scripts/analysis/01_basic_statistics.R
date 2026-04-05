#!/usr/bin/env Rscript

source("workflow/lib/utils.R")

load_required_packages(c("jsonlite"))

args <- parse_cli_args()
require_cli_args(args, c("input-csv", "csv-sep", "output", "config"))

db <- read_database_csv(args[["input-csv"]], sep = args[["csv-sep"]])

stats <- list(
  total_entries = nrow(db),
  total_columns = ncol(db),
  column_names = colnames(db),
  unique_compounds = length(unique(db$cpd)),
  unique_ko_entries = length(unique(db$ko)),
  unique_compound_classes = length(unique(db$compoundclass)),
  unique_gene_symbols = length(unique(db$genesymbol)),
  unique_gene_names = length(unique(db$genename)),
  unique_enzyme_activities = length(unique(db$enzyme_activity)),
  unique_reference_agencies = length(unique(db$referenceAG)),
  missing_values = list(
    cpd = sum(is.na(db$cpd)),
    compoundclass = sum(is.na(db$compoundclass)),
    ko = sum(is.na(db$ko)),
    ec = sum(is.na(db$ec)),
    reaction = sum(is.na(db$reaction)),
    reaction_description = sum(is.na(db$reaction_description)),
    referenceAG = sum(is.na(db$referenceAG)),
    compoundname = sum(is.na(db$compoundname)),
    genesymbol = sum(is.na(db$genesymbol)),
    genename = sum(is.na(db$genename)),
    enzyme_activity = sum(is.na(db$enzyme_activity))
  )
)

write_json_file(stats, args[["output"]])
log_message("Saved basic statistics", "SUCCESS")
