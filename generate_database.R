################################################################################
# BioRemPP Database Generator v1.0.0
################################################################################
#
# Purpose: Generate comprehensive biological remediation database by integrating
#          KEGG data, environmental agency compound lists, manual curations,
#          compound classifications, and enzyme activity extraction
#
# Author: BioRemPP Development Team
# Version: 1.0.0
#
# Working Directory: Must be set to the project root directory before execution
#
# Directory Structure:
#   ./ (project root)
#   ├── generate_database.R (this script)
#   ├── input_data/
#   │   ├── kegglistcompounds.xlsx
#   │   ├── curated_regulated_compounds.xlsx
#   │   ├── curated_programatic_missing_compounds.xlsx
#   │   ├── confirm_class_CURATED.xlsx
#   │   ├── kegglistko.txt
#   │   └── curated_enzyem_names_extracted.txt
#   └── output_data/ (generated files saved here)
#
################################################################################

# ==============================================================================
# SECTION 1: ENVIRONMENT SETUP AND DEPENDENCIES
# ==============================================================================

#' Set Working Directory to Script Location
#' 
#' Automatically detects and sets working directory to script location.
#' Works in RStudio and command-line (Rscript) execution.
#' 
#' @return Invisibly returns the working directory path
set_working_directory_to_script <- function() {
  # Try RStudio API first
  if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
    script_path <- rstudioapi::getActiveDocumentContext()$path
    if (!is.null(script_path) && nzchar(script_path)) {
      setwd(dirname(script_path))
      return(invisible(getwd()))
    }
  }
  
  # Try Rscript command-line arguments
  args <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("^--file=", args, value = TRUE)
  if (length(file_arg) > 0) {
    script_path <- sub("^--file=", "", file_arg[1])
    setwd(dirname(normalizePath(script_path)))
    return(invisible(getwd()))
  }
  
  stop("Could not detect script path. Please set working directory manually with setwd().")
}

# Set working directory
set_working_directory_to_script()
message("✓ Working directory set to: ", getwd())


#' Load Required R Packages
#' 
#' Loads all necessary packages for database generation.
#' Stops execution with informative error if any package is missing.
load_required_packages <- function() {
  required_packages <- c("readxl", "dplyr", "tidyr", "stringr", "readr", "writexl")
  
  missing_packages <- c()
  for (pkg in required_packages) {
    if (!requireNamespace(pkg, quietly = TRUE)) {
      missing_packages <- c(missing_packages, pkg)
    }
  }
  
  if (length(missing_packages) > 0) {
    stop("Missing required packages: ", paste(missing_packages, collapse = ", "),
         "\nInstall with: install.packages(c('", paste(missing_packages, collapse = "', '"), "'))")
  }
  
  # Load packages
  library(readxl)
  library(dplyr)
  library(tidyr)
  library(stringr)
  library(readr)
  library(writexl)
  
  message("✓ All required packages loaded successfully")
}

# Load packages
load_required_packages()


# ==============================================================================
# SECTION 2: UTILITY FUNCTIONS
# ==============================================================================

#' Get Script Directory Path
#' 
#' Returns the directory where this script is located
#' 
#' @return Character string with script directory path
get_script_directory <- function() {
  if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
    script_path <- rstudioapi::getActiveDocumentContext()$path
    if (!is.null(script_path) && nzchar(script_path)) {
      return(dirname(script_path))
    }
  }
  
  args <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("^--file=", args, value = TRUE)
  if (length(file_arg) > 0) {
    return(dirname(sub("^--file=", "", file_arg[1])))
  }
  
  return(getwd())
}


# ==============================================================================
# SECTION 3: DATA LOADING FUNCTIONS
# ==============================================================================

#' Load KEGG Compounds List
#' 
#' Loads local KEGG compounds reference file
#' 
#' @return Data frame with columns: cpd, compoundname
load_kegg_compounds_local <- function() {
  file_path <- "input_data/kegglistcompounds.xlsx"
  
  kegg_compounds <- read_excel(file_path, col_names = FALSE)
  colnames(kegg_compounds) <- c("cpd", "compoundname")
  
  message("✓ Loaded ", nrow(kegg_compounds), " KEGG compounds from local file")
  return(kegg_compounds)
}


