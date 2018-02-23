# summary functions ----

summarize_variable_classes <- function(data) {
  # evaluates the class distribution of variables in a data frame
  # use to assess results of class conversion functions
  summary(as.factor(vapply(data, class, character(1))))
}

# character variables ----

character_to_numeric <- function(data) {
  # characters with all-numeric values that include noninteger values are 
  # converted to numerics. 
  cols_in_order <- names(data)
  numeric_vars <- get_vars_char_decimal(data)
  d1 <- data %>% select(-one_of(numeric_vars))
  d2 <- data %>% select(one_of(numeric_vars)) %>% Map(as.numeric, .)
  bind_cols(d1, d2) %>% select(one_of(cols_in_order))
}

character_to_factor <- function(data) {
  # characters with string values that can't be numeric are converted to factors
  # this includes censored variables that would otherwise be numeric
  # (e.g., an age variable with an "18 and younger" category)
  cols_in_order <- names(data)
  factor_vars <- get_vars_char_nonnumeric(data)
  d1 <- data %>% select(-one_of(factor_vars))
  d2 <- data %>% select(one_of(factor_vars)) %>% Map(as.factor, .)
  bind_cols(d1, d2) %>% select(one_of(cols_in_order))
}

character_to_factor_or_numeric <- function(data, threshold = 100) {
  # characters with many unique values are likely to be continuous
  # characters with few unique values are likely to be categorical
  # by default, threshold for 'many' is 100, which is very conservative
  cols_in_order <- names(data)
  int_vars <- get_vars_char_int(data)
  d1 <- data %>% select(-one_of(int_vars))
  d2 <- data %>% select(one_of(int_vars))
  
  # does the non-NA thing matter here? maybe should keep, for consistency
  unique_info <- 
    vapply(d2, function(x) length(unique(x[!is.na(x)])), numeric(1))
  
  # greater than or equal to threshold -> numeric/continuous
  d2_numeric_vars <- names(which(unique_info >= threshold))
  d2_numeric <- 
    d2 %>% 
    select(one_of(d2_numeric_vars)) %>% 
    Map(as.numeric, .)
    
  # less than threshold -> factor/categorical
  d2_factor <- 
    d2 %>% 
    select(-one_of(d2_numeric_vars)) %>%
    Map(as.factor, .)
  
  bind_cols(d1, d2_numeric, d2_factor) %>% select(one_of(cols_in_order))
}

# labelled variables ----

labelled_to_factor <- function(data) {
  # converts labeled variables that are likely categorical to factors
  # avoids use of mutate_if or mutate_at for speedup (with dplyr 0.7.1)
  cols_in_order <- names(data)
  factor_vars <- get_vars_labelled_factor(data)
  d1 <- data %>% select(-one_of(factor_vars))
  d2 <- data %>% select(one_of(factor_vars)) %>% haven::as_factor()
  bind_cols(d1, d2) %>% select(one_of(cols_in_order))
}

labelled_to_numeric <- function(data) {
  # converts labeled variables that are likely continuous to numeric
  # avoids use of mutate_if or mutate_at for speedup (with dplyr 0.7.1)
  cols_in_order <- names(data)
  numeric_vars <- get_vars_labelled_numeric(data)
  d1 <- data %>% select(-one_of(numeric_vars))
  d2 <- data %>% select(one_of(numeric_vars)) %>% Map(as.numeric, .)
  bind_cols(d1, d2) %>% select(one_of(cols_in_order))
}
