library(Amelia)
library(parallel)
library(foreach)
library(doParallel)
library(doRNG)
library(labelled)

detectCores(logical = FALSE)
registerDoParallel(cores = 5)

source("code/data_processing/R/get_vars.R")

background_ffvars <- readRDS("data/imputed/mi_setup/background_ffvars_to_mi.rds")

categorical <- get_vars_categorical(background_ffvars)

Sys.time()

# https://lists.gking.harvard.edu/pipermail/amelia/2013-June/001023.html
# https://gist.github.com/jrnold/1236095/4f6076e824bbefec32f03c446f6cefb70f651a2e
# https://cran.r-project.org/web/packages/doRNG/index.html
set.seed(123)
mi_background_ffvars <- 
  foreach(i = 1:5, 
          .combine = "ameliabind", 
          .packages = "Amelia") %dorng% {
            amelia(background_ffvars, m = 1, 
                   idvars = c("challengeID"),
                   noms = categorical, 
                   empri = .1 * nrow(background_ffvars), 
                   parallel = "no",
                   tolerance = .005,
                   boot.type = "none")
          }

saveRDS(mi_background_ffvars, "data/imputed/background_ffvars_amelia.rds")
Sys.time()
