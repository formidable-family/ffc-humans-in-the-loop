rm(list=ls()) 

#setwd
homedir<-file.path(
  rprojroot::find_root("ffc-humans-in-the-loop.Rproj"), 
  "output", 
  "figures"
)

metadir<-homedir

datadir<-file.path(
  rprojroot::find_root("ffc-humans-in-the-loop.Rproj"),
  "data", 
  "scores"
)

outputdir<-homedir

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

#plotting prelims
require(ggplot2)
require(ggthemes)
# require(extrafont)
require(RColorBrewer)
require(scales)
#load fonts
# loadfonts(quiet=T) #register w/ pdf
# loadfonts(device = "win",quiet=T) #register w/ windows
#fonts()
# #get ghostscript, for tex output
# gsdir<-file.path(
#   "c:",
#   "Program Files",
#   "gs"
# )
# gsdir_full<-file.path(
#   gsdir,
#   dir(gsdir),
#   "bin",
#   "gswin64c.exe"
# )
# Sys.setenv(
#   R_GSCMD = gsdir_full
# )
#initialize graphlist
gs.list<-list()
cplotdfs<-list() #to store comparisons

#########################################################
#########################################################

#COMPUTE COMMON SPACE,
#for comparisons

#how many models?
permdf$modname[permdf$prez] %>% unique %>% length

#this returns the modnames of the prediction runs
#that can be fairly compared when we are 
#looking at either which imputation, which subset, which prior
comparisons<-c(
  'missing',
  'subset',
  'priors',
  'rankings'
)
othdim<-list(
  missing=c('subset','priors'),
  subset=c('missing','priors'),
  priors=c('subset','missing'),
  rankings=c('missing')
)

tmpseq.i<-seq_along(comparisons)
restrictions.list<-lapply(tmpseq.i,function(i) {
  #i<-2
  print(i)
  tmpdf<-permdf[permdf$prez,]
  thiscomp<-comparisons[i]
  if(thiscomp=="rankings") {
    tmpdf$rankings<-paste0(
      tmpdf$subset,
      tmpdf$priors
    )
  }
  othcomp<-othdim[[thiscomp]]
  if(length(othcomp)==2) {
    tmpdf$looper<-paste0(
      tmpdf[[othcomp[1]]],
      tmpdf[[othcomp[2]]]
    )
  } else {
    tmpdf$looper<-tmpdf[[othcomp]]
  }
  tmpselector<-tapply(
    tmpdf[[thiscomp]],
    tmpdf$looper,
    function(x) {
      #x<-tmpdf[[thiscomp]][tmpdf$looper=="mimturkers"]
      sum(unique(tmpdf[[thiscomp]])%in%x)==length(unique(tmpdf[[thiscomp]]))
    }
  )
  tmpdf$modname[tmpdf$looper%in%names(which(tmpselector))]
})
names(restrictions.list)<-comparisons

#########################################################
#########################################################

#PLOT 1 - MODEL SPACE

