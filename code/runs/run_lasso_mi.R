library(tidyverse)
library(doParallel)
registerDoParallel(cores = parallel::detectCores(logical = FALSE))

# for more info on
# cv.glmnet with parallel = TRUE and doParallel package:
# https://stackoverflow.com/a/21710769
# https://stackoverflow.com/a/29001039

source("models/calculate_penalty_factors.R")
source("models/lasso.R")
source("models/setup_lasso_all.R")

source("utils/validate_imputed_background.R")
source("utils/zip_prediction.R")

source("https://raw.githubusercontent.com/ccgilroy/ffc-data-processing/master/R/get_vars.R")
source("https://raw.githubusercontent.com/ccgilroy/ffc-data-processing/master/R/merge_train.R")
source("https://raw.githubusercontent.com/ccgilroy/ffc-data-processing/master/R/subset_vars.R")

data_file_name <- "background_ffvars_amelia.rds"
prediction_name <- "lasso_amelia_imputation"

# data ----
train <- read_csv(file.path("data", "train.csv"))
imputed_background <- readRDS(file.path("data", data_file_name))

# things that need to be done ONCE for all imputations

# covariates ----
ffvars_scored <- 
  read_csv(file.path("variables", "ffvars_scored.csv")) %>%
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

covariates <- map(vars_data_list, "ffvar")

scores_experts <- map(vars_data_list, "experts")
scores_mturkers <- map(vars_data_list, "mturkers")

families <- as.list(c(rep("gaussian", 3), 
                      rep("binomial", 3)))

# alphas closer to 0 seem to do slightly better (more ridge than lasso)
alphas <- as.list(c(0.05, 0.10, 0.025, 0.15, 0.05, 0.05))

# things that need to be done separately for each imputation

# will return a list of lists of data frames
# 15 data frames total
# fitting 6 * 3 * 5 = 90 models
mi_prediction_list <- lapply(imputed_background$imputations, function(imp) {
  ffc <- merge_train(imp, train)
  
  x_cache <- Map(function(...) setup_x(data = ffc, ...), outcome = outcomes, covariates = covariates)
  x_pred_cache <- Map(function(...) setup_x_pred(data = ffc, ...), covariates = covariates)
  
  # without score information
  prediction_list <- 
    Map(f = function(...) lasso(data = ffc, ..., parallel = TRUE)$pred, 
        outcome = outcomes, 
        covariates = covariates, 
        x_cache = x_cache, 
        x_pred_cache = x_pred_cache,
        family = families, 
        alpha = alphas)
  
  # with expert score information
  prediction_list_experts <- 
    Map(f = function(...) lasso(data = ffc, ..., parallel = TRUE)$pred, 
        outcome = outcomes, 
        covariates = covariates, 
        x_cache = x_cache, 
        x_pred_cache = x_pred_cache,
        scores = scores_experts,
        family = families, 
        alpha = alphas)
  
  # with mturk score information
  prediction_list_mturkers <- 
    Map(f = function(...) lasso(data = ffc, ..., parallel = TRUE)$pred, 
        outcome = outcomes, 
        covariates = covariates, 
        x_cache = x_cache, 
        x_pred_cache = x_pred_cache,
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
  
  # return predictions
  list(prediction = prediction, 
       prediction_experts = prediction_experts, 
       prediction_mturkers = prediction_mturkers)
})

# merge predictions here
# sometimes the tidyverse is so beautiful I could cry
prediction <-
  map(mi_prediction_list, "prediction") %>%
  bind_rows() %>%
  group_by(challengeID) %>%
  summarise_all(mean)

prediction_experts <- 
  map(mi_prediction_list, "prediction_experts") %>%
  bind_rows() %>%
  group_by(challengeID) %>%
  summarise_all(mean)

prediction_mturkers <-
  map(mi_prediction_list, "prediction_mturkers") %>%
  bind_rows() %>%
  group_by(challengeID) %>%
  summarise_all(mean)

# output ----
# write to csv and zip for submission

prediction_name_experts <- paste0(prediction_name, "_experts")
prediction_name_mturkers <- paste0(prediction_name, "_mturkers")

zip_prediction(prediction, prediction_name, run_file = "run_lasso_mi.R")
zip_prediction(prediction_experts, prediction_name_experts, run_file = "run_lasso_mi.R")
zip_prediction(prediction_mturkers, prediction_name_mturkers, run_file = "run_lasso_mi.R")
