#
# World Weather Map
# Author: M. Makkawi
#

library(shiny)
library(leaflet)
library(dplyr)
library(stringr)
library(rdrop2)

# Data Download (from Dropbox)

token <- drop_auth(rdstoken = 'token.rds')

drop_download('/Apps/weather_app_makk/weather_csv/weather.csv', local_path = 'data/weather.csv', overwrite=TRUE)

# Data Processing

city_info <- read.csv("data/weather.csv")

city_info <- city_info %>%
  mutate(conditions = factor(ifelse(Main_Weather=="overcast clouds", "Overcast",
                                    ifelse(Weather == "Drizzle", "Rain", 
                                    ifelse(Weather == "Mist", "Rain",
                                    ifelse(Weather == "Fog", "Haze",
                                    ifelse(Weather == "Smoke", "Overcast", as.character(Weather)))))))) %>%
  mutate(weather_main = stringr::str_to_title(Main_Weather))

# User Interface

ui <- fluidPage(
  div(
    class = "outer",
    tags$head(includeCSS("styles.css")),
    leafletOutput(outputId = "map",width = "100%",height = "100%"),
    absolutePanel(
      id = "controls",
      class = "panel panel-default",
      fixed = TRUE,
      draggable = TRUE,
      top = 45,
      left = "auto",
      right = 30,
      bottom = 'auto',
      width = 300,
      height = "auto",
      h3("World Weather Map"),
      selectInput(
        "weatherConditions",
        "Weather Conditions",
        choices = c("All","Clear", "Rain", "Clouds", "Thunderstorm", "Haze", "Overcast")
      ),
      sliderInput("temps","Temperature Range", as.integer(min(city_info$temp)), as.integer(max(city_info$temp)), value = range(city_info$temp), step = 1)
      )
    )
  )

# Server Logic

server <- function(input, output) {
  output$map <- renderLeaflet({
    
    city_info <- city_info %>%
      filter(
        if (input$weatherConditions == "All") {
          temp >= input$temps[1] & temp <= input$temps[2]
        } else {
          temp >= input$temps[1] & temp <= input$temps[2] & conditions == input$weatherConditions
        }
      )
    
    weatherIcons <- iconList(
      Clear = makeIcon(iconUrl = "img/Clear.png", iconWidth = 20, iconHeight = 20),
      Clouds = makeIcon(iconUrl = "img/Clouds.png", iconWidth = 20, iconHeight = 20),
      Haze = makeIcon(iconUrl = "img/Haze.png", iconWidth = 20, iconHeight = 20),
      Overcast = makeIcon(iconUrl = "img/Overcast.png", iconWidth = 20, iconHeight = 20),
      Rain = makeIcon(iconUrl = "img/Rain.png", iconWidth = 20, iconHeight = 20),
      Thunderstorm = makeIcon(iconUrl = "img/Thunderstorm.png", iconWidth = 20, iconHeight = 20)
    )
    
    leaflet(options = leafletOptions(minZoom = 2)) %>%
    addProviderTiles(providers$Esri.WorldTerrain) %>%
    setView(lat = 30, lng = 30, zoom = 2) %>%
    setMaxBounds(lng1 = -140, lat1 = -70, lng2 = 155, lat2 = 70 ) %>%
    addMarkers(data = city_info,
               lng = ~Longitude, 
               lat = ~Latitude, 
               icon = ~weatherIcons[city_info$conditions], 
               popup = paste("<b>",city_info$City,", ", city_info$Country,"</b>","<br>",
                             "<b>Updated: </b>",city_info$DateTime,"<br>",
                             "<b>Population: </b>",city_info$Population,"<br>",
                             "<b>Weather: </b>",city_info$weather_main,"<br>",
                             "<b>Temperature: </b>",city_info$temp, " C","<br>",
                             "<b>Wind Speed: </b>",city_info$Wind_Speed, " km/h",
                             sep=""))
  })
}

# Run Application

shinyApp(ui = ui, server = server)