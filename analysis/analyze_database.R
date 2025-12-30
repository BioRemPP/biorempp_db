################################################################################
# BioRemPP Database Exploratory Analysis
################################################################################
#
# Purpose: Perform comprehensive exploratory data analysis on the generated
#          BioRemPP database and export metadata and statistics to JSON format
#          for official documentation
#
# Author: BioRemPP Development Team
# Version: 1.0.0
#
# Output: JSON files with database statistics, metadata, and analysis results
#
################################################################################

# ==============================================================================
# SECTION 1: SETUP AND DEPENDENCIES
# ==============================================================================

#' Load Required Packages
load_analysis_packages <- function() {
  required_packages <- c("dplyr", "jsonlite", "stringr", "tidyr")
  
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
  
  library(dplyr)
  library(jsonlite)
  library(stringr)
  library(tidyr)
  
  message("✓ All required packages loaded")
}

load_analysis_packages()


# ==============================================================================
# SECTION 2: DATA LOADING
# ==============================================================================

#' Load BioRemPP Database
#' 
#' Loads the generated database from output_data directory
#' 
#' @return Data frame with database contents
load_database <- function() {
  db_path <- "../output_data/biorempp_database_v1.0.0.csv"
  
  if (!file.exists(db_path)) {
    stop("Database file not found: ", db_path,
         "\nPlease run generate_database.R first to create the database")
  }
  
  database <- read.csv(db_path, stringsAsFactors = FALSE)
  
  message("✓ Loaded database with ", nrow(database), " entries")
  return(database)
}


# ==============================================================================
# SECTION 3: BASIC STATISTICS
# ==============================================================================

#' Calculate Basic Database Statistics
#' 
#' Computes fundamental statistics about the database
#' 
#' @param db Data frame with database
#' @return List with basic statistics
calculate_basic_statistics <- function(db) {
  message("\n--- Calculating Basic Statistics ---")
  
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
      referenceAG = sum(is.na(db$referenceAG)),
      compoundname = sum(is.na(db$compoundname)),
      genesymbol = sum(is.na(db$genesymbol)),
      genename = sum(is.na(db$genename)),
      enzyme_activity = sum(is.na(db$enzyme_activity))
    )
  )
  
  message("✓ Basic statistics calculated")
  return(stats)
}


#' Calculate Compound Statistics
#' 
#' Detailed statistics about compounds
#' 
#' @param db Data frame with database
#' @return List with compound statistics
calculate_compound_statistics <- function(db) {
  message("\n--- Calculating Compound Statistics ---")
  
  # Compounds per class
  compounds_per_class <- db %>%
    group_by(compoundclass) %>%
    summarise(count = n_distinct(cpd), .groups = "drop") %>%
    arrange(desc(count))
  
  # Compounds per agency
  compounds_per_agency <- db %>%
    group_by(referenceAG) %>%
    summarise(count = n_distinct(cpd), .groups = "drop") %>%
    arrange(desc(count))
  
  # Top 20 most frequent compounds
  top_compounds <- db %>%
    group_by(cpd, compoundname) %>%
    summarise(frequency = n(), .groups = "drop") %>%
    arrange(desc(frequency)) %>%
    head(20)
  
  stats <- list(
    total_unique_compounds = length(unique(db$cpd)),
    compounds_per_class = as.list(setNames(compounds_per_class$count, compounds_per_class$compoundclass)),
    compounds_per_agency = as.list(setNames(compounds_per_agency$count, compounds_per_agency$referenceAG)),
    top_20_compounds = list(
      compound_ids = top_compounds$cpd,
      compound_names = top_compounds$compoundname,
      frequencies = top_compounds$frequency
    ),
    class_distribution_summary = list(
      total_classes = nrow(compounds_per_class),
      min_compounds_per_class = min(compounds_per_class$count),
      max_compounds_per_class = max(compounds_per_class$count),
      mean_compounds_per_class = mean(compounds_per_class$count),
      median_compounds_per_class = median(compounds_per_class$count)
    )
  )
  
  message("✓ Compound statistics calculated")
  return(stats)
}


