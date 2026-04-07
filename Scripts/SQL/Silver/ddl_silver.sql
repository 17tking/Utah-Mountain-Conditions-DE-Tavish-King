/*
=============================================================
DDL Script: Create Silver Tables
=============================================================
Script Purpose:
	The Silver layer stores cleaned, normalized, and validated 
	data extracted from the Bronze raw tables. All tables are 
	designed in 3rd Normal Form (3NF) to eliminate redundancy 
	and ensure data integrity.

Notes:
	- Each table includes constraints to enforce data quality
	- Tables are designed for incremental loading with upserts
	- JSON fields from Bronze are transformed into relational columns
	- No business logic or aggregation is applied
	- latitude, longitude, elevation_m, and timezone are mountain-level
	  attributes and live only in silver.wiki_mtns — they are not
	  repeated in fact tables (3NF)
=============================================================
*/


-- -------------------------
-- silver.wiki_mtns
-- -------------------------
-- Renamed mtn_id_pk to mtn_id for cleaner FK references across all tables
drop table if exists silver.wiki_mtns cascade;

create table silver.wiki_mtns (
    mtn_id      INT             PRIMARY KEY,
    mtn_name    VARCHAR(100),
    mtn_range   VARCHAR(100),
    elev_ft     INT             CHECK (elev_ft > 0),
    elev_m      INT             CHECK (elev_m > 0),
    prom_ft     INT,
    prom_m      INT,
    isol_mi     DECIMAL(6,2),
    isol_km     DECIMAL(6,2),
    latitude    DECIMAL(9,6)    NOT NULL CHECK (latitude BETWEEN -90 AND 90),
    longitude   DECIMAL(9,6)    NOT NULL CHECK (longitude BETWEEN -180 AND 180),
    elevation_m INT             CHECK (elevation_m > 0),
    timezone    VARCHAR(50)
);


-- -------------------------
-- silver.weathercodes
-- -------------------------
drop table if exists silver.weathercodes cascade;

create table silver.weathercodes (
    weather_code    INT         NOT NULL,
    time_of_day     VARCHAR(5)  NOT NULL CHECK (time_of_day IN ('day', 'night')),
    description     TEXT        NOT NULL,
    image_url       TEXT        NOT NULL,
    PRIMARY KEY (weather_code)
);


-- ----------------------------
-- silver.openweather_alerts
-- ----------------------------
drop table if exists silver.openweather_alerts cascade;

create table silver.openweather_alerts (
    mtn_id              INT             NOT NULL REFERENCES silver.wiki_mtns(mtn_id),
    alert_sender_name   TEXT,
    alert_event         TEXT            NOT NULL,
    alert_start         TIMESTAMPTZ     NOT NULL,
    alert_end           TIMESTAMPTZ     NOT NULL CHECK (alert_end >= alert_start),
    alert_description   TEXT            CHECK (length(alert_description) <= 5000),
    alert_tags          JSONB,
    PRIMARY KEY (mtn_id, alert_event, alert_start)
);


-- ----------------------------
-- silver.openmeteo_daily
-- ----------------------------
drop table if exists silver.openmeteo_daily cascade;