#' Load Environmental Agency Compounds
#' 
#' Loads compound data from 9 environmental agencies
#' 
#' @return Data frame with columns: cpd, referenceAG
load_agency_compounds <- function() {
  file_path <- "input_data/curated_regulated_compounds.xlsx"
  
  agency_compounds <- read_excel(file_path, col_names = FALSE)
  colnames(agency_compounds) <- c("cpd", "referenceAG")
  
  message("✓ Loaded ", nrow(agency_compounds), " compounds from environmental agencies")
  return(agency_compounds)
}


#' Load Manually Curated Compounds
#' 
#' Loads compounds manually curated to fill gaps in automated data
#' 
#' @return Data frame with columns: cpd, ko
load_curated_compounds <- function() {
  file_path <- "input_data/curated_programatic_missing_compounds.xlsx"
  
  curated_compounds <- read_excel(file_path)
  colnames(curated_compounds) <- c("cpd", "ko")
  
  # Remove extra columns if present
  curated_compounds <- curated_compounds[, c("cpd", "ko")]
  
  message("✓ Loaded ", nrow(curated_compounds), " manually curated compounds")
  return(curated_compounds)
}


#' Load Compound Classifications
#' 
#' Loads manually curated compound class annotations
#' 
#' @return Data frame with columns: cpd, compoundclass
load_compound_classifications <- function() {
  file_path <- "input_data/curated_compound_classes.xlsx"
  
  compound_classes <- read_excel(file_path)
  
  message("✓ Loaded compound classifications for ", nrow(compound_classes), " compounds")
  return(compound_classes)
}


#' Load KEGG Orthology List
#' 
#' Loads pre-downloaded KEGG KO list with gene information
#' 
#' @return Data frame with columns: ko, genesymbol, genename
load_kegg_ko_list <- function() {
  file_path <- "input_data/kegglistko.txt"
  
  ko_list <- read.delim(
    file = file_path,
    header = TRUE,
    sep = "\t",
    stringsAsFactors = FALSE,
    quote = "\"",
    fill = TRUE,
    comment.char = ""
  )
  
  # Standardize column names
  names(ko_list) <- tolower(names(ko_list))
  ko_list <- ko_list[, c("ko", "genesymbol", "genename")]
  
  message("✓ Loaded ", nrow(ko_list), " KO entries from local file")
  return(ko_list)
}


#' Load Enzyme Terms
#' 
#' Loads unique enzyme activity terms for pattern matching
#' 
#' @return Character vector of enzyme terms
load_enzyme_terms <- function() {
  file_path <- "input_data/curated_enzyem_names_extracted.txt"
  
  # Check if file exists
  if (!file.exists(file_path)) {
    stop("Enzyme terms file not found: ", file_path,
         "\nPlease ensure curated_enzyem_names_extracted.txt is in the input_data/ directory")
  }
  
  enzyme_terms <- readLines(file_path, warn = FALSE) %>%
    str_trim() %>%
    unique()
  
  # Remove empty strings
  enzyme_terms <- enzyme_terms[enzyme_terms != ""]
  
  message("✓ Loaded ", length(enzyme_terms), " unique enzyme terms")
  return(enzyme_terms)
}


# ==============================================================================
# SECTION 4: KEGG API FUNCTIONS
# ==============================================================================

#' Fetch Data from KEGG API
#' 
#' Generic function to fetch data from KEGG REST API with error handling
#' 
#' @param endpoint API endpoint (e.g., "link/ko/ec")
#' @param col_names Column names for resulting data frame
#' @param sep Separator character (default: tab)
#' @return Data frame with API results
fetch_kegg_api <- function(endpoint, col_names, sep = "\t") {
  url <- paste0("https://rest.kegg.jp/", endpoint)
  
  result <- try(
    read.csv(url, header = FALSE, sep = sep, col.names = col_names),
    silent = TRUE
  )
  
  if (inherits(result, "try-error")) {
    warning("Failed to fetch data from KEGG API: ", endpoint)
    return(NULL)
  }
  
  message("✓ Fetched data from KEGG API: ", endpoint)
  return(result)
}


#' Fetch KO-EC Links
#' 
#' Retrieves links between KEGG Orthology and EC numbers
#' 
#' @return Data frame with columns: ec, ko
fetch_ko_ec_links <- function() {
  fetch_kegg_api("link/ko/ec", c("ec", "ko"), sep = "")
}


