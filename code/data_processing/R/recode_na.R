recode_na_character <- function(data) {
  # addresses the fact that for some variables, NA is read into R as "NA"
  # this is a technical recoding that makes no assumptions about different kinds
  # of missingness
  # to deal with labelled missing values, convert to factor or numeric and use
  # the appropriate function, AFTER running this function
  cols_in_order <- names(data)
  d1 <- Filter(function(x) !is.character(x), data)
  d2 <- Filter(is.character, data) 
  d2[d2 == "NA"] <- NA
  bind_cols(d1, d2) %>% select(one_of(cols_in_order))
}

set_factor_nas <- function(x) {
  # helper function for recode_na_factor
  factor_nas <- c("-9 Not in wave",
                  "-8 Out of range", 
                  "-7 N/A",
                  "-6 Skip", 
                  "-5 Not asked",
                  "-4 Multiple ans",
                  "-3 Missing", 
                  "-2 Don't know", 
                  "-1 Refuse")
  x %>%
    fct_collapse(missing = factor_nas[factor_nas %in% levels(x)]) %>%
    fct_recode(NULL = "missing")
}

recode_na_factor <- function(data) {
  # NOTE:
  # there are some rare labels, like "-12 Still breastfeed" and 
  # "-11 >12 hours" for specific questions
  # -10, in particular, has a variety of possible labels
  # these are not handled by this recoding function
  # see list in set_factor_nas 

  cols_in_order <- names(data)
  d1 <- Filter(function(x) !is.factor(x), data)
  d2 <- Filter(is.factor, data) %>% Map(set_factor_nas, .)
  # d2[d2 %in% factor_nas] <- NA
  bind_cols(d1, d2) %>% select(one_of(cols_in_order))
}

recode_na_labelled <- function(data) {
  # Filter() is faster than select()
  cols_in_order <- names(data)
  d1 <- Filter(function(x) !is.labelled(x), data)
  d2 <- Filter(is.labelled, data) 
  d2[d2 < 0] <- NA
  bind_cols(d1, d2) %>% select(one_of(cols_in_order))
}

recode_na_numeric <- function(data) {
  # only recodes non-labelled numerics
  # use recode_na_labelled for labelled numerics
  # or convert labelled to numeric first
  cols_in_order <- names(data)
  d1 <- Filter(function(x) !is.numeric(x) || is.labelled(x), data)
  d2 <- Filter(function(x) !is.labelled(x) && is.numeric(x), data) 
  d2[d2 < 0] <- NA
  bind_cols(d1, d2) %>% select(one_of(cols_in_order))
}

recode_na_all <- function(data) {
  # NOTE: This function takes a very expansive definition of NA
  # which isn't theoretically justified (particularly for -6 Skip)
  
  factor_nas <- c("-9 Not in wave",
                  "-8 Out of range", 
                  "-7 N/A",
                  "-6 Skip", 
                  "-5 Not asked",
                  "-4 Multiple ans",
                  "-3 Missing", 
                  "-2 Don't know", 
                  "-1 Refuse")
  
  cols_in_order <- names(data)
  # this should cover all possible variable types
  # but that isn't validated programmatically
  d1 <- Filter(is.character, data)
  d2 <- Filter(function(x) is.numeric(x) || is.labelled(x), data)
  d3 <- Filter(is.factor, data)
  
  # character
  d1[d1 == "NA"] <- NA
  
  # numeric and labelled
  d2[d2 < 0] <- NA
  
  # factor
  d3 <- Map(set_factor_nas, d3)
  
  bind_cols(d1, d2, d3) %>% select(one_of(cols_in_order))
}
