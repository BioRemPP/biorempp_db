#!/usr/bin/env Rscript

source("workflow/lib/utils.R")

load_required_packages(c("jsonlite"))

args <- parse_cli_args()
require_cli_args(args, c("input-csv", "kegg-info", "output", "version", "config"))

db <- read.csv(args[["input-csv"]], stringsAsFactors = FALSE)
kegg_info <- read_json_file(args[["kegg-info"]])

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
      referenceAG = list(name = "referenceAG", type = "character", description = "Reference environmental agency", example = "EPA"),
      compoundname = list(name = "compoundname", type = "character", description = "Compound name", example = "Water"),
      genesymbol = list(name = "genesymbol", type = "character", description = "Gene symbol", example = "ADH1"),
      genename = list(name = "genename", type = "character", description = "Gene name", example = "alcohol dehydrogenase"),
      enzyme_activity = list(name = "enzyme_activity", type = "character", description = "Extracted enzyme activity term", example = "dehydrogenase")
    )
  ),
  data_quality = list(
    completeness = list(
      cpd = (1 - sum(is.na(db$cpd)) / nrow(db)) * 100,
      compoundclass = (1 - sum(is.na(db$compoundclass)) / nrow(db)) * 100,
      ko = (1 - sum(is.na(db$ko)) / nrow(db)) * 100,
      referenceAG = (1 - sum(is.na(db$referenceAG)) / nrow(db)) * 100,
      compoundname = (1 - sum(is.na(db$compoundname)) / nrow(db)) * 100,
      genesymbol = (1 - sum(is.na(db$genesymbol)) / nrow(db)) * 100,
      genename = (1 - sum(is.na(db$genename)) / nrow(db)) * 100,
      enzyme_activity = (1 - sum(is.na(db$enzyme_activity)) / nrow(db)) * 100
    )
  )
)

write_json_file(metadata, args[["output"]])
log_message("Saved database metadata", "SUCCESS")
