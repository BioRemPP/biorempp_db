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
  "referenceAG",
  "compoundname",
  "genesymbol",
  "genename",
  "enzyme_activity"
)

KEGG_ENDPOINTS <- list(
  ko_ec_links = list(endpoint = "link/ko/ec", columns = c("ec", "ko"), sep = "\t"),
  ko_reaction_links = list(endpoint = "link/ko/reaction", columns = c("reaction", "ko"), sep = "\t"),
  compound_ec_links = list(endpoint = "link/compound/ec", columns = c("ec", "cpd"), sep = "\t"),
  compound_reaction_links = list(endpoint = "link/cpd/reaction", columns = c("reaction", "cpd"), sep = "\t"),
  compound_list = list(endpoint = "list/cpd/", columns = c("cpd", "compoundname"), sep = "\t")
)

KEGG_ENDPOINT_PREFIX_RULES <- list(
  ko_ec_links = c(ec = "^ec:", ko = "^ko:"),
  ko_reaction_links = c(reaction = "^rn:", ko = "^ko:"),
  compound_ec_links = c(ec = "^ec:", cpd = "^cpd:"),
  compound_reaction_links = c(reaction = "^rn:", cpd = "^cpd:"),
  compound_list = c(cpd = "^C\\d{5}$")
)
