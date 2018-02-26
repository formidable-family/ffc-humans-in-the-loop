#!/bin/bash
# create lists of variable metadata
Rscript -e "rmarkdown::render('code/data_processing/variable_metadata.Rmd', output_file='variable_metadata.html')" &&
mv code/data_processing/variable_metadata.html doc/vignettes/variable_metadata.html &&

# set up and do imputations
Rscript code/imputation/setup_mi_data.R &&
Rscript code/imputation/mi.R &&

# run models
Rscript code/runs/run_lasso_mi.R &&
Rscript code/runs/run_lasso_mi_constructed.R &&

echo "Done"