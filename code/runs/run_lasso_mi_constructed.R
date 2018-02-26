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
source("code/models/setup_lasso_all.R")

source("code/utils/validate_imputed_background.R")
source("code/utils/zip_prediction.R")

source("code/data_processing/R/get_vars.R")
source("code/data_processing/R/merge_train.R")
source("code/data_processing/R/subset_vars.R")

data_file_name <- "background_constructed_amelia.rds"
prediction_name <- "lasso_amelia_imputation_constructed"

# data ----
train <- read_csv(file.path("data", "train.csv"))
imputed_background <- readRDS(file.path("data", "imputed", data_file_name))

# things that need to be done ONCE for all imputations

# models ----
outcomes <- list("gpa", "grit", "materialHardship", 
                 "eviction", "layoff", "jobTraining")

covariates <- colnames(imputed_background$imputations$imp1)[-1]

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
  
  x_cache <- lapply(outcomes, setup_x, data = ffc, covariates = covariates)
  x_pred_cache <- setup_x_pred(ffc, covariates)
  
  # without score information
  prediction_list <- 
    Map(f = function(...) lasso(data = ffc, covariates = covariates, x_pred_cache = x_pred_cache, ..., parallel = TRUE)$pred, 
        outcome = outcomes, 
        x_cache = x_cache, 
        family = families, 
        alpha = alphas)
  
  # predictions ----
  names(prediction_list) <- as.character(outcomes)
  prediction <-
    ffc %>%
    select(challengeID) %>%
    bind_cols(prediction_list)

  prediction
})

# merge predictions here
# sometimes the tidyverse is so beautiful I could cry
prediction <-
  mi_prediction_list %>%
  bind_rows() %>%
  group_by(challengeID) %>%
  summarise_all(mean)

# output ----
# write to csv and zip for submission

zip_prediction(prediction, prediction_name, run_file = "run_lasso_mi_constructed.R")
