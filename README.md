# Humans in the Loop: an approach to the Fragile Families Challenge

This repository contains the replication code for the paper "Humans in the Loop: Incorporating Expert and Crowdsourced Knowledge for Predictions using Survey Data" by Anna Filippova, Connor Gilroy, Ridhi Kashyap, Antje Kirchner, Allison C Morgan, Kivan Polimis, Adaner Usmani, and Tong Wang.

In this paper, we take a novel approach to the prediction task of the [Fragile Families Challenge](http://www.fragilefamilieschallenge.org/), with broader implications for machine learning approaches to survey data. Our primary innovation is to rank variable importance through wikisurveys of domain experts and MTurkers, and then incorporate those ranked scores into regularized regression models. Additionally, we compare several approaches to subsetting variables and to imputing missing data. Altogether, this code produces 25 sets of predictions for each of six outcomes.

For questions about this code, please contact Connor Gilroy (cgilroy [at] uw [dot] edu).

# Code overview

Broadly, this repository follows the organizational structure proposed [here](http://www.fragilefamilieschallenge.org/computational-reproducibility-and-the-fragile-families-challenge-special-issue/), with adaptations to allow for the complexity of the project.

The code (in the `code/` subdirectory) proceeds in three major steps, each with multiple scripts in the following separate subdirectories:

1) (`data_processing/`) preprocessing using variable metadata to classify variables as categorical or continuous
2) (`imputation/`) imputing **seven** intermediate data sets using a variety of missing data imputation strategies
3) (`models/` and `runs`/) running regularized regression models on the various imputed data sets, subsetting variables in various manners and incorporating or not incorporating score information (`tuning/` and `utils/` contain helper scripts and functions related to fitting models)

Empty text files ensure that the directory structure is preserved on GitHub for some of the intermediate files that are produced. We have opted to break out some imputation and run files into individual scripts, even at the cost of duplication, for the sake of clarity and robustness.

# Running the code

