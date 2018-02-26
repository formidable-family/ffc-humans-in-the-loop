set.seed(123)

library(Amelia)
library(parallel)
library(labelled)
detectCores(logical = FALSE)

# the parallel backend to use for Amelia is different 
# between windows and unix-based systems
if (.Platform$OS.type == "windows") {
  options(amelia.parallel = "snow")
} else {
  options(amelia.parallel = "multicore")
}

source("code/data_processing/R/get_vars.R")

# constructed ----

background_constructed <- readRDS("data/imputed/mi_setup/background_constructed_to_mi.rds")

categorical <- get_vars_categorical(background_constructed)

Sys.time()
mi_background_constructed <- 
  amelia(background_constructed, m = 5, 
         idvars = c("challengeID"),
         noms = categorical, 
         empri = .1 * nrow(background_constructed), 
         tolerance = .005,
         boot.type = "none", 
         ncpus = 5)

saveRDS(mi_background_constructed, "data/imputed/background_constructed_amelia.rds")
Sys.time()
