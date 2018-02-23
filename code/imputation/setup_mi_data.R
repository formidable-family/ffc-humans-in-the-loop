library(FFCRegressionImputation)

source("init.R")

background <- initImputation(data = "data/background.csv", 
                             dropna = 1, 
                             ageimpute = 0, 
                             meanimpute = 0)

background <- 
  background %>%
  subset_vars_remove(get_vars_na) %>%
  subset_vars_remove(get_vars_unique) 

ffvars <- read_lines("output/ffvars.txt")
categorical <- read_lines("output/categorical.txt")
continuous <- read_lines("output/continuous.txt")

categorical <- categorical[categorical %in% names(background)]

d1 <- background %>% select(-one_of(categorical))
d2 <- 
  background %>% 
  select(one_of(categorical)) %>%
  Map(as.factor, .)
  
background <- bind_cols(d1, d2) %>% select(one_of(names(background)))

write_rds(background, "data/background_to_mi.rds")

background_constructed <- 
  background %>%
  subset_vars_keep(get_vars_constructed)

write_rds(background_constructed, "data/background_constructed_to_mi.rds")

ffvars <- ffvars[ffvars %in% names(background)]
background_ffvars <- background %>% select(challengeID, one_of(ffvars))
background_ffvars$hv5_ppvtpr <- as.numeric(background_ffvars$hv5_ppvtpr)

write_rds(background_ffvars, "data/background_ffvars_to_mi.rds")
