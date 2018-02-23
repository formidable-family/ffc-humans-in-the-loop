#!/bin/bash
# create lists of variable metadata
Rscript -e "rmarkdown::render('code/data_processing/variable_metadata.Rmd', output_file='doc/vignettes/variable_metadata.html") &&

# set up and do imputations
Rscript code/imputation/setup_mi_data.R &&