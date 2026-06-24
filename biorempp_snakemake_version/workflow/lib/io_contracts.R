#!/usr/bin/env Rscript

REQUIRED_INPUT_FILES <- c(
  "kegglistcompounds.xlsx",
  "curated_regulated_compounds.xlsx",
  "curated_programatic_missing_compounds.xlsx",
  "curated_compound_classes.xlsx",
  "kegglistko.txt",
  "curated_enzyem_names_extracted.txt"
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
  "enzyme_activity",
  "support_stage"
)

KEGG_ENDPOINTS <- list(
  ko_ec_links = list(endpoint = "link/ko/ec", columns = c("ko", "ec"), sep = "\t"),
  ko_reaction_links = list(endpoint = "link/ko/reaction", columns = c("ko", "reaction"), sep = "\t"),
  compound_ec_links = list(endpoint = "link/compound/ec", columns = c("cpd", "ec"), sep = "\t"),
  compound_reaction_links = list(endpoint = "link/compound/reaction", columns = c("cpd", "reaction"), sep = "\t"),
  ec_reaction_links = list(endpoint = "link/enzyme/reaction", columns = c("ec", "reaction"), sep = "\t"),
  reaction_list = list(endpoint = "list/reaction", columns = c("reaction", "reaction_description_raw"), sep = "\t"),
  compound_list = list(endpoint = "list/cpd/", columns = c("cpd", "compoundname"), sep = "\t")
)

KEGG_VALUE_PATTERNS <- list(
  ko = "^(ko:)?K\\d{5}$",
  ec = "^(ec:)?[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9A-Za-z\\-]+$",
  reaction = "^(rn:)?R\\d{5}$",
  cpd = "^(cpd:)?C\\d{5}$"
)
