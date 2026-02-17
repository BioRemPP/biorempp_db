#!/usr/bin/env Rscript

source("workflow/lib/utils.R")

load_required_packages(c("dplyr", "jsonlite"))

args <- parse_cli_args()
require_cli_args(args, c("input-csv", "output", "config"))

db <- read.csv(args[["input-csv"]], stringsAsFactors = FALSE)

genesymbol_frequency <- db %>%
  dplyr::group_by(genesymbol) %>%
  dplyr::summarise(frequency = dplyr::n(), .groups = "drop") %>%
  dplyr::arrange(dplyr::desc(frequency))

top_genesymbols <- utils::head(genesymbol_frequency, 20)

genename_frequency <- db %>%
  dplyr::group_by(genename) %>%
  dplyr::summarise(frequency = dplyr::n(), .groups = "drop") %>%
  dplyr::arrange(dplyr::desc(frequency))

top_genenames <- utils::head(genename_frequency, 20)

stats <- list(
  total_unique_genesymbols = length(unique(db$genesymbol)),
  total_unique_genenames = length(unique(db$genename)),
  top_20_genesymbols = list(
    symbols = top_genesymbols$genesymbol,
    frequencies = top_genesymbols$frequency
  ),
  top_20_genenames = list(
    names = top_genenames$genename,
    frequencies = top_genenames$frequency
  )
)

write_json_file(stats, args[["output"]])
log_message("Saved gene statistics", "SUCCESS")