#' Fetch KO-Reaction Links
#' 
#' Retrieves links between KEGG Orthology and reactions
#' 
#' @return Data frame with columns: reaction, ko
fetch_ko_reaction_links <- function() {
  fetch_kegg_api("link/ko/reaction", c("reaction", "ko"), sep = "")
}


#' Fetch Compound-EC Links
#' 
#' Retrieves links between compounds and EC numbers
#' 
#' @return Data frame with columns: ec, cpd
fetch_compound_ec_links <- function() {
  fetch_kegg_api("link/compound/ec", c("ec", "cpd"), sep = "")
}


#' Fetch Compound-Reaction Links
#' 
#' Retrieves links between compounds and reactions
#' 
#' @return Data frame with columns: reaction, cpd
fetch_compound_reaction_links <- function() {
  fetch_kegg_api("link/compound/reaction", c("reaction", "cpd"), sep = "")
}


#' Fetch Compound List
#' 
#' Retrieves complete compound list with names from KEGG
#' 
#' @return Data frame with columns: cpd, compoundname
fetch_compound_list <- function() {
  compound_list <- fetch_kegg_api("list/cpd/", c("cpd", "compoundname"))
  
  if (!is.null(compound_list)) {
    # Remove everything after semicolon in compound names
    compound_list$compoundname <- sub(";.*$", "", compound_list$compoundname)
  }
  
  return(compound_list)
}


#' Fetch KO List
#' 
#' Retrieves complete KO list with gene information from KEGG
#' 
#' @return Data frame with columns: ko, geneinfo
fetch_ko_list <- function() {
  fetch_kegg_api("list/ko/", c("ko", "geneinfo"))
}


# ==============================================================================
# SECTION 5: DATA TRANSFORMATION FUNCTIONS
# ==============================================================================

#' Merge KO and Compound Data via EC and Reactions
#' 
#' Combines KO-compound relationships from both EC numbers and reactions
#' 
#' @param ko_ec_links Data frame from fetch_ko_ec_links()
#' @param ko_reaction_links Data frame from fetch_ko_reaction_links()
#' @param compound_ec_links Data frame from fetch_compound_ec_links()
#' @param compound_reaction_links Data frame from fetch_compound_reaction_links()
#' @return Data frame with unique ko-cpd relationships
merge_ko_compound_relationships <- function(ko_ec_links, ko_reaction_links,
                                            compound_ec_links, compound_reaction_links) {
  message("\n--- Merging KO and Compound Relationships ---")
  
  # Merge based on EC numbers
  ko_ec_cpd <- merge(ko_ec_links, compound_ec_links, by = "ec", all = TRUE)
  
  # Merge based on reactions
  ko_reaction_cpd <- merge(ko_reaction_links, compound_reaction_links, by = "reaction", all = TRUE)
  
  # Combine both datasets
  combined_ko_cpd <- rbind(
    ko_ec_cpd[, c("ko", "cpd")],
    ko_reaction_cpd[, c("ko", "cpd")]
  )
  
  # Remove duplicates
  unique_ko_cpd <- unique(combined_ko_cpd)
  
  # Clean compound IDs (remove "cpd:" prefix)
  unique_ko_cpd$cpd <- gsub("cpd:", "", unique_ko_cpd$cpd)
  
  message("✓ Created ", nrow(unique_ko_cpd), " unique KO-compound relationships")
  return(unique_ko_cpd)
}


#' Integrate Compound Data Sources
#' 
#' Combines agency compounds, KEGG relationships, and manual curations
#' 
#' @param agency_compounds Data frame from load_agency_compounds()
#' @param ko_compound_links Data frame from merge_ko_compound_relationships()
#' @param curated_compounds Data frame from load_curated_compounds()
#' @return Integrated data frame with columns: cpd, ko, referenceAG
integrate_compound_sources <- function(agency_compounds, ko_compound_links, curated_compounds) {
  message("\n--- Integrating Compound Data Sources ---")
  
  # Merge agency compounds with KO links
  compounds_with_ko <- merge(agency_compounds, ko_compound_links, by = "cpd")
  
  # Reorder columns to match curated format
  compounds_with_ko <- compounds_with_ko[, c("cpd", "ko", "referenceAG")]
  
  # Add reference agency to curated compounds
  curated_with_agency <- merge(curated_compounds, agency_compounds, by = "cpd")
  
  # Combine curated and automated data
  integrated_compounds <- rbind(curated_with_agency, compounds_with_ko)
  
  message("✓ Integrated ", nrow(integrated_compounds), " compound-KO relationships")
  return(integrated_compounds)
}