#' Calculate KO Statistics
#' 
#' Detailed statistics about KEGG Orthology entries
#' 
#' @param db Data frame with database
#' @return List with KO statistics
calculate_ko_statistics <- function(db) {
  message("\n--- Calculating KO Statistics ---")
  
  # KO frequency
  ko_frequency <- db %>%
    group_by(ko) %>%
    summarise(
      frequency = n(),
      unique_compounds = n_distinct(cpd),
      .groups = "drop"
    ) %>%
    arrange(desc(frequency))
  
  # Top 20 most frequent KOs
  top_kos <- ko_frequency %>%
    head(20)
  
  # KO with gene information
  ko_with_genes <- db %>%
    group_by(ko) %>%
    summarise(
      genesymbol = first(genesymbol),
      genename = first(genename),
      .groups = "drop"
    )
  
  stats <- list(
    total_unique_ko = length(unique(db$ko)),
    top_20_ko = list(
      ko_ids = top_kos$ko,
      frequencies = top_kos$frequency,
      unique_compounds_per_ko = top_kos$unique_compounds
    ),
    ko_frequency_summary = list(
      min_frequency = min(ko_frequency$frequency),
      max_frequency = max(ko_frequency$frequency),
      mean_frequency = mean(ko_frequency$frequency),
      median_frequency = median(ko_frequency$frequency)
    ),
    compounds_per_ko_summary = list(
      min_compounds = min(ko_frequency$unique_compounds),
      max_compounds = max(ko_frequency$unique_compounds),
      mean_compounds = mean(ko_frequency$unique_compounds),
      median_compounds = median(ko_frequency$unique_compounds)
    )
  )
  
  message("✓ KO statistics calculated")
  return(stats)
}


#' Calculate Enzyme Activity Statistics
#' 
#' Detailed statistics about enzyme activities
#' 
#' @param db Data frame with database
#' @return List with enzyme statistics
calculate_enzyme_statistics <- function(db) {
  message("\n--- Calculating Enzyme Activity Statistics ---")
  
  # Enzyme activity frequency
  enzyme_frequency <- db %>%
    group_by(enzyme_activity) %>%
    summarise(
      frequency = n(),
      unique_compounds = n_distinct(cpd),
      unique_ko = n_distinct(ko),
      .groups = "drop"
    ) %>%
    arrange(desc(frequency))
  
  # Top 30 most frequent enzymes
  top_enzymes <- enzyme_frequency %>%
    head(30)
  
  stats <- list(
    total_unique_enzymes = length(unique(db$enzyme_activity)),
    top_30_enzymes = list(
      enzyme_names = top_enzymes$enzyme_activity,
      frequencies = top_enzymes$frequency,
      unique_compounds = top_enzymes$unique_compounds,
      unique_ko = top_enzymes$unique_ko
    ),
    enzyme_frequency_summary = list(
      min_frequency = min(enzyme_frequency$frequency),
      max_frequency = max(enzyme_frequency$frequency),
      mean_frequency = mean(enzyme_frequency$frequency),
      median_frequency = median(enzyme_frequency$frequency)
    )
  )
  
  message("✓ Enzyme statistics calculated")
  return(stats)
}


#' Calculate Gene Statistics
#' 
#' Detailed statistics about genes
#' 
#' @param db Data frame with database
#' @return List with gene statistics
calculate_gene_statistics <- function(db) {
  message("\n--- Calculating Gene Statistics ---")
  
  # Gene symbol frequency
  genesymbol_frequency <- db %>%
    group_by(genesymbol) %>%
    summarise(frequency = n(), .groups = "drop") %>%
    arrange(desc(frequency))
  
  # Top 20 gene symbols
  top_genesymbols <- genesymbol_frequency %>%
    head(20)
  
  # Gene name frequency
  genename_frequency <- db %>%
    group_by(genename) %>%
    summarise(frequency = n(), .groups = "drop") %>%
    arrange(desc(frequency))
  
  # Top 20 gene names
  top_genenames <- genename_frequency %>%
    head(20)
  
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
  
  message("✓ Gene statistics calculated")
  return(stats)
}


#' Calculate Cross-Tabulation Statistics
#' 
#' Statistics about relationships between different dimensions
#' 
#' @param db Data frame with database
#' @return List with cross-tabulation statistics
calculate_crosstab_statistics <- function(db) {
  message("\n--- Calculating Cross-Tabulation Statistics ---")
  
  # Compounds per class and agency
  class_agency_crosstab <- db %>%
    group_by(compoundclass, referenceAG) %>%
    summarise(count = n_distinct(cpd), .groups = "drop") %>%
    arrange(desc(count)) %>%
    head(20)
  
  # Enzyme activities per compound class
  enzyme_class_crosstab <- db %>%
    group_by(compoundclass, enzyme_activity) %>%
    summarise(count = n(), .groups = "drop") %>%
    arrange(desc(count)) %>%
    head(20)
  
  # KO per compound class
  ko_class_summary <- db %>%
    group_by(compoundclass) %>%
    summarise(unique_ko = n_distinct(ko), .groups = "drop") %>%
    arrange(desc(unique_ko)) %>%
    head(10)
  
  stats <- list(
    top_20_class_agency_combinations = list(
      compound_classes = class_agency_crosstab$compoundclass,
      agencies = class_agency_crosstab$referenceAG,
      compound_counts = class_agency_crosstab$count
    ),
    top_20_enzyme_class_combinations = list(
      compound_classes = enzyme_class_crosstab$compoundclass,
      enzymes = enzyme_class_crosstab$enzyme_activity,
      counts = enzyme_class_crosstab$count
    ),
    top_10_classes_by_ko_diversity = list(
      compound_classes = ko_class_summary$compoundclass,
      unique_ko_counts = ko_class_summary$unique_ko
    )
  )
  
  message("✓ Cross-tabulation statistics calculated")
  return(stats)
}


