set.seed(123)

library(dplyr)
library(purrr)
library(readr)
library(doParallel)
library(parallel)
registerDoParallel(cores = parallel::detectCores(logical = FALSE))

# for more info on
# cv.glmnet with parallel = TRUE and doParallel package:
# https://stackoverflow.com/a/21710769
# https://stackoverflow.com/a/29001039

source("code/models/calculate_penalty_factors.R")
source("code/models/lasso.R")

source("code/utils/validate_imputed_background.R")
source("code/utils/zip_prediction.R")

source("code/data_processing/R/merge_train.R")

run_lasso <- function(data_file_name, prediction_name) {
  # hardcoded file dependencies
  # data/train.csv
  # variables/ffvars_scored.csv"
  
  # data ----
  train <- read_csv(file.path("data", "train.csv"))
  imputed_background <- readRDS(file.path("data", "imputed", data_file_name))
  
  # handle potential issues with imputed data
  # adds a challengeID column if necessary
  # removes any columns that still have NAs
  # converts categorical variables to factors
  imputed_background <- validate_imputed_background(imputed_background)
  
  ffc <- merge_train(imputed_background, train)
  
  # covariates ----
  ffvars_scored <- 
    read_csv(file.path("data", "variables", "ffvars_scored.csv")) %>%
    filter(!is.na(ffvar))
  
  gpa_vars <- ffvars_scored %>% filter(outcome == "gpa")
  grit_vars <- ffvars_scored %>% filter(outcome == "grit")
  materialHardship_vars <- ffvars_scored %>% filter(outcome == "material_hardship")
  eviction_vars <- ffvars_scored %>% filter(outcome == "eviction")
  layoff_vars <- ffvars_scored %>% filter(outcome == "layoff")
  jobTraining_vars <- ffvars_scored %>% filter(outcome == "job_training")
  
  # models ----
  outcomes <- list("gpa", "grit", "materialHardship", 
                   "eviction", "layoff", "jobTraining")
  
  vars_data_list <- list(gpa_vars, grit_vars, materialHardship_vars, 
                         eviction_vars, layoff_vars, jobTraining_vars)
  names(vars_data_list) <- as.character(outcomes)
  
  all_covariates <- rep(list(colnames(imputed_background)[-1]), 6)
  
  covariates <- map(vars_data_list, "ffvar")
  
  scores_experts <- map(vars_data_list, "experts")
  scores_mturkers <- map(vars_data_list, "mturkers")
  
  families <- as.list(c(rep("gaussian", 3), 
                        rep("binomial", 3)))
  
  # alphas closer to 0 seem to do slightly better (more ridge than lasso)
  alphas <- as.list(c(0.05, 0.10, 0.025, 0.15, 0.05, 0.05))
  
  # without score information
  prediction_list <- 
    Map(f = function(...) lasso(data = ffc, ..., parallel = TRUE)$pred, 
        outcome = outcomes, 
        covariates = covariates, 
        family = families, 
        alpha = alphas)
  
  # with expert score information
  prediction_list_experts <- 
    Map(f = function(...) lasso(data = ffc, ..., parallel = TRUE)$pred, 
        outcome = outcomes, 
        covariates = covariates, 
        scores = scores_experts,
        family = families, 
        alpha = alphas)
  
  # with mturk score information
  prediction_list_mturkers <- 
    Map(f = function(...) lasso(data = ffc, ..., parallel = TRUE)$pred, 
        outcome = outcomes, 
        covariates = covariates, 
        scores = scores_mturkers,
        family = families, 
        alpha = alphas)
  
  # predictions ----
  names(prediction_list) <- as.character(outcomes)
  prediction <- 
    ffc %>% 
    select(challengeID) %>%
    bind_cols(prediction_list)
  
  names(prediction_list_experts) <- as.character(outcomes)
  prediction_experts <- 
    ffc %>% 
    select(challengeID) %>%
    bind_cols(prediction_list_experts)
  
  names(prediction_list_mturkers) <- as.character(outcomes)
  prediction_mturkers <- 
    ffc %>% 
    select(challengeID) %>%
    bind_cols(prediction_list_mturkers)
  
  # output ----
  # write to csv and zip for submission
  
  prediction_name_experts <- paste0(prediction_name, "_experts")
  prediction_name_mturkers <- paste0(prediction_name, "_mturkers")
  
  zip_prediction(prediction, prediction_name)
  zip_prediction(prediction_experts, prediction_name_experts)
  zip_prediction(prediction_mturkers, prediction_name_mturkers)
  
  # return predictions
  list(prediction = prediction, 
       prediction_experts = prediction_experts, 
       prediction_mturkers = prediction_mturkers)
}

glmnet_lasso_h <- 
  run_lasso("imputed-fulldata-lasso.rds", "glmnet_lasso_h")

glmnet_mean_h <- 
  run_lasso("meanmode_imputed.rds", "glmnet_mean_h")

glmnet_lm_h <- 
  run_lasso("imputed-lm-vartype.rds", "glmnet_lm_h")

glmnet_lmuntyped_h <- 
  run_lasso("imputed-lm-untyped.rds", "glmnet_lmuntyped_h")
