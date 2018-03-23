#' Purpose: approximately tune alpha parameter for different outcomes (NOT RUN AGAIN)
#' Inputs: run_lasso.R
#' Outputs: hardcoded series of alpha values
#' Machine used: laptop
#' Expected runtime: hour

# notes ----
# run run_lasso.R to set up, through line 59

source("models/generate_test_indices.R")

set.seed(42)
gpa_test <- generate_test_indices(ffc, "gpa")
gpa_foldid <- generate_foldid(ffc, "gpa", gpa_test)
# test_fit <- lasso(ffc, "gpa", covariates$gpa, test_indices = gpa_test)

# alphas <- seq(0, 1, .1)
alphas <- c(0, .025, .05, .075, .1, .125, .15, .175, .2, .25)
test_gpa_alphas <- 
  lapply(alphas, function(x)  { 
    lasso(ffc, "gpa", covariates$gpa, test_indices = gpa_test, 
          alpha = x, foldid = gpa_foldid)
  })

gpa_alphas <- 
  data_frame(alpha = alphas,
             mse = map_dbl(test_gpa_alphas, "mse"), 
             test_mse = map_dbl(test_gpa_alphas, "test_mse"))

set.seed(36)
grit_test <- generate_test_indices(ffc, "grit")
grit_foldid <- generate_foldid(ffc, "grit", grit_test)

test_grit_alphas <- 
  lapply(alphas, function(x)  { 
    lasso(ffc, "grit", covariates$grit, test_indices = grit_test,
          alpha = x, foldid = grit_foldid)
  })

grit_alphas <- 
  data_frame(alpha = alphas,
             mse = map_dbl(test_grit_alphas, "mse"), 
             test_mse = map_dbl(test_grit_alphas, "test_mse"))


set.seed(54)
layoff_test <- generate_test_indices(ffc, "layoff")
layoff_foldid <- generate_foldid(ffc, "layoff", layoff_test)

test_layoff_alphas <- 
  lapply(alphas, function(x)  { 
    lasso(ffc, "layoff", covariates$layoff, test_indices = layoff_test,
          family = "binomial",
          alpha = x, foldid = layoff_foldid)
  })

layoff_alphas <- 
  data_frame(alpha = alphas,
             mse = map_dbl(test_layoff_alphas, "mse"), 
             test_mse = map_dbl(test_layoff_alphas, "test_mse"))


# using caret ----
library(caret)
control <- trainControl(method = "repeatedcv", repeats = 3, verboseIter = TRUE)
# redo with a narrower set of alphas
egrid <- expand.grid( # .alpha = c(0, .1, .2, .25, .3, .4, .5, .75, .9, 1), 
                     .alpha = c(0, .025, .05, .075, .1, .125, .15, .175, .2, .25),
                     .lambda = 1:10 * .1)

gpa_setup <- setup_lasso(ffc, "gpa", covariates$gpa)
gpa_caret <- train(x = gpa_setup$x, 
                   y = gpa_setup$y, 
                   method = "glmnet",
                   tuneGrid = egrid, 
                   trControl = control) 
# alpha = 0.1, lambda = 0.3
# refined alpha = .05

grit_setup <- setup_lasso(ffc, "grit", covariates$grit)
grit_caret <- train(x = grit_setup$x, 
                    y = grit_setup$y, 
                    method = "glmnet",
                    tuneGrid = egrid, 
                    trControl = control) 
# alpha = 0.1, lambda = 0.2
# refined alpha = 0.1

materialHardship_setup <- setup_lasso(ffc, "materialHardship", covariates$materialHardship)
materialHardship_caret <- train(x = materialHardship_setup$x, 
                                y = materialHardship_setup$y, 
                                method = "glmnet",
                                tuneGrid = egrid, 
                                trControl = control) 
# alpha = 0.1, lambda = 0.1
# refined alpha = 0.025

eviction_setup <- setup_lasso(ffc, "eviction", covariates$eviction)
eviction_caret <- train(x = eviction_setup$x, 
                        y = eviction_setup$y, 
                        method = "glmnet", 
                        tuneGrid = egrid, 
                        trControl = control, 
                        family = "binomial")
# alpha = .1, lambda = 1
# refined alpha = .15

layoff_setup <- setup_lasso(ffc, "layoff", covariates$layoff)
layoff_caret <- train(x = layoff_setup$x, 
                      y = layoff_setup$y, 
                      method = "glmnet", 
                      tuneGrid = egrid, 
                      trControl = control, 
                      family = "binomial")
# alpha = .1, lambda = .4
# refined alpha = .05

jobTraining_setup <- setup_lasso(ffc, "jobTraining", covariates$jobTraining)
jobTraining_caret <- train(x = jobTraining_setup$x, 
                           y = jobTraining_setup$y, 
                           method = "glmnet", 
                           tuneGrid = egrid, 
                           trControl = control, 
                           family = "binomial")
# alpha = .1, lambda = .4
# refined alpha = .05


