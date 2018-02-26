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

# read lists of continuous and categorical variables
vars_continuous <- read_lines("data/variables/continuous.txt")
vars_categorical <- read_lines("data/variables/categorical.txt")

# create correlation matrix
output_typed <- corMatrix(data = yourDF, 
                          continuous = vars_continuous, 
                          categorical = vars_categorical)
# impute data frame
lm_typed_df <- regImputation(yourDF, output_typed,                    
                             continuous = vars_continuous, 
                             categorical = vars_categorical, 
                             top_predictors = 5, 
                             threshold = .1,
                             parallel = reg_parallel, 
                             failmode = "impute")

saveRDS("data/imputed/imputed-lm-vartype.rds")
