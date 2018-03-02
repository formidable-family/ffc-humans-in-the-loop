set.seed(123)

library(dplyr)
library(purrr)
library(readr)
library(tidyr)
library(doParallel)
library(parallel)
registerDoParallel(cores = parallel::detectCores(logical = FALSE))

# for more info on
# cv.glmnet with parallel = TRUE and doParallel package:
# https://stackoverflow.com/a/21710769
# https://stackoverflow.com/a/29001039

source("code/models/calculate_penalty_factors.R")
source("code/models/lasso.R")
source("code/models/setup_lasso_all.R")

source("code/utils/validate_imputed_background.R")
source("code/utils/zip_prediction.R")

source("code/data_processing/R/get_vars.R")
source("code/data_processing/R/merge_train.R")
source("code/data_processing/R/subset_vars.R")

data_file_name <- "imputed-lm-vartype.rds"
prediction_name <- "lasso_lm_imputation_all_covariates"

# data ----
train <- read_csv(file.path("data", "train.csv"))
imputed_background <- readRDS(file.path("data", "imputed", data_file_name))

# handle potential issues with imputed data
# adds a challengeID column if necessary
# removes any columns that still have NAs
# converts categorical variables to factors
imputed_background <- validate_imputed_background(imputed_background)
imputed_background <- 
  imputed_background %>%
  subset_vars_remove(get_vars_unique)

ffc <- merge_train(imputed_background, train)

# model information ----
outcomes <- list("gpa", "grit", "materialHardship", 
                 "eviction", "layoff", "jobTraining")

covariates <- colnames(imputed_background)[-1]

families <- as.list(c(rep("gaussian", 3), 
                      rep("binomial", 3)))

alphas <- as.list(c(0.05, 0.10, 0.025, 0.15, 0.05, 0.05))

# scores ----
ffvars_scored <- 
  read_csv(file.path("data", "variables", "ffvars_scored.csv")) %>%
  filter(!is.na(ffvar))

# handle duplicates by taking max score
ffvars_scored <-
  ffvars_scored %>%
  group_by(outcome, ffvar) %>%
  summarise(experts = max(experts, na.rm=TRUE),
            mturkers = max(mturkers, na.rm=TRUE)) %>%
  mutate(experts = ifelse(is.infinite(experts), NA, experts),
         mturkers = ifelse(is.infinite(mturkers), NA, mturkers))

all_covariates <- rep(list(colnames(imputed_background)[-1]), 6)
names(all_covariates) <- c("gpa", "grit", "material_hardship", 
                           "eviction", "layoff", "job_training")
covariates_df <- 
  all_covariates %>% 
  as_data_frame() %>% 
  gather("outcome", "ffvar")

ffvars_scored <- 
  covariates_df %>%
  left_join(ffvars_scored, by = c("outcome", "ffvar"))

gpa_vars <- ffvars_scored %>% filter(outcome == "gpa")
grit_vars <- ffvars_scored %>% filter(outcome == "grit")
materialHardship_vars <- ffvars_scored %>% filter(outcome == "material_hardship")
eviction_vars <- ffvars_scored %>% filter(outcome == "eviction")
layoff_vars <- ffvars_scored %>% filter(outcome == "layoff")
jobTraining_vars <- ffvars_scored %>% filter(outcome == "job_training")

vars_data_list <- list(gpa_vars, grit_vars, materialHardship_vars, 
                       eviction_vars, layoff_vars, jobTraining_vars)
names(vars_data_list) <- as.character(outcomes)

scores_experts <- map(vars_data_list, "experts")
scores_mturkers <- map(vars_data_list, "mturkers")

# set up covariates ----
# these steps are time consuming! 
# approximately 1hr each
x_cache <- lapply(outcomes, setup_x, data = ffc, covariates = covariates)
x_pred_cache <- setup_x_pred(ffc, covariates)

write_rds(x_cache, "data/cached/x_cache.rds")
write_rds(x_pred_cache, "data/cached/x_pred_cache.rds")

# run models ----
prediction_list <- 
  Map(f = function(...) { 
    lasso(data = ffc, 
          covariates = covariates, 
          x_pred_cache = x_pred_cache, 
          ..., parallel = TRUE)$pred 
  }, 
  outcome = outcomes, 
  family = families, 
  x_cache = x_cache,
  alpha = alphas)

# with expert score information
prediction_list_experts <- 
  Map(f = function(...) { 
    lasso(data = ffc, 
          covariates = covariates, 
          x_pred_cache = x_pred_cache, 
          ..., parallel = TRUE)$pred 
  }, 
  outcome = outcomes, 
  scores = scores_experts,
  family = families, 
  x_cache = x_cache,
  alpha = alphas)

# with mturk score information
prediction_list_mturkers <- 
  Map(f = function(...) { 
    lasso(data = ffc, 
          covariates = covariates, 
          x_pred_cache = x_pred_cache, 
          ..., parallel = TRUE)$pred 
  }, 
  outcome = outcomes, 
  scores = scores_mturkers,
  family = families, 
  x_cache = x_cache,
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

zip_prediction(prediction, prediction_name, run_file = "run_lasso_all.R")
zip_prediction(prediction_experts, prediction_name_experts, run_file = "run_lasso_all.R")
zip_prediction(prediction_mturkers, prediction_name_mturkers, run_file = "run_lasso_all.R")
