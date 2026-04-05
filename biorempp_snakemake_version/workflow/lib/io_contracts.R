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
  "ec",
  "reaction",
  "reaction_description",
  "referenceAG",
  "compoundname",
  "genesymbol",
  "genename",
  "enzyme_activity"
)

KEGG_ENDPOINTS <- list(
  ko_ec_links = list(endpoint = "link/ko/ec", columns = c("ko", "ec"), sep = "\t"),
  ko_reaction_links = list(endpoint = "link/ko/reaction", columns = c("ko", "reaction"), sep = "\t"),
  compound_ec_links = list(endpoint = "link/compound/ec", columns = c("cpd", "ec"), sep = "\t"),
  compound_reaction_links = list(endpoint = "link/cpd/reaction", columns = c("cpd", "reaction"), sep = "\t"),
  ec_reaction_links = list(endpoint = "link/ec/reaction", columns = c("ec", "reaction"), sep = "\t"),
  reaction_list = list(endpoint = "list/reaction", columns = c("reaction", "reaction_description_raw"), sep = "\t"),
  compound_list = list(endpoint = "list/cpd/", columns = c("cpd", "compoundname"), sep = "\t")
)

KEGG_VALUE_PATTERNS <- list(
  ko = "^(ko:)?K\\d{5}$",
  ec = "^(ec:)?[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9A-Za-z\\-]+$",
  reaction = "^(rn:)?R\\d{5}$",
  cpd = "^(cpd:)?C\\d{5}$"
)
