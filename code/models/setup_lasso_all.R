#' Purpose: cache model matrices for runs using all covariates
#' (See runs for run information)

setup_x <- function(data, outcome, covariates) {
  # create x for reuse across models
  
  # only use covariates that are in the provided data
  covariates <- covariates[covariates %in% colnames(data)]
  
  f <- as.formula(paste0(outcome, " ~ ", paste0(covariates, collapse = " + ")))
  d <- model.frame(f, data)
  sparse.model.matrix(f, data = d)[, -1]
}

setup_x_pred <- function(data, covariates) {
  # create x_pred for reuse across models
  covariates <- covariates[covariates %in% colnames(data)]
  f <- as.formula(paste0(" ~ ", paste0(covariates, collapse = " + ")))
  sparse.model.matrix(f, data = model.frame(~ ., data, na.action = na.pass))[, -1]
}