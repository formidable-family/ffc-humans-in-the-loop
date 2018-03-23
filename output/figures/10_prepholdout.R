rm(list=ls()) 

#setwd
homedir<-file.path(
  "c:",
  "users",
  "adaner",
  "dropbox",
  "_learning",
  "sicss",
  "ffc_plots"
)

datadir<-file.path(
  homedir,
  "data"
)
outputdir<-file.path(
  homedir,
  "output"
)

#packages
require(stringr)
require(plyr)
require(dplyr)
require(tidyr)
require(data.table)

###########################################
###########################################

#load new holdout scores
setwd(datadir)
hodf<-read.csv(
  'ffc_mses_holdout_032018.csv',
  stringsAsFactors=F
)
head(hodf); tail(hodf)

#simplify filename
hodf$filename<-str_replace(
  hodf$filename,
  "glmnet\\_",
  ""
) %>% str_replace(
  "/prediction\\.csv",
  ""
)

#we need to classify the predicitons
#priorsXsubsetXmissingness

#priors
hodf$priors<-str_extract(
  hodf$filename,
  "experts|mturkers"
)
hodf$priors[is.na(hodf$priors)]<-"none"

#subset
hodf$subset<-str_extract(
  hodf$filename,
  "all|h|constructed"
)
is.na(hodf$subset) #nothing to fill in

#missingness
hodf$missing<-str_extract(
  hodf$filename,
  "mean|mi|lm(untyped)?|lasso"
) 
is.na(hodf$missing) #nothing

#standardize modelname
hodf$modname<-paste0(
  hodf$missing,"_",
  hodf$subset,"_",
  hodf$priors
)
hodf$filename<-NULL

#quick survey of the possible model space
#i.e., these are all the possible permutations
#vs. these are the permutations we explored
permdf<-expand.grid(
  missing=unique(hodf$missing),
  subset=unique(hodf$subset),
  priors=unique(hodf$priors),
  stringsAsFactors=F
)
permdf$modname<-paste0(
  permdf$missing,"_",
  permdf$subset,"_",
  permdf$priors
)
sum(!hodf$modname%in%permdf$modname) # should be 0

#we can use this to make a graph of model space
tmp<-permdf$modname%in%hodf$modname
permdf$prez<-tmp

###########################################
###########################################

#get baseline scores
#and get relative mse's
#and standardized relative mse's

#reshape before merge
hodf <- gather(
  hodf,
  outcome,
  mse,
  eviction:materialHardship
)

#load the baseline scores
setwd(datadir); dir()
tmpdf<-read.csv(
  'ffc_baselinescores.csv',
  stringsAsFactors=F
)
tmpdf<-
  tmpdf[tmpdf$evaldata=="holdout",]
tmpdf$evaldata<-NULL

tmpdf<-gather(
  tmpdf,
  outcome,
  baseline,
  gpa:jobTraining
)

intersect(
  names(hodf),
  names(tmpdf)
)

fulldf<-merge(
  hodf,
  tmpdf,
  all=T
)

fulldf$relmse <- fulldf$mse - fulldf$baseline
fulldf$relmse_pct <- 100 * (fulldf$mse - fulldf$baseline)/fulldf$baseline

#some outcomes were easier to fit
tapply(
  fulldf$mse,
  fulldf$outcome,
  mean
)

#moreover, for some outcomes, 
#it was easier to beat baseline
#than for others
tapply(
  fulldf$relmse,
  fulldf$outcome,
  mean
)

#for this reason, standardized mse's 
#are best thing to plot
fulldf<-by(fulldf,fulldf$outcome,function(df) {
  #df<-fulldf[fulldf$outcome=="gpa",]
  df$relmse_scaled<-scale(df$relmse)[,1]
  df
}) %>% rbind.fill

###########################################
###########################################

#RANK WITHIN OUTCOME

fulldf<-by(fulldf,fulldf$outcome,function(df) {
  #df<-fulldf[fulldf$outcome=="grit",]
  df<-df[order(df$mse),]
  df$rank<-1:nrow(df)
  df
}) %>% rbind.fill

###########################################
###########################################

setwd(datadir); dir()
save.image(
  "10_prepped.RData"
)

