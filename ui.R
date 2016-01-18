
# This is the user-interface definition of a Shiny web application.
# You can find out more about building applications with Shiny here:
#
# http://shiny.rstudio.com
#

library(shiny)

plotImage = function(outputId) tagList(plotOutput(outputId, inline=TRUE), p())

shinyUI(fluidPage(

  # Application title
  titlePanel("Segmentation of trees"),

  # Sidebar with a slider input for number of bins
  sidebarLayout(
    sidebarPanel(
      h3("Filtering"),
      checkboxInput("filter", "Gaussian filter", TRUE),
      sliderInput("filtersize",
                  "size",
                  min = 1, max = 5, value = 2, step = 1),
      h3("Adaptive thresholding"),
      sliderInput("w",
                  "width",
                  min = 1, max = 10, value = 3, step = 1),
      sliderInput("h",
                  "height",
                  min = 1, max = 10, value = 4, step = 1),
      numericInput("offset", "offset", 0.0015),
      h3("Morphological opening"),
      sliderInput("osize",
                  "size",
                  min = 1, max = 10, value = 3, step = 1),
      checkboxInput("fillhull", "fill holes", TRUE)
    ),
    
    # Show a plot of the generated distribution
    mainPanel(
      tabsetPanel(
        tabPanel("Input", plotImage("img"), 
                          numericInput("left", "left", -120.39697, step=0.1),
                          numericInput("right", "right", -120.39251, step=0.1),
                          numericInput("bottom", "bottom", 37.30481, step=0.1),
                          numericInput("top", "top", 37.30662), step=0.1),
        tabPanel("Filtered", plotImage("filtered")),
        tabPanel("Thresholded", plotImage("thresholded")),
        tabPanel("Opening", plotImage("opening")),
        tabPanel("Segmentation", plotImage("segmentation"),
                                 h4(textOutput("numberOfTrees"))),
        tabPanel("Overlay", plotImage("overlay"))
      )
    )
  )
))