create table silver.openmeteo_daily (
    mtn_id                                  INT             NOT NULL REFERENCES silver.wiki_mtns(mtn_id),
    measured_at_m                           INT,
    pulled_at                               TIMESTAMPTZ,
    dly_time                                DATE            NOT NULL,
    dly_sunset                              TIMESTAMPTZ,
    dly_sunrise                             TIMESTAMPTZ,
    dly_weather_code                        INT             REFERENCES silver.weathercodes(weather_code),
    dly_rain_sum_mm                         NUMERIC(10,2)   CHECK (dly_rain_sum_mm >= 0),
    dly_showers_sum_mm                      NUMERIC(10,2)   CHECK (dly_showers_sum_mm >= 0),
    dly_snowfall_sum_cm                     NUMERIC(10,2)   CHECK (dly_snowfall_sum_cm >= 0),
    dly_uv_index_max                        NUMERIC(5,2),
    dly_visibility_max_m                    NUMERIC(10,2),
    dly_visibility_min_m                    NUMERIC(10,2),
    dly_visibility_mean_m                   NUMERIC(10,2),
    dly_cloud_cover_max_pct                 INT             CHECK (dly_cloud_cover_max_pct BETWEEN 0 AND 100),
    dly_cloud_cover_min_pct                 INT             CHECK (dly_cloud_cover_min_pct BETWEEN 0 AND 100),
    dly_cloud_cover_mean_pct                INT             CHECK (dly_cloud_cover_mean_pct BETWEEN 0 AND 100),
    dly_dew_point_2m_max_celsius            NUMERIC(5,2),
    dly_dew_point_2m_min_celsius            NUMERIC(5,2),
    dly_dew_point_2m_mean_celsius           NUMERIC(5,2),
    dly_daylight_duration_seconds           NUMERIC(10,2)   CHECK (dly_daylight_duration_seconds >= 0),
    dly_precipitation_sum_mm                NUMERIC(10,2)   CHECK (dly_precipitation_sum_mm >= 0),
    dly_precipitation_hours                 NUMERIC(10,2)   CHECK (dly_precipitation_hours >= 0),
    dly_precipitation_probability_max_pct   INT             CHECK (dly_precipitation_probability_max_pct BETWEEN 0 AND 100),
    dly_precipitation_probability_min_pct   INT             CHECK (dly_precipitation_probability_min_pct BETWEEN 0 AND 100),
    dly_precipitation_probability_mean_pct  INT             CHECK (dly_precipitation_probability_mean_pct BETWEEN 0 AND 100),
    dly_sunshine_duration_seconds           NUMERIC(10,2)   CHECK (dly_sunshine_duration_seconds >= 0),
    dly_temperature_2m_max_celsius          NUMERIC(5,2),
    dly_temperature_2m_min_celsius          NUMERIC(5,2),
    dly_temperature_2m_mean_celsius         NUMERIC(5,2),
    dly_apparent_temperature_max_celsius    NUMERIC(5,2),
    dly_apparent_temperature_min_celsius    NUMERIC(5,2),
    dly_apparent_temperature_mean_celsius   NUMERIC(5,2),
    dly_wind_gusts_10m_max_kmh              NUMERIC(10,2),
    dly_wind_gusts_10m_min_kmh              NUMERIC(10,2),
    dly_wind_gusts_10m_mean_kmh             NUMERIC(10,2),
    dly_wind_speed_10m_max_kmh              NUMERIC(10,2),
    dly_wind_speed_10m_min_kmh              NUMERIC(10,2),
    dly_wind_speed_10m_mean_kmh             NUMERIC(10,2),
    dly_wind_direction_10m_dominant         INT,
    dly_surface_pressure_max_hpa            NUMERIC(10,2),
    dly_surface_pressure_min_hpa            NUMERIC(10,2),
    dly_surface_pressure_mean_hpa           NUMERIC(10,2),
    dly_relative_humidity_2m_max_pct        INT             CHECK (dly_relative_humidity_2m_max_pct BETWEEN 0 AND 100),
    dly_relative_humidity_2m_min_pct        INT             CHECK (dly_relative_humidity_2m_min_pct BETWEEN 0 AND 100),
    dly_relative_humidity_2m_mean_pct       INT             CHECK (dly_relative_humidity_2m_mean_pct BETWEEN 0 AND 100),
    PRIMARY KEY (mtn_id, dly_time)
);


-- ----------------------------
-- silver.openmeteo_hourly
-- ----------------------------
drop table if exists silver.openmeteo_hourly cascade;

create table silver.openmeteo_hourly (
    mtn_id                          INT             NOT NULL REFERENCES silver.wiki_mtns(mtn_id),
    measured_at_m                   INT,
    pulled_at                       TIMESTAMPTZ,
    hrly_time                       TIMESTAMP       NOT NULL,
    hrly_weather_code               INT             REFERENCES silver.weathercodes(weather_code),
    hrly_rain_mm                    NUMERIC(10,2)   CHECK (hrly_rain_mm >= 0),
    hrly_showers_mm                 NUMERIC(10,2)   CHECK (hrly_showers_mm >= 0),
    hrly_snowfall_cm                NUMERIC(10,2)   CHECK (hrly_snowfall_cm >= 0),
    hrly_snow_depth_m               NUMERIC(10,2)   CHECK (hrly_snow_depth_m >= 0),
    hrly_precipitation_mm           NUMERIC(10,2)   CHECK (hrly_precipitation_mm >= 0),
    hrly_precipitation_probability_pct INT          CHECK (hrly_precipitation_probability_pct BETWEEN 0 AND 100),
    hrly_uv_index                   NUMERIC(5,2),
    hrly_is_day                     INT,
    hrly_visibility_m               NUMERIC(10,2),
    hrly_cloud_cover_pct            INT             CHECK (hrly_cloud_cover_pct BETWEEN 0 AND 100),
    hrly_dew_point_2m_celsius       NUMERIC(5,2),
    hrly_temperature_2m_celsius     NUMERIC(5,2),
    hrly_apparent_temperature_celsius NUMERIC(5,2),
    hrly_relative_humidity_2m_pct   INT             CHECK (hrly_relative_humidity_2m_pct BETWEEN 0 AND 100),
    hrly_wind_gusts_10m_kmh         NUMERIC(10,2),
    hrly_wind_speed_10m_kmh         NUMERIC(10,2),
    hrly_wind_speed_80m_kmh         NUMERIC(10,2),
    hrly_wind_direction_10m         INT,
    hrly_wind_direction_80m         INT,
    hrly_surface_pressure_hpa       NUMERIC(10,2),
    hrly_sunshine_duration_seconds  NUMERIC(10,2),
    hrly_freezing_level_height_m    NUMERIC(10,2),
    PRIMARY KEY (mtn_id, hrly_time)
);


-- ------------------------------
-- silver.openmeteo_lightning
-- ------------------------------
drop table if exists silver.openmeteo_lightning cascade;

create table silver.openmeteo_lightning (
    mtn_id              INT             NOT NULL REFERENCES silver.wiki_mtns(mtn_id),
    measured_at_m       INT,
    pulled_at           TIMESTAMPTZ,
    ltng_time           TIMESTAMP       NOT NULL,
    ltng_potential_j_kg_max NUMERIC(10,2),
	ltng_potential_j_kg_mean NUMERIC(10,2),
    PRIMARY KEY (mtn_id, ltng_time)
);