plotdf<-permdf

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
plotdf$subset<-factor(
  plotdf$subset,
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
plotdf$priors<-factor(
  plotdf$priors,
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
plotdf$missing<-factor(
  plotdf$missing,
  rev(tmplevels),
  rev(tmplabels)
)

tmplevels<-c(
  T,F
)
tmplabels<-c(
  "Explored",
  "Not Explored"
)
plotdf$prez<-factor(
  plotdf$prez,
  tmplevels,
  tmplabels
)

prezcolors<-c("#f0f0f0","#636363")
names(prezcolors)<-levels(plotdf$prez)

g.tmp<-ggplot(
  plotdf,
  aes(
    x=subset,
    y=missing,
    fill=prez
  )
) + 
  geom_tile() +
  scale_fill_manual(
    name="",
    values=prezcolors
  ) +
  facet_wrap(
    ~ priors
  ) + 
  xlab("") +
  ylab("") +
  theme_bw(
    #base_family="CM Roman",
    base_size=14
  ) +
  theme(
    legend.position='top',
    legend.direction='horizontal'
  )
g.tmp
tmpname<-"fig_permutations.png"
gs.list[[tmpname]]<-list(
  graph=g.tmp,
  filename=tmpname,
  width=12,
  height=6
)

#########################################################
#########################################################

#PLOT 2 - PERMUTATIONS W/ THE RELEVANT COMPARISONS HIGHLIGHTED

tmpseq.i<-seq_along(names(restrictions.list))
plotdf<-lapply(tmpseq.i,function(i) {
  tmpdf<-permdf
  tmpdf$incomparison<-tmpdf$modname%in%restrictions.list[[i]]
  tmpdf$comparison<-names(restrictions.list)[i]
  tmpdf
}) %>% rbind.fill

plotdf$fillme<-NA
plotdf$fillme[!plotdf$prez & !plotdf$incomparison]<-1
plotdf$fillme[plotdf$prez & !plotdf$incomparison]<-2
plotdf$fillme[plotdf$prez & plotdf$incomparison]<-3

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
plotdf$subset<-factor(
  plotdf$subset,
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
plotdf$priors<-factor(
  plotdf$priors,
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
plotdf$missing<-factor(
  plotdf$missing,
  rev(tmplevels),
  rev(tmplabels)
)

tmplevels<-c(
  "missing",
  "subset",
  "priors",
  "rankings"
)
tmplabels<-c(
  "Imputation",
  "Subsetting",
  "Scoring",
  "Humans in the Loop?"
)

plotdf$comparison<-factor(
  plotdf$comparison,
  tmplevels,
  tmplabels
)

tmplevels<-c(
  1,2,3
)
tmplabels<-c(
  "Never Explored",
  "Explored, Not In Comparison",
  "Explored, In Comparison"
)
plotdf$fillme<-factor(
  plotdf$fillme,
  tmplevels,
  tmplabels
)

fillmecolors<-c("#636363","#f0f0f0",'#CE1620')
names(fillmecolors)<-levels(plotdf$fillme)

g.tmp<-ggplot(
  plotdf,
  aes(
    x=subset,
    y=missing,
    fill=fillme
  )
) + 
  geom_tile() +
  scale_fill_manual(
    name="",
    values=fillmecolors
  ) +
  facet_grid(
    comparison ~ priors
  ) + 
  xlab("") +
  ylab("") +
  theme_bw(
    #base_family="CM Roman",
    base_size=14
  ) +
  theme(
    legend.position='top',
    legend.direction='horizontal'
  )
g.tmp
tmpname<-"fig_permutations_full.png"
gs.list[[tmpname]]<-list(
  graph=g.tmp,
  filename=tmpname,
  width=10*1.25,
  height=7*1.25
)

#########################################################
#########################################################

#PLOT 1 - RAW SCORES

#we are most interested in rankings
#that are comparable across subsetXprior combinations
#b/c we didn't use all imputation techniques for each, 
#it makes sense to restrict

#below I plot a restricted and unrestricted version
tmp<-fulldf$modname%in%restrictions.list$rankings
tmpdf<-fulldf
tmpdf$restricted<-tmp

tmpdf$ssXprior<-paste0(
  tmpdf$subset," + ",
  tmpdf$priors
)
unique(tmpdf$ssXprior)
tmplevels<-c(
  "all + none",
  "all + experts",
  "all + mturkers",
  "h + none",
  "h + experts",
  "h + mturkers",
  "constructed + none"
)
tmplabels<-c(
  "No Subsetting + No Scores",
  "No Subsetting + Expert Scores",
  "No Subsetting + MTurker Scores",
  "Wikisurveyed + No Scores",
  "Wikisurveyed + Expert Scores",
  "Wikisurveyed + MTurker Scores",
  "Constructed + No Scores"
)
tmpdf$ssXprior<-factor(
  tmpdf$ssXprior,
  tmplevels,
  tmplabels
)

unique(tmpdf$missing)
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
  tmplevels,
  tmplabels
)

tmplevels<-c(
  "eviction",
  "gpa",
  "grit",
  "jobTraining",
  "layoff",
  "materialHardship"
)
tmplabels<-c(
  "Eviction",
  "GPA",
  "Grit",
  "Job Training",
  "Layoff",
  "Material Hardship"
)
tmpdf$outcome<-factor(
  tmpdf$outcome,
  tmplevels,
  tmplabels
)


#unrestricted
plotdf<-tmpdf
g.tmp<-ggplot(
  plotdf,
  aes(
    x=ssXprior,
    y=mse,
    color=missing
  )
) +
  geom_point() +
  coord_flip() +
  facet_wrap(
    ~ outcome,
    scales='free_x'
  ) +
  scale_color_discrete(name="") + 
  xlab("") + 
  ylab("") +
  theme_bw(
    #base_family="CM Roman",
    base_size=14
  ) 

tmpname<-"fig_rawscores_unrestricted.png"
gs.list[[tmpname]]<-list(
  graph=g.tmp,
  filename=tmpname,
  width=10 * 1.5,
  height=4 * 1.5
)

#restricted
plotdf<-tmpdf[tmpdf$restricted,]
g.tmp<-ggplot(
  plotdf,
  aes(
    x=ssXprior,
    y=mse
  )
) +
  geom_point() +
  coord_flip() +
  facet_wrap(
    ~ outcome,
    scales='free_x'
  ) +
  xlab("") + 
  ylab("")  +
  theme_bw(
    #base_family="CM Roman",
    base_size=14
  ) 

tmpname<-"fig_rawscores.png"
gs.list[[tmpname]]<-list(
  graph=g.tmp,
  filename=tmpname,
  width=10,
  height=4
)

#########################################################
#########################################################

#QUESTION 1 - WHAT IS THE BEST STRATEGY? 

#to do this, compare RMSES's across subsetXprior strategies

#b/c we don't fill the permutation space w/ our runs
#we restrict to imputation strategies and subsets
#that are present for each scores strategy
head(fulldf)
tmp<-fulldf$modname%in%restrictions.list$rankings
tmpdf<-fulldf[tmp,]
nrow(tmpdf) 

#generate new rankings, w/in this space
tmpdf<-by(tmpdf,tmpdf$outcome,function(df) {
  #df<-df[order(df$mse),]
  df$rank<-1:nrow(df)
  df
}) %>% rbind.fill

#now we can compare
tmplist<-list(tmpdf$subset,tmpdf$priors)
tapply(
  tmpdf$relmse_scaled,
  tmplist,
  mean
)
#this suggests: no priors and no Subsetting is best

#when we compare across all these 
tapply(
  tmpdf$rank,
  tmplist,
  mean
)
#by this metric also, no priors and no Subsetting is best
#although it is tied w/ experts and no Subsetting

tapply(
  tmpdf$mse,
  tmplist,
  mean
)
#by this metric, no priors and no Subsetting is best

#plot it
plotdf<-by(tmpdf,tmplist,function(df) {
  data.frame(
    subset=unique(df$subset),
    priors=unique(df$priors),
    mse=mean(df$mse),
    mse_median=median(df$mse),
    relmse=mean(df$relmse),
    rank=mean(df$rank),
    relmse_pct=mean(df$relmse_pct),
    relmse_scaled=mean(df$relmse_scaled),
    stringsAsFactors=F
  )
}) %>% rbind.fill
plotdf<-gather(
  plotdf,
  var,
  val,
  mse:relmse_scaled
)
roworder<-order(plotdf$var)
plotdf<-plotdf[roworder,]
plotdf$ranking<-
  tapply(plotdf$val,plotdf$var,rank) %>%
  unlist
plotdf$ranking<-floor(plotdf$ranking)
plotdf$ranking<-factor(plotdf$ranking)
tmpcolors1<-brewer.pal(length(levels(plotdf$ranking)),"GnBu")
names(tmpcolors1)<-rev(levels(plotdf$ranking))
cplotdfs[['rankings']]<-plotdf

tmplevels<-c(
  "mse",
  "mse_median",
  "relmse",
  "rank",
  "relmse_scaled",
  "relmse_pct"
)
tmplabels<-c(
  "Avg. MSE",
  "Median MSE",
  "Rel. MSE-Based",
  "Rank-Based",
  "Rel. Std. MSE-Based",
  "% Impr. Rel. Baseline"
)
plotdf$var<-factor(
  plotdf$var,
  tmplevels,
  tmplabels
)
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
plotdf$subset<-factor(
  plotdf$subset,
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
plotdf$priors<-factor(
  plotdf$priors,
  tmplevels,
  tmplabels
)

g.tmp<-ggplot(
  plotdf,
  aes(
    x=priors,
    y=subset,
    fill=ranking,
    label=ranking
  )
) + 
  geom_tile() +
  geom_text() +
  facet_wrap(
    ~ var
  ) +
  scale_fill_manual(
    name="Rank",
    values=tmpcolors1
  ) +
  xlab("\nScores") +
  ylab("Subset\n") +
  theme_bw(
    #base_family="CM Roman",
    base_size=14
  ) 

tmpname<-"fig_rankings.png"
gs.list[[tmpname]]<-list(
  graph=g.tmp,
  filename=tmpname,
  width=10,
  height=4
)


#########################################################
#########################################################

#QUESTION 2 - INTERVENTION AT STAGE 1

#does it make sense to trim to constructed or wikisurvey
#or is it best to keep the whole dataset?

#we can either compare by average rank
#or by average RMSE Std's across strategoes

#we can also compare in an unrestricted sample
#or, we can compare in a restricted sample,
#where we only conduct this comparisons
#in subset of space where common
# scores X missing strategies are used alongside
tmp<-fulldf$modname%in%restrictions.list$subset
tmpdf<-fulldf[tmp,]
tmpdf

#should be 36 cells
nrow(tmpdf) #36

#generate new rankings, w/in this space
tmpdf<-by(tmpdf,tmpdf$outcome,function(df) {
  #df<-df[order(df$mse),]
  df$rank<-1:nrow(df)
  df
}) %>% rbind.fill

stats<-c(
  "mse",
  "relmse",
  "rank",
  "relmse_scaled",
  "relmse_pct"
)
statsdf<-lapply(
  stats,
  function(x) {
    tapply(
      tmpdf[[x]],
      tmpdf$subset,
      mean
    ) %>% t %>%
      data.frame 
  }
) %>% rbind.fill
statsdf$stat<-stats
statsdf

#in short: human intervention at stage 1 is not good idea!

#plot it
plotdf<-by(tmpdf,tmpdf$subset,function(df) {
  data.frame(
    subset=unique(df$subset),
    mse=mean(df$mse),
    mse_median=median(df$mse),
    relmse=mean(df$relmse),
    rank=mean(df$rank),
    relmse_pct=mean(df$relmse_pct),
    relmse_scaled=mean(df$relmse_scaled),
    stringsAsFactors=F
  )
}) %>% rbind.fill
plotdf<-gather(
  plotdf,
  var,
  val,
  mse:relmse_scaled
)
roworder<-order(plotdf$var)
plotdf<-plotdf[roworder,]
plotdf$ranking<-
  tapply(plotdf$val,plotdf$var,rank) %>%
  unlist
plotdf$ranking<-floor(plotdf$ranking)
plotdf$ranking<-factor(plotdf$ranking)
tmpcolors2<-brewer.pal(length(levels(plotdf$ranking)),"GnBu")
names(tmpcolors2)<-rev(levels(plotdf$ranking))
cplotdfs[['subset']]<-plotdf

tmplevels<-c(
  "mse",
  "mse_median",
  "relmse",
  "rank",
  "relmse_scaled",
  "relmse_pct"
)
tmplabels<-c(
  "Avg. MSE",
  "Median MSE",
  "Rel. MSE-Based",
  "Rank-Based",
  "Rel. Std. MSE-Based",
  "% Impr. Rel. Baseline"
)
plotdf$var<-factor(
  plotdf$var,
  tmplevels,
  tmplabels
)

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
plotdf$subset<-factor(
  plotdf$subset,
  tmplevels,
  tmplabels
)

g.tmp<-ggplot(
  plotdf,
  aes(
    x=var,
    y=subset,
    fill=ranking,
    label=ranking
  )
) + 
  geom_tile() +
  geom_text() +
  scale_fill_manual(
    name="Rank",
    values=tmpcolors2
  ) +
  xlab("") +
  ylab("") +
  theme_bw(
    #base_family="CM Roman",
    base_size=14
  ) 

tmpname<-"fig_subset.png"
gs.list[[tmpname]]<-list(
  graph=g.tmp,
  filename=tmpname,
  width=8,
  height=5
)

#########################################################
#########################################################

#QUESTION 2 - EXPERTS VS. MTURKERS VS. NONE?

#we want to know whether incorporating prior knowledge helped

#again, we restrict the cells that we examine
#so that we hold everything else constant 
#when we compare these strategies to each other

# tmp<-fulldf$subset=="h" |
#   (
#     fulldf$subset=="all" & 
#       fulldf$missing%in%c("mean","lm")
#   ) 
tmp<-fulldf$modname%in%restrictions.list$priors
tmpdf<-fulldf[tmp,]
nrow(tmpdf) #should be 126

#generate new rankings, w/in this space
tmpdf<-by(tmpdf,tmpdf$outcome,function(df) {
  #df<-df[order(df$mse),]
  df$rank<-1:nrow(df)
  df
}) %>% rbind.fill

stats<-c(
  "mse",
  "relmse",
  "rank",
  "relmse_scaled",
  "relmse_pct"
)
statsdf<-lapply(
  stats,
  function(x) {
    tapply(
      tmpdf[[x]],
      tmpdf$priors,
      mean
    ) %>% t %>%
      data.frame 
  }
) %>% rbind.fill
statsdf$stat<-stats
statsdf

#in short: human intervention at stage 2 may be good idea
#but note that the difference in rankings is not so sig
#could just be that it doesn't make much difference
#and, when considering overall strategies, 
#benefit was outweighed by damage done at first stage

#plot it
plotdf<-by(tmpdf,tmpdf$priors,function(df) {
  data.frame(
    priors=unique(df$priors),
    mse=mean(df$mse),
    mse_median=median(df$mse),
    relmse=mean(df$relmse),
    rank=mean(df$rank),
    relmse_pct=mean(df$relmse_pct),
    relmse_scaled=mean(df$relmse_scaled),
    stringsAsFactors=F
  )
}) %>% rbind.fill
plotdf<-gather(
  plotdf,
  var,
  val,
  mse:relmse_scaled
)
roworder<-order(plotdf$var)
plotdf<-plotdf[roworder,]
plotdf$ranking<-
  tapply(plotdf$val,plotdf$var,rank) %>%
  unlist
plotdf$ranking<-floor(plotdf$ranking)
plotdf$ranking<-factor(plotdf$ranking)
tmpcolors3<-brewer.pal(length(levels(plotdf$ranking)),"GnBu")
names(tmpcolors3)<-rev(levels(plotdf$ranking))
cplotdfs[['priors']]<-plotdf

tmplevels<-c(
  "mse",
  "mse_median",
  "relmse",
  "rank",
  "relmse_scaled",
  "relmse_pct"
)
tmplabels<-c(
  "Avg. MSE",
  "Median MSE",
  "Rel. MSE-Based",
  "Rank-Based",
  "Rel. Std. MSE-Based",
  "% Impr. Rel. Baseline"
)
plotdf$var<-factor(
  plotdf$var,
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
plotdf$priors<-factor(
  plotdf$priors,
  tmplevels,
  tmplabels
)

g.tmp<-ggplot(
  plotdf,
  aes(
    x=var,
    y=priors,
    fill=ranking,
    label=ranking
  )
) + 
  geom_tile() +
  geom_text() +
  scale_fill_manual(
    name="Rank",
    values=tmpcolors3
  ) +
  xlab("") +
  ylab("") +
  theme_bw(
    #base_family="CM Roman",
    base_size=14
  ) 

tmpname<-"fig_scores.png"
gs.list[[tmpname]]<-list(
  graph=g.tmp,
  filename=tmpname,
  width=8,
  height=5
)


###########################################
###########################################

#QUESTION 3 - WHICH IMPUTATION TECHNIQUE?

#again, restrict to strategies that were tried for all
#this means that we restrict to the 'wikisurveyed' vars

tmp<-fulldf$modname%in%restrictions.list$missing
tmpdf<-fulldf[tmp,]
nrow(tmpdf) #should be 90: 5 * 6 * 3

stats<-c(
  "mse",
  "relmse",
  "rank",
  "relmse_scaled",
  "relmse_pct"
)
statsdf<-lapply(
  stats,
  function(x) {
    tapply(
      tmpdf[[x]],
      tmpdf$missing,
      mean
    ) %>% t %>%
      data.frame 
  }
) %>% rbind.fill
statsdf$stat<-stats
statsdf

#mi is best, but mean and lm are right behind
#this suggests: ideal to do mi, but there
#are computtational issues that prevented us
#plot it
plotdf<-by(tmpdf,tmpdf$missing,function(df) {
  data.frame(
    missing=unique(df$missing),
    mse=mean(df$mse),
    mse_median=median(df$mse),
    relmse=mean(df$relmse),
    rank=mean(df$rank),
    relmse_pct=mean(df$relmse_pct),
    relmse_scaled=mean(df$relmse_scaled),
    stringsAsFactors=F
  )
}) %>% rbind.fill
plotdf<-gather(
  plotdf,
  var,
  val,
  mse:relmse_scaled
)
roworder<-order(plotdf$var)
plotdf<-plotdf[roworder,]
plotdf$ranking<-
  tapply(plotdf$val,plotdf$var,rank) %>%
  unlist
plotdf$ranking<-floor(plotdf$ranking)
plotdf$ranking<-factor(plotdf$ranking)
tmpcolors4<-brewer.pal(length(levels(plotdf$ranking)),"GnBu")
names(tmpcolors4)<-rev(levels(plotdf$ranking))
cplotdfs[['missing']]<-plotdf

tmplevels<-c(
  "mse",
  "mse_median",
  "relmse",
  "rank",
  "relmse_scaled",
  "relmse_pct"
)
tmplabels<-c(
  "Avg. MSE",
  "Median MSE",
  "Rel. MSE-Based",
  "Rank-Based",
  "Rel. Std. MSE-Based",
  "% Impr. Rel. Baseline"
)
plotdf$var<-factor(
  plotdf$var,
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
plotdf$missing<-factor(
  plotdf$missing,
  rev(tmplevels),
  rev(tmplabels)
)

g.tmp<-ggplot(
  plotdf,
  aes(
    x=var,
    y=missing,
    fill=ranking,
    label=ranking
  )
) + 
  geom_tile() +
  geom_text() +
  scale_fill_manual(
    name="Rank",
    values=tmpcolors4
  ) +
  xlab("") +
  ylab("") +
  theme_bw(
    #base_family="CM Roman",
    base_size=14
  ) 

tmpname<-"fig_missing.png"
gs.list[[tmpname]]<-list(
  graph=g.tmp,
  filename=tmpname,
  width=8,
  height=5
)

###########################################
###########################################

#CREATE COMPOSITE GRAPH
#shows rankings for each q
#mse based only

tmpseq.i<-seq_along(cplotdfs)
plotdf<-lapply(tmpseq.i,function(i) {
  #i<-1
  tmpdf<-cplotdfs[[i]]
  tmpname<-names(cplotdfs)[i]
  if(tmpname=="rankings") {
    tmpdf$x<-paste0(
      tmpdf$subset," + ",
      tmpdf$priors
    )
  } else {
    tmpdf$x<-tmpdf[[tmpname]]
  }
  #return
  tmpcols<-c(
    "x",
    "var",
    "val",
    "ranking"
  )
  returndf<-tmpdf[,tmpcols]
  returndf$comparison<-tmpname
  returndf
}) %>% rbind.fill
tmpcolors5<-brewer.pal(length(levels(plotdf$ranking)),"GnBu")
names(tmpcolors5)<-rev(levels(plotdf$ranking))

#order by average rank
rankdf<-plotdf[plotdf$var=="mse",]
tmplevels<-rankdf$x[order(rankdf$ranking)] %>%
  unique
tmplabels<-sapply(
  tmplevels,
  function(x) {
    varsdf$prettyname[varsdf$name==x]
  }
)
plotdf$x<-factor(
  plotdf$x,
  rev(tmplevels),
  rev(tmplabels)
)

tmplevels<-c(
  "missing",
  "subset",
  "priors",
  "rankings"
)
tmplabels<-c(
  "(a) Imputation",
  "(b) Subsetting",
  "(c) Scoring",
  "(d) Humans in the Loop?"
)
plotdf$comparison<-factor(
  plotdf$comparison,
  tmplevels,
  tmplabels
)

tmplevels<-c(
  "mse",
  "mse_median",
  "relmse",
  "rank",
  "relmse_scaled",
  "relmse_pct"
)
tmplabels<-c(
  "Avg. MSE",
  "Median MSE",
  "Rel. MSE-Based",
  "Rank-Based",
  "Rel. Std. MSE-Based",
  "% Impr. Rel. Baseline"
)
plotdf$var<-factor(
  plotdf$var,
  tmplevels,
  tmplabels
)

#trim to key metrics to show rankings
plotdf.tmp<-plotdf[plotdf$var%in%c("Avg. MSE","Median MSE"),]
g.tmp<-ggplot(
  plotdf.tmp,
  aes(
    x=var,
    y=x,
    fill=ranking,
    label=ranking
  )
) +
  geom_tile() +
  geom_text() +
  scale_fill_manual(
    name="Rank",
    values=tmpcolors5
  ) +
  facet_wrap(
    ~ comparison,
    ncol=1,
    scales='free'
  ) +
  xlab("") +
  ylab("") +
  theme_bw(
    #base_family="CM Roman",
    base_size=14
  ) 

tmpname<-"fig_overall.png"
gs.list[[tmpname]]<-list(
  graph=g.tmp,
  filename=tmpname,
  width=6,
  height=11
)

#trim to pct redution to show magnitudes

plotdf.tmp<-plotdf[plotdf$var%in%c("% Impr. Rel. Baseline"),]
plotdf.tmp$val <- -1 * round(plotdf.tmp$val,2)
g.tmp<-ggplot(
  plotdf.tmp,
  aes(
    x=x,
    y=val,
    label=val
  )
) +
  geom_bar(stat='identity') +
  geom_text(
    position=position_nudge(0,0.2)
  ) +
  facet_wrap(
    ~ comparison,
    ncol=1,
    scales='free_y'
  ) +
  xlab("") +
  ylab("\n% MSE Improvement Relative to Baseline") +
  coord_flip() +
  theme_bw(
    #base_family="CM Roman",
    base_size=14
  ) 

tmpname<-"fig_overall_mag.png"
gs.list[[tmpname]]<-list(
  graph=g.tmp,
  filename=tmpname,
  width=12,
  height=10
)

###########################################
###########################################

# #restrict to graphs for paper
# gs.list$fig_rankings.png<-
#   gs.list$fig_scores.png<-
#   gs.list$fig_subset.png<-NULL

#any quantities we want for the paper

###########################################
###########################################

#OUTPUT
#output graphlist
this.sequence<-seq_along(gs.list)
for(i in this.sequence) {
  Sys.sleep(1)
  print(
    paste0(
      "saving ",i," of ",length(this.sequence)
    )
  )
  thiselement<-gs.list[[i]]
  
  ggsave(
    filename=file.path(outputdir, thiselement$filename),
    plot=thiselement$graph,
    width=thiselement$width,
    height=thiselement$height
  )

  
  #for fonts
  # ggsave(
  #   filename="tmp.png",
  #   plot=thiselement$graph,
  #   width=thiselement$width,
  #   height=thiselement$height
  # )
  # #embed font
  # embed_fonts(
  #   file="tmp.png",
  #   outfile=thiselement$filename
  # )
  # file.remove(
  #   "tmp.png"
  # )
}


