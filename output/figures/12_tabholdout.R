rm(list=ls()) 

#setwd
homedir<-file.path(
  rprojroot::find_root("ffc-humans-in-the-loop.Rproj"), 
  "output", 
  "figures"
)

datadir<-file.path(
  rprojroot::find_root("ffc-humans-in-the-loop.Rproj"),
  "data", 
  "scores"
)

metadir<- homedir

outputdir<-file.path(
  rprojroot::find_root("ffc-humans-in-the-loop.Rproj"), 
  "output", 
  "tables"
)

#packages
require(stringr)
require(plyr)
require(dplyr)
require(tidyr)
require(data.table)

#load data
load(file.path(homedir, '10_prepped.RData'))

#load for nice names
varsdf<-read.csv(
  file.path(metadir, 'prettynamer.csv'),
  stringsAsFactors=F
)

#########################################################
#########################################################

#this generates a Latex table 
#which shows our holdout scores, organized

require(xtable)
tmpcols<-c(
  'outcome',
  'missing',
  'subset',
  'priors',
  'mse'
)
tmpdf<-fulldf[,tmpcols]
tmpdf<-spread(
  tmpdf,
  outcome,
  mse
)

#harmonize names w/ figs
tmplevels<-c(
  "all",
  "h",
  "constructed"
)
tmplabels<-c(
  "No Subsetting",
  "Wikisurveyed",
  "Constructed"
)
tmpdf$subset<-factor(
  tmpdf$subset,
  tmplevels,
  tmplabels
)

tmplevels<-c(
  "experts",
  "mturkers",
  "none"
)
tmplabels<-c(
  "Experts",
  "MTurkers",
  "No Scores"
)
tmpdf$priors<-factor(
  tmpdf$priors,
  tmplevels,
  tmplabels
)

tmplevels<-c(
  "mean",
  "lm",
  "lmuntyped",
  "lasso",
  "mi"
)
tmplabels<-c(
  "Mean",
  "LM",
  "LM-Untyped",
  "LASSO",
  "MI"
)
tmpdf$missing<-factor(
  tmpdf$missing,
  rev(tmplevels),
  rev(tmplabels)
)
names(tmpdf)

roworder<-order(
  tmpdf$missing,
  tmpdf$subset,
  tmpdf$priors
)
tmpdf<-tmpdf[roworder,]

#harmonize names w/ figs
names(tmpdf)<-c(
  "Imputation",
  "Subsetting",
  "Scores",
  "Eviction",
  "GPA",
  "Grit",
  "Job Training",
  "Layoff",
  "Material Hardship"
)

tmptab<-xtable(
  tmpdf,
  digits=5,
  caption="Holdout Scores",
  label="tab_holdout",
  align=c('l','l','l','l','r','r','r','r','r','r')
)

#print table
print(
  tmptab,
  file=file.path(outputdir, "tab_holdout.tex"),
  ##preset commands, same for all
  caption.placement="top",
  booktabs=T,
  include.rownames=F,
  sanitize.text.function=identity
)
output<-readLines(file.path(outputdir, 'tab_holdout.tex'))
thisline<-str_detect(output,"begin\\{(long)?table\\}") %>%
  which %>%
  max 
write(
  c(
    output[1:thisline],
    paste0("\\scriptsize"),
    output[(thisline+1):length(output)]
  ),
  file=file.path(outputdir, "tab_holdout.tex")
)

