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

gg_miss_case(background, order_cases = TRUE)

x <- gg_miss_case(background)
summary_row <- miss_case_summary(background)
print(summary_row)
avg_row <- mean(as.numeric(summary_row$pct_miss))
print(sprintf("Average %% missing within a row %.4f", avg_row))


y <- 
  gg_miss_var(background, show_pct = TRUE) + 
  theme(axis.ticks.y=element_blank(), axis.text.y=element_blank())

gg_miss_var(background, show_pct = TRUE) + 
  theme(axis.ticks.y=element_blank(), axis.text.y=element_blank())

summary_col <- miss_var_summary(background)
print(summary_col)
avg_col <- mean(as.numeric(summary_col$pct_miss))
# print(sprintf("Average %% missing within a column %.4f", avg_col)) # Should be the same as above

d <- dim(background)
total_miss <- sum(as.numeric(summary_col$n_miss))*100/(d[1]*d[2])
print(sprintf("%% missing within the whole table %.4f", total_miss))