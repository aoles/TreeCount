
# This is the server logic for a Shiny web application.
# You can find out more about building applications with Shiny here:
#
# http://shiny.rstudio.com
#

library(shiny)
library(EBImage)
library(ggmap)
library(raster)

set.seed(1)

options(EBImage.display="raster")

renderImage = function(x) renderPlot(display(x), width = isolate(dim(x)[1L]), height = isolate(dim(x)[2L]))

shinyServer(function(input, output) {
  img = reactive({
    # SET ORCHARD BOUNDARY
    orchard_boundary <- c(left=input$left, right=input$right, bottom=input$bottom, top=input$top)
    
    #DOWNLOAD MAP
    map_downloaded <- get_map(location=orchard_boundary, source="google", maptype="hybrid", crop=FALSE, zoom=17)
    
    #PERFORM RASTERIZE OPERATIONS
    map_rgb = col2rgb(as.matrix(map_downloaded))
    map_rasterized = do.call("brick",
                              lapply(1:3, function(channel) raster(matrix(map_rgb[channel,], nrow(map_downloaded), ncol(map_downloaded))))
    )
    
    # SET GEOGRAPHICAL PROJECTION FOR NEW RASTER
    projection(map_rasterized) <- CRS("+init=epsg:3857") # CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
    
    # SET GEOGRAPHICAL EXTENT BOUNDARY FOR NEW RASTER
    extent(map_rasterized) <- unlist(attr(map_downloaded, which = "bb"))[c(2, 4, 1, 3)]
    
    # CROP RASTER (GOOGLE MAP AREA IS LARGER THAN ORCHARD AREA)
    map_crop <- crop(map_rasterized, extent(orchard_boundary))
    
    Image(transpose(as.array(map_crop))/255, colormode = Color)
  })
  
  inv = reactive(if (!is.null(img())) 1 - channel(img(), "gray") else NULL)
  
  output$img <- renderImage(img())
  
  filtered = reactive(if(input$filter) gblur(inv(), input$filtersize) else inv())
  
  output$filtered <- renderImage(filtered())

  thresholded = reactive({
    thresh(filtered(), input$w, input$h, input$offset)
  })
  
  output$thresholded <- renderImage(thresholded())
  
  opened = reactive({
      res = opening(thresholded(), makeBrush(input$osize, shape = "disc"))
      if (input$fillhull) fillHull(res) else res
  })
  
  output$opening <- renderImage(opened())
  
  segmented = reactive(watershed( distmap(opened())) )
  
  output$segmentation <- renderImage(colorLabels(segmented()))
  
  output$numberOfTrees <- renderText(sprintf("Found %d trees", max(segmented())))
  
  output$overlay <- renderImage(paintObjects(segmented(), img(), col = c("yellow", "green"), opac = c(.5, .2)))
})
