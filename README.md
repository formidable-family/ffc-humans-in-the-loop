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

The data processing, imputation, and model code was run on a Dell PowerEdge M620 Blade server with 16 2.00GHz Intel Xeon CPUs and 192GB of RAM, running Windows Server 2012 R2 (64-bit) Enterprise Edition ([link](https://csde.washington.edu/computing/resources/#Sim_Details)). On that server, it takes approximately **one day** to run. Code for producing figures and tables was run separately, on a laptop.

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

Dependencies are listed in `code/requirements_r.txt`.

One package dependency, `FFCRegressionImputation`, is not on CRAN and must be installed from GitHub using `devtools::install_github("annafil/FFCRegressionImputation")`. `run_all.sh` will do this automatically for you. This package was developed by a coauthor of this project, Anna Filippova, and the package options are documented on the [GitHub page](https://github.com/annafil/FFCRegressionImputation).

## Setup and data

Three data files from the Fragile Families Challenge---`background.csv`, `background.dta`, and `train.csv`---must be placed in the `data/` subdirectory.

In addition, the `data/` subdirectory contains a file, `variables/ffvars_scored.csv`, with descriptive variable ideas manually mapped to FFC variable names, and those variables' scores according to surveyed experts and MTurkers.

## Data processing

## Imputation

## Model runs

**Expected warnings:** The original code submissions for the Fragile Families Challenge required a narrative.txt file to go with each zipped submission. Our code issues a warning if a narrative.txt file is absent, but we have moved to project-level documentation instead, and removed all existing narrative.txt files.

## Figures and tables

**This code is not part of the main sequence in `run_all.sh`.** The actual values of the outcomes for the holdout set are held by the administrators of the Fragile Families Challenge. This code runs on the out-of-sample MSE values that they have provided us, which are included in `data/scores/holdout_results.csv`.

# Acknowledgments

Funding for the Fragile Families and Child Wellbeing Study was provided by the Eunice Kennedy Shriver National Institute of Child Health and Human Development through grants R01HD36916, R01HD39135, and R01HD40421 and by a consortium of private foundations, including the Robert Wood Johnson Foundation. Funding for the Fragile Families Challenge was provided by the Russell Sage Foundation. Support for the computational resources for this research came from a Eunice Kennedy Shriver National Institute of Child Health and Human Development research infrastructure grant, P2C HD042828, to the Center for Studies in Demography & Ecology at the University of Washington.
