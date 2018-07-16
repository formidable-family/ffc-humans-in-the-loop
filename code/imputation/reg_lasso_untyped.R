#' Purpose: Imputes missing values of covariates using regularized regression
#' Inputs: data/background.csv
#' Outputs: data/imputed/imputed-fulldata-lasso.rds
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

# read background data
yourDF <- initImputation(data = "data/background.csv") 

# create correlation matrix
output_untyped <- corMatrix(data=yourDF)

# impute data frame
lasso_untyped_df <- regImputation(yourDF, output_untyped,    
                                  method = "lasso",
                                  top_predictors = 5, 
                                  threshold = .1, 
                                  parallel = 0, 
                                  failmode = "impute")

saveRDS(lasso_untyped_df, "data/imputed/imputed-fulldata-lasso.rds")