# ==============================================================================
# SECTION 4: METADATA GENERATION
# ==============================================================================

#' Generate Database Metadata
#' 
#' Creates comprehensive metadata about the database
#' 
#' @param db Data frame with database
#' @return List with metadata
generate_metadata <- function(db) {
  message("\n--- Generating Database Metadata ---")
  
  metadata <- list(
    database_info = list(
      name = "BioRemPP Database",
      version = "1.0.0",
      generation_date = Sys.Date(),
      description = "Comprehensive biological remediation database integrating KEGG data, environmental agency compound lists, manual curations, and enzyme classifications"
    ),
    
    data_sources = list(
      kegg_api = "https://rest.kegg.jp/",
      environmental_agencies = "9 agencies",
      manual_curations = "Manually curated compounds and classifications",
      enzyme_terms = "210+ unique enzyme activity terms"
    ),
    
    schema = list(
      columns = list(
        cpd = list(
          name = "cpd",
          type = "character",
          description = "KEGG compound identifier",
          example = "C00001"
        ),
        compoundclass = list(
          name = "compoundclass",
          type = "character",
          description = "Chemical class of the compound",
          example = "Organic"
        ),
        ko = list(
          name = "ko",
          type = "character",
          description = "KEGG Orthology identifier (K#####)",
          example = "K00001"
        ),
        referenceAG = list(
          name = "referenceAG",
          type = "character",
          description = "Reference environmental agency",
          example = "EPA"
        ),
        compoundname = list(
          name = "compoundname",
          type = "character",
          description = "Name of the compound",
          example = "Water"
        ),
        genesymbol = list(
          name = "genesymbol",
          type = "character",
          description = "Gene symbol",
          example = "ADH1"
        ),
        genename = list(
          name = "genename",
          type = "character",
          description = "Gene name (cleaned, without EC numbers)",
          example = "alcohol dehydrogenase"
        ),
        enzyme_activity = list(
          name = "enzyme_activity",
          type = "character",
          description = "Extracted enzyme activity term",
          example = "dehydrogenase"
        )
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
  
  message("✓ Metadata generated")
  return(metadata)
}


# ==============================================================================
# SECTION 5: SUMMARY GENERATION
# ==============================================================================

#' Generate Executive Summary
#' 
#' Creates a high-level summary for documentation
#' 
#' @param basic_stats List from calculate_basic_statistics()
#' @param compound_stats List from calculate_compound_statistics()
#' @param ko_stats List from calculate_ko_statistics()
#' @param enzyme_stats List from calculate_enzyme_statistics()
#' @return List with executive summary
generate_executive_summary <- function(basic_stats, compound_stats, ko_stats, enzyme_stats) {
  message("\n--- Generating Executive Summary ---")
  
  summary <- list(
    overview = list(
      total_entries = basic_stats$total_entries,
      unique_compounds = basic_stats$unique_compounds,
      unique_ko_entries = basic_stats$unique_ko_entries,
      unique_enzyme_activities = basic_stats$unique_enzyme_activities,
      unique_compound_classes = basic_stats$unique_compound_classes
    ),
    
    highlights = list(
      most_represented_class = names(which.max(unlist(compound_stats$compounds_per_class))),
      compounds_in_top_class = max(unlist(compound_stats$compounds_per_class)),
      most_frequent_enzyme = enzyme_stats$top_30_enzymes$enzyme_names[1],
      enzyme_frequency = enzyme_stats$top_30_enzymes$frequencies[1],
      total_classes = compound_stats$class_distribution_summary$total_classes
    ),
    
    coverage = list(
      environmental_agencies = basic_stats$unique_reference_agencies,
      compound_classes_covered = basic_stats$unique_compound_classes,
      enzyme_types_identified = basic_stats$unique_enzyme_activities,
      gene_symbols_mapped = basic_stats$unique_gene_symbols
    )
  )
  
  message("✓ Executive summary generated")
  return(summary)
}


# ==============================================================================
# SECTION 6: EXPORT FUNCTIONS
# ==============================================================================

#' Export Analysis Results to JSON
#' 
#' Saves all analysis results to JSON files
#' 
#' @param results List with all analysis results
export_to_json <- function(results) {
  message("\n--- Exporting Results to JSON ---")
  
  # Create output directory if it doesn't exist
  if (!dir.exists("output")) {
    dir.create("output", recursive = TRUE)
  }
  
  # Export each component
  write_json(results$metadata, "output/database_metadata.json", 
             pretty = TRUE, auto_unbox = TRUE)
  message("✓ Exported metadata to output/database_metadata.json")
  
  write_json(results$basic_stats, "output/basic_statistics.json", 
             pretty = TRUE, auto_unbox = TRUE)
  message("✓ Exported basic statistics to output/basic_statistics.json")
  
  write_json(results$compound_stats, "output/compound_statistics.json", 
             pretty = TRUE, auto_unbox = TRUE)
  message("✓ Exported compound statistics to output/compound_statistics.json")
  
  write_json(results$ko_stats, "output/ko_statistics.json", 
             pretty = TRUE, auto_unbox = TRUE)
  message("✓ Exported KO statistics to output/ko_statistics.json")
  
  write_json(results$enzyme_stats, "output/enzyme_statistics.json", 
             pretty = TRUE, auto_unbox = TRUE)
  message("✓ Exported enzyme statistics to output/enzyme_statistics.json")
  
  write_json(results$gene_stats, "output/gene_statistics.json", 
             pretty = TRUE, auto_unbox = TRUE)
  message("✓ Exported gene statistics to output/gene_statistics.json")
  
  write_json(results$crosstab_stats, "output/crosstab_statistics.json", 
             pretty = TRUE, auto_unbox = TRUE)
  message("✓ Exported cross-tabulation statistics to output/crosstab_statistics.json")
  
  write_json(results$executive_summary, "output/executive_summary.json", 
             pretty = TRUE, auto_unbox = TRUE)
  message("✓ Exported executive summary to output/executive_summary.json")
  
  # Export complete analysis
  write_json(results, "output/complete_analysis.json", 
             pretty = TRUE, auto_unbox = TRUE)
  message("✓ Exported complete analysis to output/complete_analysis.json")
  
  message("\n✓ All results exported successfully")
}


# ==============================================================================
# SECTION 7: MAIN ANALYSIS PIPELINE
# ==============================================================================

#' Main Analysis Pipeline
#' 
#' Orchestrates the complete exploratory data analysis
main_analysis <- function() {
  message("\n")
  message("================================================================================")
  message("  BioRemPP Database Exploratory Analysis")
  message("================================================================================")
  message("\n")
  
  # Load database
  db <- load_database()
  
  # Calculate all statistics
  basic_stats <- calculate_basic_statistics(db)
  compound_stats <- calculate_compound_statistics(db)
  ko_stats <- calculate_ko_statistics(db)
  enzyme_stats <- calculate_enzyme_statistics(db)
  gene_stats <- calculate_gene_statistics(db)
  crosstab_stats <- calculate_crosstab_statistics(db)
  
  # Generate metadata and summary
  metadata <- generate_metadata(db)
  executive_summary <- generate_executive_summary(basic_stats, compound_stats, 
                                                   ko_stats, enzyme_stats)
  
  # Compile all results
  results <- list(
    metadata = metadata,
    basic_stats = basic_stats,
    compound_stats = compound_stats,
    ko_stats = ko_stats,
    enzyme_stats = enzyme_stats,
    gene_stats = gene_stats,
    crosstab_stats = crosstab_stats,
    executive_summary = executive_summary
  )
  
  # Export to JSON
  export_to_json(results)
  
  # Print summary
  message("\n")
  message("================================================================================")
  message("  Analysis Complete!")
  message("================================================================================")
  message("\nKey Statistics:")
  message("  - Total entries: ", basic_stats$total_entries)
  message("  - Unique compounds: ", basic_stats$unique_compounds)
  message("  - Unique KO entries: ", basic_stats$unique_ko_entries)
  message("  - Unique enzyme activities: ", basic_stats$unique_enzyme_activities)
  message("  - Unique compound classes: ", basic_stats$unique_compound_classes)
  message("\nJSON files generated in analysis/output/:")
  message("  - database_metadata.json")
  message("  - basic_statistics.json")
  message("  - compound_statistics.json")
  message("  - ko_statistics.json")
  message("  - enzyme_statistics.json")
  message("  - gene_statistics.json")
  message("  - crosstab_statistics.json")
  message("  - executive_summary.json")
  message("  - complete_analysis.json")
  message("\n")
  
  return(results)
}


# ==============================================================================
# EXECUTE ANALYSIS
# ==============================================================================

# Run the analysis
analysis_results <- main_analysis()
