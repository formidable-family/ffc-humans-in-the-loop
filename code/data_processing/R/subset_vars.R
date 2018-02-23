subset_vars_keep <- function(data, get_vars) {
  # subsets data using a get_vars function to select variables to keep
  # always keeps challengeID to identify observations
  data %>% select(challengeID, one_of(get_vars(data)))
}

subset_vars_remove <- function(data, get_vars) {
  # subsets data by removing variables selected by a get_vars function
  data %>% select(-one_of(get_vars(data)))
}
