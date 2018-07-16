#' Purpose: Imputes missing values of covariates using central tendency
#' Inputs: data/background.csv, data/variables/continuous.txt, data/variables/categorical.txt
#' Outputs: data/imputed/meanmode_imputed.rds
#' Machine used: cluster
#' Expected runtime: hour

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

# read lists of continuous and categorical variables
vars_continuous <- read_lines("data/variables/continuous.txt")
vars_categorical <- read_lines("data/variables/categorical.txt")

# create correlation matrix
output_typed <- corMatrix(data = yourDF, 
                          continuous = vars_continuous, 
                          categorical = vars_categorical)

# impute data frame
meanmode_typed_df <- regImputation(yourDF, output_typed,  
                                   method = "",
                                   top_predictors = 0, 
                                   threshold = 1, 
                                   continuous = vars_continuous, 
                                   categorical = vars_categorical,
                                   parallel = 0, 
                                   failmode = "impute")

saveRDS(meanmode_typed_df, "data/imputed/meanmode_imputed.rds")
