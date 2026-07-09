# Packages
suppressPackageStartupMessages({
  library(tidyverse)
  library(ggplot2)
  library(dbplyr)
  library(RPostgres)
  library(DBI)
  library(showtext)
  library(ggtext)
  library(dotenv)
  library(tigris)
  library(sf)
})
message("Project packages loaded :) You rock!")

# Options
options(scipen=999) #prevent scientific notation

# ===================
# Plot Customization
# ===================

# Plot Font
font_add_google(
  "Mulish",
  "Mulish",
  regular.wt = 400,
  bold.wt = 800
)
showtext_auto()
showtext_opts(dpi = 300)

# Plot Colors
misty_blue   <- "#e0f0f2"
deep_slate   <- "#2e3a3f"
stone_gray   <- "#5c6b6f"
pine_green   <- "#00a86b"
glacier_blue <- "#1e90dd"
earth_brown  <- "#997950"
sunrise_gold <- "#daa520"





# Plot Theming
ut_mtn_theme <- theme_set(
  theme_minimal() +
  theme(
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    plot.background = element_rect(
      fill = misty_blue),
    
    plot.title.position = 'plot',
    plot.title = element_markdown(
      family = 'Mulish',
      face = 'bold',
      size = 8,
      hjust = 0,
      margin = margin(0,0,5,0),
      lineheight = 1.2),
    
    plot.subtitle = element_markdown(
      family = 'Mulish',
      size = 5,
      hjust = 0,
      margin = margin(5,0,30,0),
      lineheight = 1.2),
    
    plot.caption = element_markdown(
      family = 'Mulish',
      size = 4,
      hjust = 1,
      margin = margin(10,0,0,0),
      lineheight = 1.2),
    
    axis.title.y = element_markdown(
      family = 'Mulish',
      size = 6,
      hjust = 0.5,
      margin = margin(0,15,0,0),
      lineheight = 1.2),
    
    axis.title.x = element_markdown(
      family = 'Mulish',
      size = 6,
      hjust = 0.5,
      margin = margin(15,0,0,0),
      lineheight = 1.2),
    
    axis.text = element_markdown(
      family = 'Mulish',
      size = 4,
      hjust = 0.5,
      color = stone_gray),
    
    legend.text = element_markdown(
      family = 'Mulish',
      size = 5),
    legend.title = element_markdown(
      size = 5),
    legend.position = "none",
    
    plot.margin = margin(20,20,25,25),
    text = element_text(
      family = 'Mulish',
      color = deep_slate)
    )
  )

# =====================
# How to connect to DB
# =====================
# # Loading environment vars
# readRenviron(".env")
# load_dot_env()
# 
# # Getting DB connection
# con <- dbConnect(
#   RPostgres::Postgres(),
#   dbname = Sys.getenv("DB_NAME"),
#   host = Sys.getenv("localhost"), #R is not containerized and I dont feel like setting it up. lol
#   port = Sys.getenv("DB_PORT"),
#   user = Sys.getenv("DB_USERNAME"),
#   pass = Sys.getenv("DB_PASSWORD")
# )

