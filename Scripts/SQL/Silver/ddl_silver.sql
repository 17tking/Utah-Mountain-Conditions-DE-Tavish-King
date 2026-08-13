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
	- mountain_latitude, mountain_longitude, elevation_m, and mountain_timezone are mountain-level
	  attributes and live only in silver.mountains — they are not
	  repeated in fact tables (3NF)
=============================================================
*/


-- -------------------------
-- silver.mountains
-- -------------------------
drop table if exists silver.mountains cascade;

create table silver.mountains (
    mountain_id          INT             PRIMARY KEY,
    mountain_name        VARCHAR(100),
    mountain_range       VARCHAR(100),
    elevation_ft         INT             CHECK (elevation_ft > 0),
    elevation_m          INT             CHECK (elevation_m > 0),
    prominence_ft        INT,
    prominence_m         INT,
    isolation_mi         DECIMAL(6,2),
    isolation_km         DECIMAL(6,2),
    mountain_latitude    DECIMAL(9,6)    NOT NULL CHECK (mountain_latitude BETWEEN -90 AND 90),
    mountain_longitude   DECIMAL(9,6)    NOT NULL CHECK (mountain_longitude BETWEEN -180 AND 180),
    mountain_timezone    VARCHAR(50)
    create_date          TIMESTAMP       DEFAULT CURRENT_TIMESTAMP
);


-- -------------------------
-- silver.weathercodes
-- -------------------------
drop table if exists silver.weathercodes cascade;

create table silver.weathercodes (
    weather_code    INT         NOT NULL,
    description     TEXT        NOT NULL,
    image_url       TEXT        NOT NULL,
    PRIMARY KEY (weather_code)
);


-- ----------------------------
-- silver.openweather_alerts
-- ----------------------------
drop table if exists silver.alerts cascade;

create table silver.alerts (
    alert_id         VARCHAR(24)     PRIMARY KEY,
    mountain_id      INT             NOT NULL REFERENCES silver.mountains(mountain_id),
	create_date      TIMESTAMP       DEFAULT CURRENT_TIMESTAMP,
    sender_name      VARCHAR(100),
    event_name       VARCHAR(100)    NOT NULL,
    start_time       TIMESTAMPTZ     NOT NULL,
    end_time         TIMESTAMPTZ     NOT NULL CHECK (end_time >= start_time),
    description      TEXT            CHECK (length(description) <= 5000),
    alert_tags       JSONB
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