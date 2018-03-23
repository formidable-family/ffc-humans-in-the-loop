#' Purpose: Source all helper functions and packages for data processing
#' Inputs: R files in code/data_processing/R subdirectory
#' Outputs: NA
#' Machine used: cluster
#' Expected runtime: seconds

library(dplyr)
library(forcats)
library(haven)
library(labelled)
library(readr)
library(stringr)

data_processing_source_dir <- file.path("code", "data_processing", "R")

source(file.path(data_processing_source_dir, "convert_classes.R"))
source(file.path(data_processing_source_dir, "get_vars.R"))
source(file.path(data_processing_source_dir, "merge_train.R"))
source(file.path(data_processing_source_dir, "process_data.R"))
source(file.path(data_processing_source_dir, "recode_na.R"))
source(file.path(data_processing_source_dir, "subset_vars.R"))
source(file.path(data_processing_source_dir, "summarize_variables.R"))
