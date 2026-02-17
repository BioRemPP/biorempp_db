#!/usr/bin/env Rscript

REQUIRED_INPUT_FILES <- c(
  "kegglistcompounds.xlsx",
  "compostos_todasagencias.xlsx",
  "missing_compounds_founds_curated.xlsx",
  "confirm_class_CURATED.xlsx",
  "kegglistko.txt",
  "enzymes_unique.txt"
)

EXPECTED_DATABASE_COLUMNS <- c(
  "cpd",
  "compoundclass",
  "ko",
  "referenceAG",
  "compoundname",
  "genesymbol",
  "genename",
  "enzyme_activity"
)

KEGG_ENDPOINTS <- list(
  ko_ec_links = list(endpoint = "link/ko/ec", columns = c("ec", "ko"), sep = ""),
  ko_reaction_links = list(endpoint = "link/ko/reaction", columns = c("reaction", "ko"), sep = ""),
  compound_ec_links = list(endpoint = "link/compound/ec", columns = c("ec", "cpd"), sep = ""),
  compound_reaction_links = list(endpoint = "link/cpd/reaction", columns = c("reaction", "cpd"), sep = ""),
  compound_list = list(endpoint = "list/cpd/", columns = c("cpd", "compoundname"), sep = "\t")
)