The data processing, imputation, and model code was run on a Dell PowerEdge M620 Blade server with 16 2.00GHz Intel Xeon CPUs and 192GB of RAM, running Windows Server 2012 R2 (64-bit) Enterprise Edition ([link](https://csde.washington.edu/computing/resources/#Sim_Details)). On that server, it takes approximately **one or two days** to run. Code for producing figures and tables was run separately, on a laptop.

The code to produce 25 sets of predictions from the original data may be run as follows from the **root directory of the project** (all file paths are relative to this) in a bash terminal:

```
$ bash ./code/run_all.sh
```

Or, preferably:

```
$ nohup bash ./code/run_all.sh &
```

This latter will run the code as a background process, even if you disconnect from the server. On a Windows machine, you can access a bash terminal through a recent version of RStudio.

## Packages and dependencies

The results in this paper were created with software written in R 3.4.3 (R Core Team, 2017) using the following packages: glmnet 2.0.13 (Friedman, Hastie, and Tibshirani, 2010), Amelia 1.7.4 (Honaker, King, and Blackwell, 2011), caret 6.0.78 (Kuhn, 2017), polywog 0.4.0 (Kenkel and Signorino, 2014), Matrix 1.2.12 (Bates and Maechler, 2017), doParallel 1.0.11 (Microsoft Corporation and Weston, 2017), parallel 3.4.3 (R Core Team, 2017), dplyr 0.7.4 (Wickham, Francois, Henry, and Müller, 2017), forcats 0.3.0 (Wickham, 2018), haven 1.1.0 (Wickham and Miller, 2017), abelled 1.0.1 (Larmarange, 2017), purrr 0.2.4 (Henry and Wickham, 2017), readr 1.1.1 (Wickham, Hester, and Francois, 2017), stringr 1.3.0 (Wickham, 2018), tidyr 0.8.0 (Wickham and Henry, 2018), devtools 1.13.5 (Wickham, Hester, and Chang, 2018), rmarkdown 1.9 (Allaire et al, 2018), rprojroot 1.3-2 (Müller, 2018), ggplot2 2.2.1 (Wickham, 2009), plyr 1.8.4 (Wickham, 2011), and data.table 1.10.4-3 (Dowle and Srinivasan, 2017). Dependencies are listed in `code/requirements_r.txt`.

One package dependency, `FFCRegressionImputation`, is not on CRAN and must be installed from GitHub using `devtools::install_github("annafil/FFCRegressionImputation")`. `run_all.sh` will do this automatically for you. This package was developed by a coauthor of this project, Anna Filippova, and the package options are documented on the [GitHub page](https://github.com/annafil/FFCRegressionImputation).

## Setup and data

Three data files from the Fragile Families Challenge---`background.csv`, `background.dta`, and `train.csv`---must be placed in the `data/` subdirectory.

In addition, the `data/` subdirectory contains a file, `variables/ffvars_scored.csv`, with descriptive variable ideas manually mapped to FFC variable names, and those variables' scores according to surveyed experts and MTurkers. Further details of this file's generation are described in the paper.
.
## Data processing

An rmarkdown vignette, `variable_metadata.Rmd`, uses a series of helper functions to classify variables as categorical or continuous, makes some manual corrections, then writes those variables to separate text files (stored in `data/variables/`), one per line, for use later in the pipeline. The vignette discusses some of the complications of this process.

Please note that haven 1.1.1 has a bug that renders it unusable for this data processing step; you must use haven 1.1.0.

## Imputation

The imputation scripts create intermediate data sets that drop some variables and impute missing values for the rest.

Two data sets are multiply imputed (m = 5) using the Amelia package. Amelia bootstraps values from a multivariate normal distribution, and computation time increases very nonlinearly with increasing number of variables. Even with only 200-300 variables out of 10000, this is much slower than any of the other data-processing, imputation, or model-fitting code in this project. On a powerful server, with the individual data sets running on 5 parallel processes, **this takes at least 8 hours, if not longer** for each of the two scripts---one running on the subset of *scored* variables, and the other running on the subset of *constructed* variables. We do not attempt to impute the full data set using Amelia.

The other five data sets (mean/mode, lasso, lasso-constructed subset, OLS, and OLS-untyped) are singly imputed using Anna Filippova's `FFCRegressionImputation` package. These take roughly an hour each, and mostly run on the entire data set except as noted.

## Model runs

From the variable scores, the training data, the categorical/continuous classification, and the imputed background data, regularized regression using the glmnet package generates sets of predicted outcomes, saved as the `output/predictions/*/prediction.csv`.

The prediction subdirectories are named schematically as follows:

{model + imputation + variables + [scores]}

- model is always *glmnet*
- imputation is one of *lasso*, *lm*, *lmuntyped*, *mean*, or *mi*.
- variables is one of *all*, *constructed*, or *h* (for 'human', the subset of variables included in the wikisurveys)
- scores is *experts*, *mturkers*, or nothing

A total of 25 combinations (not all possibilities, because some are uninformative or computationally too difficult) are produced.

Model runs on subsets of covariates are relatively fast, running in anywhere from a few minutes to half an hour. Model runs on the full set of covariates are slower, and can take from an hour to several hours. Because model runs on the full set of covariates are slower, and because the covariates in these cases do not vary between outcomes, the matrices of covariates are cached for use across outcomes, which speeds up computation.

The alpha parameter for glmnet is only *approximately* tuned using a grid search in `code/tuning/tune_alpha.R`, and the resulting alpha values are hard-coded into the main run scripts. Because changing alpha does not have a large impact on cross-validated MSE values, we do not optimize alpha for each different type of model run.

**Expected warnings:** The original code submissions for the Fragile Families Challenge required a narrative.txt file to go with each zipped submission. Our code issues a warning if a narrative.txt file is absent, but we have moved to project-level documentation instead, and removed all existing narrative.txt files.

## Figures and tables

**This code is not part of the main sequence in `run_all.sh`.** The actual values of the outcomes for the holdout set are held by the administrators of the Fragile Families Challenge. This code runs on the out-of-sample MSE values that they have provided us, which are included in `data/scores/holdout_results.csv`.

# Acknowledgments

Funding for the Fragile Families and Child Wellbeing Study was provided by the Eunice Kennedy Shriver National Institute of Child Health and Human Development through grants R01HD36916, R01HD39135, and R01HD40421 and by a consortium of private foundations, including the Robert Wood Johnson Foundation. Funding for the Fragile Families Challenge was provided by the Russell Sage Foundation. Support for the computational resources for this research came from a Eunice Kennedy Shriver National Institute of Child Health and Human Development research infrastructure grant, P2C HD042828, to the Center for Studies in Demography & Ecology at the University of Washington.
