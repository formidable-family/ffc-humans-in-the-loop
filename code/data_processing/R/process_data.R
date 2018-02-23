process_data_minimal <- function(data) {
  # wrapper that does the most justifiable recoding and conversion
  # to the background data
  # addresses character NAs, 
  # converts all labelled variables to factors or numerics
  # and converts some character variables to factors or numerics
  # does NOT address missings in the data,
  # leaves most character variables as characters, 
  # and does not remove any variables
  data %>%
    recode_na_character() %>%
    labelled_to_factor() %>%
    labelled_to_numeric() %>%
    character_to_factor() %>%
    character_to_numeric()
}

process_data_maximal <- function(data) {
  data %>%
    recode_na_character() %>%
    labelled_to_factor() %>%
    labelled_to_numeric() %>%
    character_to_factor() %>%
    character_to_numeric() %>%
    # use a less conservative threshold than default
    character_to_factor_or_numeric(threshold = 29) %>%
    recode_na_factor() %>%
    recode_na_numeric() %>%
    subset_vars_remove(get_vars_na) %>%
    subset_vars_remove(get_vars_unique)
}
