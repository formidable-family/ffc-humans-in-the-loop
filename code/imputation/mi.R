library(Amelia)
library(parallel)
library(labelled)
detectCores(logical = FALSE)

source("https://raw.githubusercontent.com/ccgilroy/ffc-data-processing/master/R/get_vars.R")

background_ffvars <- readRDS("data/background_ffvars_to_mi.rds")

categorical <- get_vars_categorical(background_ffvars)

Sys.time()
mi_background_ffvars <- 
  amelia(background_ffvars, m = 5, 
         idvars = c("challengeID"),
         noms = categorical, 
         empri = .1 * nrow(background_ffvars), 
         tolerance = .005,
         boot.type = "none", 
         parallel = "snow", 
         ncpus = 5)

saveRDS(mi_background_ffvars, "data/background_ffvars_amelia.rds")
Sys.time()

# constructed ----

background_constructed <- readRDS("data/background_constructed_to_mi.rds")

categorical <- get_vars_categorical(background_constructed)

Sys.time()
mi_background_constructed <- 
  amelia(background_constructed, m = 5, 
         idvars = c("challengeID"),
         noms = categorical, 
         empri = .1 * nrow(background_constructed), 
         tolerance = .005,
         boot.type = "none", 
         parallel = "snow", 
         ncpus = 5)

saveRDS(mi_background_constructed, "data/background_constructed_amelia.rds")
Sys.time()