#' Add Compound Names
#' 
#' Enriches compound data with compound names from KEGG
#' 
#' @param compounds Data frame with compound data
#' @param compound_list Data frame from fetch_compound_list()
#' @return Data frame with added compoundname column
add_compound_names <- function(compounds, compound_list) {
  message("\n--- Adding Compound Names ---")
  
  compounds_with_names <- merge(compounds, compound_list, by = "cpd")
  
  message("✓ Added names to ", nrow(compounds_with_names), " compounds")
  return(compounds_with_names)
}


#' Transform Compound Classifications to Tidy Format
#' 
#' Converts comma-separated compound classes to one row per class
#' 
#' @param compound_classes Data frame from load_compound_classifications()
#' @return Tidy data frame with one row per compound-class combination
tidy_compound_classifications <- function(compound_classes) {
  message("\n--- Tidying Compound Classifications ---")
  
  tidy_classes <- compound_classes %>%
    separate_rows(compoundclass, sep = ",") %>%
    mutate(
      compoundclass = str_trim(compoundclass),
      compoundclass = str_replace_all(compoundclass, " \\(repeated\\)", ""),
      compoundclass = str_replace_all(compoundclass, "Organometalic", "Organometallic")
    ) %>%
    na.omit()
  
  message("✓ Created ", nrow(tidy_classes), " compound-class relationships")
  return(tidy_classes)
}


#' Add Classifications to Compounds
#' 
#' Merges compound classifications with compound data
#' 
#' @param compounds Data frame with compound data
#' @param tidy_classes Data frame from tidy_compound_classifications()
#' @return Data frame with added compoundclass column
add_compound_classifications <- function(compounds, tidy_classes) {
  message("\n--- Adding Compound Classifications ---")
  
  classified_compounds <- merge(tidy_classes, compounds, by = "cpd") %>%
    unique() %>%
    arrange(ko)
  
  message("✓ Classified ", nrow(classified_compounds), " compound entries")
  return(classified_compounds)
}


#' Sanitize KO Identifiers
#' 
#' Cleans and standardizes KO identifiers to K##### format
#' Removes invalid entries
#' 
#' @param classified_compounds Data frame with compound classifications
#' @return Data frame with sanitized KO identifiers
sanitize_ko_identifiers <- function(classified_compounds) {
  message("\n--- Sanitizing KO Identifiers ---")
  
  sanitized_data <- classified_compounds %>%
    mutate(
      ko = str_trim(as.character(ko)),
      # Remove "ko:" prefix
      ko = str_remove(ko, regex("^ko\\s*:\\s*", ignore_case = TRUE)),
      # Extract K##### pattern
      ko_k = str_extract(ko, regex("K\\d{5}", ignore_case = TRUE)),
      # Standardize to K##### format
      ko = if_else(
        !is.na(ko_k),
        str_c("K", str_extract(ko_k, "\\d{5}")),
        NA_character_
      )
    ) %>%
    # Remove rows with NA KO identifiers
    filter(!is.na(ko)) %>%
    select(-ko_k)
  
  message("✓ Sanitized ", nrow(sanitized_data), " KO identifiers")
  return(sanitized_data)
}


#' Prepare KEGG Reference Data
#' 
#' Cleans and deduplicates KEGG KO list for joining
#' 
#' @param ko_list Data frame from load_kegg_ko_list()
#' @return Cleaned and deduplicated data frame
prepare_kegg_reference <- function(ko_list) {
  message("\n--- Preparing KEGG Reference Data ---")
  
  kegg_reference <- ko_list %>%
    transmute(
      ko = str_trim(str_to_upper(ko)),
      genesymbol = str_trim(genesymbol),
      genename = str_trim(genename)
    ) %>%
    group_by(ko) %>%
    summarise(
      genesymbol = first(genesymbol),
      genename = first(genename),
      .groups = "drop"
    )
  
  message("✓ Prepared ", nrow(kegg_reference), " unique KO entries")
  return(kegg_reference)
}


