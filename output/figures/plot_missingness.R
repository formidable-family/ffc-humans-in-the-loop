library(FFCRegressionImputation)
library(naniar)
library(ggplot2)

background <- initImputation(data = "data/background.csv", 
                             dropna = 1, 
                             ageimpute = 0, 
                             meanimpute = 0)

# source("code/data_processing/init.R")
# background <- 
#   background %>%
#   subset_vars_remove(get_vars_na)

x <- gg_miss_case(background)

y <- 
  gg_miss_var(background, show_pct = TRUE) + 
  theme(axis.ticks.y=element_blank(), axis.text.y=element_blank())
