library(dplyr)
library(readr)

validate_imputed_background <- function(imputed_background, 
                                        categorical_to_factor = TRUE) {
  # handling for issues with imputed data
  
  # if the imputed data has no challengeID column, add one
  if (!"challengeID" %in% colnames(imputed_background)) {
    challengeID <- data_frame(challengeID = 1:nrow(imputed_background))
    imputed_background <- bind_cols(challengeID, imputed_background)
  }
  
  # if the imputed data still has columns with NAs, get rid of those columns
  na_check <- sapply(imputed_background, function(x) any(is.na(x)))
  still_nas <- names(na_check[na_check])
  imputed_background <- imputed_background %>% select(-one_of(still_nas))
  
  # stop here if categorical_to_factor = FALSE
  if (any(vapply(imputed_background, is.factor, logical(1)))) {
    categorical_to_factor <- TRUE
  }
  if (!categorical_to_factor) return(imputed_background)
  
  # convert categorical variables to factors
  categorical_vars <- read_lines("data/variables/categorical.txt")
  categorical_vars <- 
    categorical_vars[categorical_vars %in% colnames(imputed_background)]
  
  d1 <- imputed_background %>% select(-one_of(categorical_vars))
  d2 <- 
    imputed_background %>%
    select(one_of(categorical_vars)) %>%
    Map(as.factor, .)
  
  bind_cols(d1, d2)
}