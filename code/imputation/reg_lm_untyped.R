#' Purpose: Imputes missing values of covariates using linear regression and top 5 correlated covariates
#' Inputs: data/background.csv
#' Outputs: data/imputed/imputed-lm-untyped.rds
#' Machine used: cluster
#' Expected runtime: hours

set.seed(123)

library(devtools)

if (!"FFCRegressionImputation" %in% installed.packages()) {
  devtools::install_github("annafil/FFCRegressionImputation")
}

library(FFCRegressionImputation)
library(dplyr)
library(readr)

# FFCRegressionImputation only supports parallelization 
# on unix-based systems
if (.Platform$OS.type == "unix") {
  reg_parallel <- 1
} else {
  reg_parallel <- 0
}


# read background data
yourDF <- initImputation(data = "data/background.csv") 

# create correlation matrix
output_untyped <- corMatrix(data=yourDF)

# impute data frame
lm_untyped_df <- regImputation(yourDF, output_untyped,    
                               method = "lm",
                               top_predictors = 5, 
                               threshold = .1, 
                               parallel = reg_parallel, 
                               failmode = "impute")

saveRDS(lm_untyped_df, "data/imputed/imputed-lm-untyped.rds")
