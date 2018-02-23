# character variables ----

# variables with decimals are definitely continuous
# variables with non-numeric string values are definitely categorical
# variables with only integer values are ambiguous

get_vars_character <- function(data) {
  chars_info <- vapply(data, is.character, logical(1))
  names(which(chars_info))
}

get_vars_char_decimal <- function(data) {
  # returns characters variables that can be converted to numerics
  # and that take on decimal values
  # this means that they are likely continuous and should be convert to numeric
  if (any(vapply(data, function(x) is.character(x) && "NA" %in% x, 
                 logical(1)))) {
    # must convert "NA" to NA before using
    stop("Convert string 'NA' to NA before using.")
  }
  decimal_info <- vapply(data, function(x) { 
    # a few character columns throw warnings because they contain
    # non-numeric character values
    # return FALSE instead
    tryCatch(is.character(x) && any(as.numeric(x) %% 1 != 0),
             warning = function(w) FALSE)
    # is.character(x) && any(as.numeric(x) %% 1 != 0)
  }, logical(1))
  names(which(decimal_info))
}

get_vars_char_nonnumeric <- function(data) {
  # returns character variables that cannot be converted to numerics
  # without NA coercion
  # this means they are likely categorical and should be converted to factors
  if (any(vapply(data, function(x) is.character(x) && "NA" %in% x, 
                 logical(1)))) {
    # must convert "NA" to NA before using
    stop("Convert string 'NA' to NA before using.")
  } 
  char_info <- vapply(data, function(x) {
    is.character(x) && tryCatch({ 
      # false if successfully converts to numeric
      as.numeric(x) 
      FALSE 
    }, 
    # true if throws a warning about NA conversion
    warning = function(w) TRUE
    )
  }, logical(1))
  names(which(char_info))
}

get_vars_char_int <- function(data) {
  # returns characters variables that can be converted to numerics
  # and that NEVER take on decimal values
  # it is unclear whether these are categorical or continuous
  # a reasonable heuristic is the number of unique values
  if (any(vapply(data, function(x) is.character(x) && "NA" %in% x, 
                 logical(1)))) {
    # must convert "NA" to NA before using
    stop("Convert string 'NA' to NA before using.")
  }
  int_info <- vapply(data, function(x) { 
    # a few character columns throw warnings because they contain
    # non-numeric character values
    # return FALSE instead
    tryCatch(is.character(x) && all(as.numeric(x) %% 1 == 0, na.rm = TRUE),
             warning = function(w) FALSE)
    # is.character(x) && any(as.numeric(x) %% 1 != 0)
  }, logical(1))
  names(which(int_info))
}

# labelled variables ----

get_vars_labelled <- function(data) {
  labelled_info <- vapply(data, is.labelled, logical(1))
  names(which(labelled_info))
}

is_labelled_factor <- function(x) {
  # if a labelled variable has labels for values greater than 0, 
  # then it is most likely a categorical variable
  is.labelled(x) && max(as.numeric(val_labels(x)), na.rm = TRUE) >= 0 
}

get_vars_labelled_factor <- function(data) {
  # uses is_labelled_factor to evaluate variables in a data frame
  # returns the names of the *labelled* variables that are likely categorical
  factor_info <- vapply(data, is_labelled_factor, logical(1))
  names(which(factor_info))
}

is_labelled_numeric <- function(x) {
  # if a labelled variable only has labels for negative values, 
  # e.g., "-1 Refuse", then it is most likely numeric
  is.labelled(x) && max(as.numeric(val_labels(x)), na.rm = TRUE) < 0
}

get_vars_labelled_numeric <- function(data) {
  # uses is_labelled_numeric to evaluate variables in a data frame
  # returns the names of the *labelled* variables that are likely continuous
  numeric_info <- vapply(data, is_labelled_numeric, logical(1))
  names(which(numeric_info))
}

# variable types ----

get_vars_categorical <- function(data) {
  if (any(vapply(data, is.labelled, logical(1)))) {
    warning(
      "Some variables are labelled variables. ", 
      "Convert labelled variables to factors first in order to include them in evaluation."
    )
  }
  if (any(vapply(data, is.character, logical(1)))) {
    warning(
      "Some variables are character variables. ", 
      "Convert character variables to factors first in order to include them in evaluation."    
    )
  }
  categorical_info <- vapply(data, is.factor, logical(1))
  names(which(categorical_info))
}

get_vars_continuous <- function(data) {
  if (any(vapply(data, is.labelled, logical(1)))) {
    warning(
      "Some variables are labelled variables. ", 
      "Convert labelled variables to numerics first in order to include them in evaluation."
    )
  }
  if (any(vapply(data, is.character, logical(1)))) {
    warning(
      "Some variables are character variables. ", 
      "Convert character variables to numerics first in order to include them in evaluation."    
    )
  }
  
  continuous_info <- vapply(data, function(x) !is.labelled(x) && is.numeric(x), 
                            logical(1)) 
  continuous_vars <- names(continuous_info[which(continuous_info)])
  
  # challengeID is numeric, but isn't a variable, so remove it
  continuous_vars[continuous_vars != "challengeID"]
}

# subsetting helpers ----

get_vars_constructed <- function(data) {
  # returns the names of constructed variables
  # regex for detecting most constructed variables by Anna Filippova
  c_vars <- str_subset(names(data), "(^c)([mfhpktfvino]{1,2})([12345])(.*)")
  # at least three constructed variables do not follow the c* naming convention
  # discovered by Anna Filippova and Antje Kirchner
  c(c_vars, "n5d2_age", "o5oint", "t5tint")
}

get_vars_na <- function(data, non_na_responses = 0) {
  # by default, returns names of variables for which all responses are NA
  # increasing `non_na_responses` will return variables that have that many
  # or fewer non-NA responses
  # you should do some NA recoding, at least for character variables, 
  # before running this
  if (any(vapply(data, function(x) is.numeric(x) && any(x < 0, na.rm = TRUE), 
                 logical(1)), 
          na.rm = TRUE)) {
    warning("Some variables have negative values. Have you recoded numeric NAs?")
  }
  if (any(vapply(data, function(x) is.character(x) && "NA" %in% x, 
                 logical(1)))) {
    warning("Some variables have the string 'NA'. Have you recoded character NAs?")
  }
  max_nas <- nrow(data)
  na_info <- vapply(data, function(x) length(which(is.na(x))), numeric(1))
  names(which(na_info >= max_nas - non_na_responses))
}

get_vars_low_variance <- function(data, variance_threshold = 0) {
  # by default, returns variables with zero variance
  # similar to get_vars_unique, which is recommended over this function
  if (any(vapply(data, is.character, logical(1)))) {
    warning("Convert character variables before evaluating variance")
  }
  variance_info <- vapply(data, function(x) var(as.numeric(x), na.rm = TRUE), 
                          numeric(1))
  names(which(variance_info <= variance_threshold))
}

get_vars_unique <- function(data, unique_threshold = 1) {
  # by default, returns names of variables with one or zero unique non-NA values
  # increasing unique_threshold is not recommended
  unique_info <- vapply(data, function(x) length(unique(x[!is.na(x)])), numeric(1))
  names(which(unique_info <= unique_threshold))
}
