# ------------------------------------
# Timp v. Kings Peak Wind/Gusts map
#
# ====================================
# Comparison plot comparing wind speeds/gusts 
# on Kings Peak v. Timpanogos
# ====================================


# ---------------
# Get Data
#----------------
# Loading environment vars
readRenviron(".env")
load_dot_env()

# Getting DB connection
con <- dbConnect(
  RPostgres::Postgres(),
  dbname = Sys.getenv("DB_NAME"),
  host = Sys.getenv("localhost"), #R is not containerized and I dont feel like setting it up. lol
  port = Sys.getenv("DB_PORT"),
  user = Sys.getenv("DB_USERNAME"),
  pass = Sys.getenv("DB_PASSWORD")
)

wind_data <- as.data.frame(dbGetQuery(con,
                        "
  SELECT
        omh.mtn_id,
		    wm.mtn_name,
        omh.hrly_time::time,
        ROUND(AVG(omh.hrly_wind_speed_10m_kmh * 0.621371),2) AS avg_wind_speed,
        ROUND(AVG(omh.hrly_wind_gusts_10m_kmh * 0.621371),2) AS avg_gust_speed,
        ROUND(AVG(omh.hrly_wind_gusts_10m_kmh - omh.hrly_wind_speed_10m_kmh)* 0.621371,2) AS avg_gust_diff,
        ROUND(AVG(omh.hrly_wind_gusts_10m_kmh * 0.621371 / NULLIF(omh.hrly_wind_speed_10m_kmh* 0.621371, 0)), 2) AS avg_gust_factor
  FROM silver.openmeteo_hourly omh
	LEFT JOIN silver.wiki_mtns wm on omh.mtn_id = wm.mtn_id
  WHERE omh.hrly_wind_speed_10m_kmh IS NOT NULL
    AND omh.hrly_wind_gusts_10m_kmh IS NOT NULL
    -- filter out near-zero wind hours where gust factor is noisy/meaningless
    AND omh.hrly_wind_speed_10m_kmh > 2
	  AND omh.mtn_id in (1,52)
	GROUP BY omh.mtn_id, omh.hrly_time::time, wm.mtn_name
	ORDER BY omh.mtn_id asc, omh.hrly_time::time asc;
                        "))

wind_data <- wind_data %>% 
  mutate(hrly_time = hour(hrly_time),
         mtn_name = case_when(
           mtn_name == "Mount Timpanogos" ~ "Mt Timp",
           mtn_name == "Kings Peak" ~ "Kings Peak"
         ))

#-----------------
# Comparison Plot
#-----------------



ggplot()+
  annotate("rect",
           xmin = 5.8,
           xmax = 6.2,
           ymin = -0,
           ymax = 30,
           fill = sunrise_gold,
           alpha = 0.4)+
  annotate("rect",
           xmin = 20.5,
           xmax = 21,
           ymin = -0,
           ymax = 30,
           fill = '#f76218',
           alpha = 0.4)+
  geom_line(
    data = wind_data,
            aes(
              x = hrly_time,
              y = avg_gust_speed,
              color = mtn_name
            ),
            linewidth = 1.25)+
  geom_text(
    data = wind_data %>% dplyr::filter(hrly_time == max(hrly_time)),
    aes(
      x = hrly_time,
      y = avg_gust_speed,
      color = mtn_name,
      label = mtn_name),
    family = 'Mulish',
    fontface = 'bold',
    size = 1.3,
    vjust = 1.3,
    hjust = 0.4)+
  annotate("text",
           label = "Sunrise",
           family = "Mulish",
           x = 7.4,
           y = 1,
           size = 1.25,
           color = stone_gray)+
  annotate("text",
           label = "Sunset",
           family = "Mulish",
           x = 22,
           y = 1,
           size = 1.25,
           color = stone_gray)+
  geom_segment(aes(
    x = 2,
    y = 9,
    xend = 3,
    yend = 12.5),
    color = stone_gray,
    size = 0.6)+
  annotate("text",
           label = "My preferred time \n \n to start hikes \n \n (3am)",
           family = "Mulish",
           x = 2,
           y = 7,
           size = 1.25,
           color = stone_gray)+
  scale_x_continuous(breaks = seq(0,24,2),
                     limits = c(0,24))+
  scale_y_continuous(breaks = seq(0,30,5),
                     limits = c(0,30))+
  scale_color_manual(values = c(pine_green,
                                glacier_blue))+
  theme(ut_mtn_theme)+
  labs(title = "Beat the heat and beat the gusts!",
       subtitle = "Solar heating causes cooler air to rush down from the atomosphere \n \n giving hikers something to compete with on the mountainside.",
       y = "Avg. Gust Speed (mph)",
       x = "Hour",
       caption = "source: openmeteo (May-July)")