#' Add Gene Information to Compounds
#' 
#' Enriches compound data with gene symbols and names
#' Filters out entries without valid gene information
#' 
#' @param sanitized_compounds Data frame from sanitize_ko_identifiers()
#' @param kegg_reference Data frame from prepare_kegg_reference()
#' @return Data frame with added genesymbol and genename columns
add_gene_information <- function(sanitized_compounds, kegg_reference) {
  message("\n--- Adding Gene Information ---")
  
  compounds_with_genes <- sanitized_compounds %>%
    filter(!is.na(ko), ko != "") %>%
    mutate(ko = str_trim(str_to_upper(ko))) %>%
    left_join(
      kegg_reference %>%
        filter(!is.na(ko), ko != "") %>%
        mutate(ko = str_trim(str_to_upper(ko))),
      by = "ko"
    ) %>%
    filter(
      !is.na(genesymbol), genesymbol != "",
      !is.na(genename), genename != ""
    )
  
  message("✓ Added gene information to ", nrow(compounds_with_genes), " entries")
  message("⚠ Entries without gene match: ", 
          nrow(sanitized_compounds) - nrow(compounds_with_genes))
  
  return(compounds_with_genes)
}


#' Build Enzyme Activity Regex Pattern
#' 
#' Creates regex pattern from enzyme terms for activity extraction
#' Properly escapes regex metacharacters
#' 
#' @param enzyme_terms Character vector from load_enzyme_terms()
#' @return Character string with regex pattern
build_enzyme_pattern <- function(enzyme_terms) {
  message("\n--- Building Enzyme Activity Pattern ---")
  
  # Escape regex metacharacters for safe pattern matching
  enzyme_terms_escaped <- gsub("([\\^$.|?*+(){}\\[\\]\\\\])", "\\\\\\1", 
                               enzyme_terms, perl = TRUE)
  
  # Create word-boundary pattern
  pattern <- paste0("\\b(", paste(enzyme_terms_escaped, collapse = "|"), ")\\b")
  
  message("✓ Built pattern with ", length(enzyme_terms), " enzyme terms")
  return(pattern)
}


#' Extract Enzyme Activities
#' 
#' Extracts enzyme activity terms from gene names using pattern matching
#' Falls back to original genename if no enzyme term found
#' 
#' @param compounds_with_genes Data frame from add_gene_information()
#' @param enzyme_pattern Regex pattern from build_enzyme_pattern()
#' @return Data frame with added enzyme_activity column
extract_enzyme_activities <- function(compounds_with_genes, enzyme_pattern) {
  message("\n--- Extracting Enzyme Activities ---")
  
  compounds_with_enzymes <- compounds_with_genes %>%
    mutate(
      enzyme_activity = str_extract(genename, regex(enzyme_pattern, ignore_case = TRUE)),
      # Fallback to genename if no enzyme term found
      enzyme_activity = if_else(is.na(enzyme_activity), genename, enzyme_activity)
    )
  
  message("✓ Extracted enzyme activities for ", nrow(compounds_with_enzymes), " entries")
  return(compounds_with_enzymes)
}


#' Clean Gene Names and Symbols
#' 
#' Removes EC numbers from gene names and cleans gene symbols
#' 
#' @param compounds_with_enzymes Data frame from extract_enzyme_activities()
#' @return Data frame with cleaned genename and genesymbol columns
clean_gene_annotations <- function(compounds_with_enzymes) {
  message("\n--- Cleaning Gene Annotations ---")
  
  cleaned_data <- compounds_with_enzymes %>%
    mutate(
      # Remove EC numbers from gene names
      genename = str_remove(genename, regex("\\s*\\[EC.*$", ignore_case = TRUE)),
      # Remove everything after comma in gene symbols
      genesymbol = str_remove(genesymbol, ",.*$")
    )
  
  message("✓ Cleaned gene annotations")
  return(cleaned_data)
}


# ==============================================================================
# SECTION 6: MAIN EXECUTION PIPELINE
# ==============================================================================

