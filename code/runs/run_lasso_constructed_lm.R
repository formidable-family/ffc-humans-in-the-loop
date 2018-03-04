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

data_file_name <- "imputed-lm-vartype.rds"
prediction_name <- "glmnet_lm_constructed"

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
  subset_vars_remove(get_vars_unique) %>%
  subset_vars_remove(get_vars_constructed)

ffc <- merge_train(imputed_background, train) %>% arrange(challengeID)

# models ----
outcomes <- list("gpa", "grit", "materialHardship", 
                 "eviction", "layoff", "jobTraining")

covariates <- colnames(imputed_background)[-1]

families <- as.list(c(rep("gaussian", 3), 
                      rep("binomial", 3)))

alphas <- as.list(c(0.05, 0.10, 0.025, 0.15, 0.05, 0.05))

# these steps are time consuming! 
# approximately 1hr each
x_cache <- lapply(outcomes, setup_x, data = ffc, covariates = covariates)
x_pred_cache <- setup_x_pred(ffc, covariates)

write_rds(x_cache, "data/cached/x_cache_constructed_lm.rds")
write_rds(x_pred_cache, "data/cached/x_pred_cache_constructed_lm.rds")

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

# predictions ----
names(prediction_list) <- as.character(outcomes)
prediction <- 
  ffc %>% 
  select(challengeID) %>%
  bind_cols(prediction_list)

zip_prediction(prediction, prediction_name, run_file = "run_lasso_constructed_lm.R")
