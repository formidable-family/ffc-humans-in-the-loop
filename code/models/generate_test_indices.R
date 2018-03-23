#' Purpose: help functions for tuning

generate_test_indices <- function(data, outcome) {
  valid_outcomes <- which(!is.na(data[[outcome]]))
  sample(valid_outcomes, .2 * length(valid_outcomes))
}

generate_foldid <- function(data, outcome, test_indices) {
  valid_outcomes <- which(!is.na(data[[outcome]]))
  obs <- setdiff(valid_outcomes, test_indices)
  sample(rep(1:10, ceiling(length(obs)/10)), length(obs))
}

setup_lasso <- function(data, outcome, covariates) {
  # using model.matrix instead of sparse.model.matrix
  # prevents a warning from caret about turning data into a data frame
  
  # only use covariates that are in the provided data
  covariates <- covariates[covariates %in% colnames(data)]
  
  f <- as.formula(paste0(outcome, " ~ ", paste0(covariates, collapse = " + ")))
  d <- model.frame(f, data)
  x <- model.matrix(f, data = d)[, -1]
  y <- d[[outcome]]
  
  list(x = x, y = y)
}

