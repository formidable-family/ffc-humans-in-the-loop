#' Purpose: Imputes missing values of covariates using regularized regression for constructed subset of variables
#' Inputs: data/background.csv
#' Outputs: data/imputed/imputed-lasso-constructed.rds
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
output_untyped <- corMatrix(data=yourDF, 
                            varpattern = '^c[mfhpktfvino]{1,2}[12345]')

# impute data frame
lasso_untyped_constructed_df <- regImputation(yourDF, output_untyped,    
                                              method = "lasso",
                                              top_predictors = 5, 
                                              threshold = .1, 
                                              parallel = 0, 
                                              failmode = "impute")

saveRDS(lasso_untyped_constructed_df, "data/imputed/imputed-lasso-constructed.rds")
