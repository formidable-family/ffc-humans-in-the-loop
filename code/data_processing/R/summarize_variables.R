summarize_variables <- function(raw_data, 
                                processed_data = NULL, 
                                process_data = process_data_minimal) {
  # processes background data, 
  # returning a data frame where each observation is a variable, 
  # with information about labels, non-NA unique values, 
  # and probable variable types
  # by default, uses process_data_minimal, 
  # and records unconverted character variables as of "unknown" type
  # can speed up by passing in processed data separately
  
  # to keep all labels, start with original background.dta as raw_data
  label <- vapply(raw_data, function(x) { 
    label <- attr(x, "label", exact = TRUE) 
    if (is.null(label)) NA_character_ else label
  }, character(1))
  
  # then, process data
  # by default, minimal processing
  data <- if(is.null(processed_data)) process_data(raw_data) else processed_data
  
  # gets unique non-NA values
  # if all values are NA, will be 0
  unique_values <- 
    vapply(data, function(x) length(unique(x[!is.na(x)])), numeric(1))
  
  # variable type 
  categorical <- get_vars_categorical(data)
  continuous <- get_vars_continuous(data)
  unknown <- get_vars_character(data)
  
  d_categorical <- 
    data_frame(variable = categorical, 
               variable_type = rep("categorical", length(categorical)))
  d_continuous <- 
    data_frame(variable = continuous, 
               variable_type = rep("continuous", length(continuous)))
  d_unknown <- 
    data_frame(variable = unknown, 
               variable_type = rep("unknown", length(unknown)))
  
  d_variable_type <- bind_rows(d_categorical, d_continuous, d_unknown)
  
  data_frame(
    variable = names(data),
    label = label, 
    unique_values = unique_values
  ) %>% 
    full_join(d_variable_type, by = "variable")
}
