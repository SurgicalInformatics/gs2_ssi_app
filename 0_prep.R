load('gs2_ssi.rda')

library(ggplot2)
library(dplyr)
library(tidyr)
library(broom)
library(forcats)
library(magrittr)
library(scales)
library(readr)
theme_set(theme_bw())


shinydata$los.quantiles %<>% 
  fct_recode("<1 day"   = "[0,1]",
             "2-3 days" = "(1,3]",
             "4-7 days" = "(3,7]",
             ">7 days" = "(7,180]"
             )

shinydata$time2op.hours.factor %<>%
  fct_recode("<6 h"    = "<6",
             "6-11 h"  = "6-11",
             "12-23 h" = "12-23",
             "24-47 h" = "24-47",
             "48+ h"   =  "48+")


save(shinydata, file = 'shinydata.rda')

names(allvars_grouped)[2] = "Patient characteristics"
names(allvars_grouped)[3] = "Operative characteristics"
names(allvars_grouped$`Operative characteristics`)[1] = "Procedure start-time" #typo


save(allvars_grouped, file = 'allvars_grouped.rda')


