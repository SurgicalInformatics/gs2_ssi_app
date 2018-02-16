# https://argonaut.is.ed.ac.uk/shiny/rots/gs2_ssi/
library(ggplot2)
library(dplyr)
library(tidyr)
library(broom)
library(forcats)
library(magrittr)
library(scales)
theme_set(theme_bw())
library(shiny)

load('shinydata.rda')
alldata = shinydata
alldata$ALL = factor('ALL')


load('allvars_grouped.rda')
#reordering the deafult levels of Outcome variables
alldata = alldata %>% 
  mutate_at(as.character(allvars_grouped$Outcomes), fct_rev) # need the as.character as otherwise was using the names()
alldata$mort30.factor %<>% fct_shift(2)
alldata$reintervention_yn.factor %<>% fct_shift(2)


#there's a logical for this in the ui
barplot_type =  'stack' #'fill' or 'stack'


shinyServer(function(input, output, session) {
  
  # subset data --------------------------
  data_subset         <- reactive({     
    #put requested variables in a list
    expl1 = input$explanatory1
    expl2 = input$explanatory2
    outcome = input$outcome
    
    #if testing set input values here
    #expl1 = 'aaa.onepanel'
    #expl2 = 'aaa.onepanel'
    #outcome = 'price.quartiles'
    
    
    
    alldata = alldata %>% 
      filter(hdi_tertile %in% input$subset1)
    
    
    subdata = alldata[, c(expl1, expl2, outcome)]
    colnames(subdata) = c('expl1', 'expl2', 'outcome')
    
    #reverse or shift factor levels -----------

    if (input$rev_expl1){
      subdata$expl1 %<>%   fct_rev()
    }
    if (input$rev_expl2){
      subdata$expl2 %<>%   fct_rev()
    }
    if (input$rev_outcome){
      subdata$outcome %<>%  fct_rev()
    }
    
    subdata$outcome %<>%  fct_shift(input$fct_shift)
    
    
    # remove missing or unknown ------------
    
    if (input$rem_unkwn){
      subdata %<>%   filter(outcome != 'Unknown')
    }
    if (input$rem_mis){
      subdata %<>%   filter(outcome != 'Missing')
    }
    
    # updating plot default heigth on the UI -----
    # (reacts shoulnd't have side-effects but I'll make this one an exception)
    
    number_explanatory   = subdata$expl1   %>% unique() %>% length()
    number_panels        = subdata$expl2   %>% unique() %>% length()
    number_outcomes      = subdata$outcome %>% unique() %>% length()
    

    adjust_heigth = 30 + number_explanatory*50 + number_panels*100 + number_outcomes*10

    #print(paste("Number of levels in explanatory", number_explanatory))
    updateSliderInput(session, "height", value = adjust_heigth)
    
    subdata
    
  })




  
  create_summary = reactive({
    
    subdata = data_subset()
    
    expl1 = input$explanatory1
    expl2 = input$explanatory2
    outcome = input$outcome
    
    
    #count instances
    subdata %>% 
      count(expl1, expl2, outcome) ->
      count_outcomes
    
    #sum instances for totals
    count_outcomes %>% 
      group_by(expl1, expl2) %>% 
      summarise(total = sum(n)) ->
      total_numbers
    
    summary_table = full_join(count_outcomes, total_numbers, by=c('expl1', 'expl2'))
    
    summary_table$relative = 100*summary_table$n/summary_table$total
    
    summary_table %<>% 
      mutate(relative_label = if_else(relative<99,
                                      signif(relative, 2) %>% formatC(digits=2, format='fg'),
                                      signif(relative, 4) %>% formatC(digits=4, format='fg')) %>%
               paste0('%')
      )
    
    
    
    summary_table
    
  })
  
  # create plot
  myplot_p = reactive({
    
    withProgress(message = 'Progress: ', value = 0, {
    incProgress(0.3, detail = "Pulling data")
    #Sys.sleep(0.5) # for testing progress bar
    
    summary_table = create_summary()
    
    incProgress(0.6, detail = "Plotting data")
    #Sys.sleep(0.5) # for testing progress bar
    
    expl1 = input$explanatory1
    expl2 = input$explanatory2
    outcome = input$outcome
    
    
    if (input$axis_relative){
      barplot_type = 'fill' 
    }
    if (input$reverse_colours){
      colour_order = -1
    }else{
      colour_order = 1
    }
    
    #as.numeric as necessary as the input passes on our numbers as characters
    my_ncol = as.numeric(input$legend_columns)
    
    my_breaks = 0:10/10
    
    p = ggplot(summary_table, aes(x=expl1, fill = fct_rev(outcome), y=n))+
      geom_bar(position=barplot_type, stat='identity') +
      facet_wrap(~expl2, ncol=1)+
      coord_flip() +
      theme(
        strip.background = element_rect(fill = "white", colour = "grey50", size = 0.2),
        panel.background = element_rect(fill = "white", colour = NA), 
        panel.border = element_rect(fill=NA, linetype = 'solid', colour = "grey50"),
        #panel.margin = unit(2, "lines"),
        plot.margin = unit(c(2, 2, 2, 2), 'lines'),
        panel.grid.major.x = element_line(colour = "grey90", size = 0.2),
        panel.grid.major.y = element_blank(),
        panel.grid.minor = element_blank(),
        strip.text.x = element_text(size=12),
        axis.text.x = element_text(size=12, vjust=0.7, colour='black'),
        axis.text.y = element_text(size=12, colour='black'),
        axis.title = element_text(size=14),
        #axis.title.y = element_blank(),
        legend.justification=c(1,0),
        legend.position='top',
        legend.title=element_text(size=12),
        legend.text=element_text(size=12)
      )+
      ylab('Patients')+
      scale_fill_brewer(palette=input$my_palette, name = names(outcome), direction=colour_order)+
      guides(fill=guide_legend(ncol=my_ncol, reverse = TRUE)) +
      xlab(names(expl1))
    
    summary_table$outcome = fct_drop(summary_table$outcome)
    first_outcome = levels(summary_table$outcome)[1]
    
    summary_table %>%
      filter(outcome==first_outcome) ->
      first_only
    
    if (input$axis_relative){
      p = p+scale_y_continuous(expand = c(0, 0), label=percent, breaks=my_breaks)
      
    }else{
      p = p+ scale_y_continuous(expand = c(0, 0))
    }
    
    if (input$perc_label){
      p = p+geom_text(data = first_only, aes(label=relative_label), y=0.01, size=7, hjust=0,
                      colour=input$black_white)
    }
    
    
    p
    }) # end withProgress
    
  })
  
  
  # render plot ----------------------------
  
  output$myplot = renderPlot({
    
    p = myplot_p()
    p
    
  })
  
  output$plot.ui <- renderUI({
    plotOutput("myplot", width = paste0(input$width, "%"), height = input$height)
  })
  
  
  
  
  
  # create and render output table -------------------------
  output$table = renderTable({
    
    subdata = data_subset()
    
    expl1 = input$explanatory1
    expl2 = input$explanatory2
    outcome = input$outcome
    
    # subdata = alldata
    # expl1 = 'hdi_tertile'
    # expl2 = 'ALL'
    # outcome = 'ssi_yn.collapsed'
    # subdata = alldata[, c(expl1, expl2, outcome)]
    #colnames(subdata) = c('expl1', 'expl2', 'outcome')
    
    
    subdata %>% 
      count(expl1, expl2, outcome) %>% 
      spread(outcome, 'n', fill=0, convert = TRUE) ->
      summary_table
    
    # adding percentage columns
    number_colnames = colnames(summary_table[, 3:ncol(summary_table) ])
    
    summary_table$total = as.integer(rowSums(summary_table[, number_colnames]))
    
    rel_colnames = paste0(number_colnames, '_%')
    
    summary_table[, rel_colnames] = 100*summary_table[, number_colnames]/summary_table$total
    
    summary_table  = summary_table %>% rename_('Explan.' = 'expl1', 'Split' = 'expl2')
    
    summary_table
    
  })

  
  output$laysummary <- downloadHandler(
    filename = "globalsurg_ssi_lay_summary.pdf",
    content = function(file) {
      file.copy("pdf/globalsurg_ssi_lay_summary.pdf", file)
    }
  )
  
  
  
  
  
})
