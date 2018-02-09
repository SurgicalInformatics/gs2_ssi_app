# https://argonaut.is.ed.ac.uk/shiny/rots/gs2_ssi/
library(shiny)
library(shinythemes)

load('allvars_grouped.rda')

# removing the option ALL for the outcome variable - this has no levels
allvars_grouped_outcome = allvars_grouped
allvars_grouped_outcome$General = allvars_grouped_outcome$General[-1]


palettes = list(
  'Qualitative' = rev(c('Accent', 'Dark2', 'Dark1','Paired', 'Pastel1', 'Pastel2', 'Set1', 'Set2', 'Set3')),
  'Sequential'  = rev(c('Blues', 'BuGn', 'BuPu', 'GnBu', 'Greens', 'Greys', 'Oranges'
                        , 'OrRd', 'PuBu', 'PuBuGn', 'PuRd', 'Purples', 'RdPu', 'Reds', 'YlGn', 'YlGnBu', 'YlOrBr', 'YlOrRd')),
  'Diverging'   = rev(c('BrBG', 'PiYG', 'PRGn', 'PuOr', 'RdBu', 'RdGy', 'RdYlBu', 'RdYlGn', 'Spectral'))
)

shinyUI(fluidPage(
  theme = shinytheme("yeti"),
  #shinythemes::themeSelector(),
  titlePanel("GlobalSurg 2 dataset explorer"),
  
  fluidRow(
    
    column(4, # A - input panel
           wellPanel( # begin_A1
             h3('Main input parameters:'),
             # A1.1 - explanatory, split, outcome
             selectInput("explanatory1",
                         label    = "Explanatory variable:",
                         selected = c("hdi_tertile"),
                         choices  = allvars_grouped,
                         multiple = FALSE),
             selectInput("explanatory2",
                         label    = "Split by:",
                         selected = c("ALL"),
                         choices  = allvars_grouped,
                         multiple = FALSE),
             selectInput("outcome",
                         label    = "Outcome variable:",
                         selected = c("ssi_yn.collapsed"),
                         choices  = allvars_grouped_outcome,
                         multiple = FALSE),
             checkboxInput("axis_relative",
                           label = "Relative to total (x-axis to %)",
                           value = FALSE)
           ),
           wellPanel(
             h3('Advanced parameters:'),
             fluidRow(
               column(3,
                      h5('Reverse order:')),
               column(3,
                      checkboxInput("rev_expl1",   "Explanat.",   TRUE) ),
               column(2,
                      checkboxInput("rev_expl2",   "Split",   FALSE) ),
               column(4,
                      checkboxInput("rev_outcome", "Outcome", FALSE) )
             ),
           fluidRow( # A1.4 - shift outcome levels
             # the percentage label is only plotted for the first factor level (otherwise would start overlapping)
             # this "shifter" is useful if you want another level to be the first one on the barplot
             # this complements the Reverse order options.
             sliderInput("fct_shift", "Shift outcome levels:",
                         min = 0, max = 6, value = 0, step=1,
                         ticks=TRUE),
             fluidRow(
               column(3,
                      h5('Remove from outcome:')),
               column(3,
                      checkboxInput("rem_unkwn",   "Unknown",   FALSE) ),
               column(3,
                      checkboxInput("rem_mis",   "Missing",   FALSE) )
             )
           )
    ), #end_A1
    wellPanel( # begin_A2
      sliderInput("width", "Plot Width (%)", min = 20, max = 100, value = 80, step=10),
      sliderInput("height", "Plot Height (px)", min = 100, max = 1000, value = 400, step=50)
    ), # end_A2
    # begin_A3
    column(6, #begin_A3.1
           wellPanel(
             checkboxGroupInput("subset1",
                                label     = ("Subsetting: included countries"),
                                #note the spaces after the names (e.g. 'Ideal ')
                                #that's because in this syntax, Shiny expects names and values to be different
                                #which would be useful if you data for, e.g. 1,2,3,4,5 instead of names
                                #without the spaces you get:
                                #ERROR: 'selected' must be the values instead of names of 'choices' for the input 'subset1'
                                choices   = list('High HDI '       = 'High',
                                                 'Middle HDI '     = 'Middle',
                                                 'Low HDI '        = 'Low')
                                ,selected = c('High', 'Middle', 'Low'))

           )
    ), #end_A3.1
    column(6, # begin_A3.2
           wellPanel(
             selectInput("my_palette",
                         label = "Colour palette:",
                         selected = c("Paired"),
                         choices  = palettes,
                         multiple = FALSE),
             checkboxInput("reverse_colours", "Reverse colours", FALSE),
             radioButtons('legend_columns', 'Legend columns',
                          choices  = c(1:3),
                          selected = 2,
                          inline   = TRUE),
             checkboxInput("perc_label", "% label:", TRUE),
             radioButtons('black_white', label=NULL,
                          choices = list(
                            'Black' = 'black',
                            'White' = 'white'
                          ),
                          selected = 'white',
                          inline=TRUE)
           )
           
    ) # end_A3.2
    
  ), #end_A
  
  
  
  column(8, 
         tabsetPanel(type = "tabs", 
                     tabPanel("Data", uiOutput("plot.ui"),
                              p('Table'),
                              tableOutput('table')), 
                     #tabPanel('Colour palettes', img(src='brewer-pal.png', align = "left")),
                     tabPanel("Study summary", includeMarkdown("lay_summary.md")),
                     tabPanel('Info', h4( a("http://globalsurg.org/", href="http://globalsurg.org/")),
                              h4( a("https://github.com/riinuots/gs2_ssi_app", href="https://github.com/riinuots/gs2_ssi_app")))
         )
  )
  
)

))