#' Main Database Generation Pipeline
#' 
#' Orchestrates the complete database generation process
#' 
#' @return Final database data frame
main_pipeline <- function() {
  message("\n")
  message("================================================================================")
  message("  BioRemPP Database Generator v1.0.0")
  message("================================================================================")
  message("\n")
  
  # ============================================================================
  # STEP 1: Load Local Data Files
  # ============================================================================
  message("=== STEP 1: Loading Local Data Files ===")
  
  kegg_compounds_local <- load_kegg_compounds_local()
  agency_compounds <- load_agency_compounds()
  curated_compounds <- load_curated_compounds()
  compound_classes <- load_compound_classifications()
  ko_list <- load_kegg_ko_list()
  enzyme_terms <- load_enzyme_terms()
  
  # ============================================================================
  # STEP 2: Fetch Data from KEGG API
  # ============================================================================
  message("\n=== STEP 2: Fetching Data from KEGG API ===")
  
  ko_ec_links <- fetch_ko_ec_links()
  ko_reaction_links <- fetch_ko_reaction_links()
  compound_ec_links <- fetch_compound_ec_links()
  compound_reaction_links <- fetch_compound_reaction_links()
  compound_list <- fetch_compound_list()
  
  # ============================================================================
  # STEP 3: Merge and Integrate Data
  # ============================================================================
  message("\n=== STEP 3: Merging and Integrating Data ===")
  
  ko_compound_links <- merge_ko_compound_relationships(
    ko_ec_links, ko_reaction_links,
    compound_ec_links, compound_reaction_links
  )
  
  integrated_compounds <- integrate_compound_sources(
    agency_compounds, ko_compound_links, curated_compounds
  )
  
  compounds_with_names <- add_compound_names(integrated_compounds, compound_list)
  
  # ============================================================================
  # STEP 4: Add Compound Classifications
  # ============================================================================
  message("\n=== STEP 4: Adding Compound Classifications ===")
  
  tidy_classes <- tidy_compound_classifications(compound_classes)
  classified_compounds <- add_compound_classifications(compounds_with_names, tidy_classes)
  
  # ============================================================================
  # STEP 5: Sanitize and Enrich with Gene Information
  # ============================================================================
  message("\n=== STEP 5: Sanitizing KO IDs and Adding Gene Information ===")
  
  sanitized_compounds <- sanitize_ko_identifiers(classified_compounds)
  kegg_reference <- prepare_kegg_reference(ko_list)
  compounds_with_genes <- add_gene_information(sanitized_compounds, kegg_reference)
  
  # ============================================================================
  # STEP 6: Extract Enzyme Activities and Clean Annotations
  # ============================================================================
  message("\n=== STEP 6: Extracting Enzyme Activities ===")
  
  enzyme_pattern <- build_enzyme_pattern(enzyme_terms)
  compounds_with_enzymes <- extract_enzyme_activities(compounds_with_genes, enzyme_pattern)
  final_database <- clean_gene_annotations(compounds_with_enzymes)
  
  # ============================================================================
  # STEP 7: Save Results
  # ============================================================================
  message("\n=== STEP 7: Saving Results ===")
  
  # Create output directory if it doesn't exist
  if (!dir.exists("output_data")) {
    dir.create("output_data", recursive = TRUE)
  }
  
  # Save as CSV
  output_csv <- "output_data/biorempp_database_v1.0.0.csv"
  write.csv(final_database, output_csv, row.names = FALSE)
  message("✓ Saved database to: ", output_csv)
  
  # Save as Excel (optional)
  output_xlsx <- "output_data/biorempp_database_v1.0.0.xlsx"
  tryCatch({
    writexl::write_xlsx(final_database, output_xlsx)
    message("✓ Saved database to: ", output_xlsx)
  }, error = function(e) {
    message("⚠ Could not save Excel file: ", e$message)
  })
  
  # Print summary statistics
  message("\n")
  message("================================================================================")
  message("  Database Generation Complete!")
  message("================================================================================")
  message("\nSummary Statistics:")
  message("  - Total entries: ", nrow(final_database))
  message("  - Unique compounds: ", length(unique(final_database$cpd)))
  message("  - Unique KO entries: ", length(unique(final_database$ko)))
  message("  - Unique compound classes: ", length(unique(final_database$compoundclass)))
  message("  - Unique gene symbols: ", length(unique(final_database$genesymbol)))
  message("  - Unique enzyme activities: ", length(unique(final_database$enzyme_activity)))
  message("\nOutput files:")
  message("  - ", output_csv)
  if (file.exists(output_xlsx)) {
    message("  - ", output_xlsx)
  }
  message("\n")
  
  return(final_database)
}


# ==============================================================================
# EXECUTE MAIN PIPELINE
# ==============================================================================

# Run the main pipeline
biorempp_database <- main_pipeline()

# Display preview of results
message("Preview of final database (first 10 rows):")
print(head(biorempp_database, 10))

message("\nColumn names:")
print(colnames(biorempp_database))
