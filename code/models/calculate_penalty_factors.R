#' Purpose: map scores to penalties for lambda parameter in glmnet
#' (See runs for run information)

library(stringr)

calculate_penalty_factors <- function(model_covariates, 
                                      original_covariates, 
                                      scores,
                                      link = identity) {
  # model.matrix removes duplicate covariates
  # and expands / renames factor variables
  # this function maps scores of original covariates
  # to penalties (0 to 1) for actual model covariates
  
  if (length(original_covariates) != length(scores)) {
    # Is this true? What if scored variables are subset of original covariates?
    stop("Scores must match original covariates in length.")
  }
  
  penalties <- rep(1, length(model_covariates))
  # TODO: vectorize this
  for (i in seq_along(original_covariates)) {
    # TODO: handle duplicated covariates better
    j <- which(str_detect(model_covariates, original_covariates[i]))
    score <- link(1 - scores[i] / 100)
    penalties[j] <- if (!is.na(score)) score else 1
  }
  
  penalties
}