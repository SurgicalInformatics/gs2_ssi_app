load('gs2_ssi.rda')

save(shinydata, file = 'shinydata.rda')

names(allvars_grouped)[2] = "Patient characteristics"
names(allvars_grouped)[3] = "Operative characteristics"



save(allvars_grouped, file = 'allvars_grouped.rda')