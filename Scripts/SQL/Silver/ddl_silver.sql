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
    - Each table includes specific constraints to enforce
    - Tables are designed for incremental loading
    - JSON fields from Bronze are transformed into relational columns
    - No business logic or aggregation is applied
=============================================================
*/

-- Creating dimension wiki_mtns in Silver schema
create table silver.wiki_mtns (
mtn_id_pk VARCHAR(3) PRIMARY KEY,
mtn_name VARCHAR(100) NOT NULL,
mtn_range VARCHAR(100),
elev_ft INT CHECK (elev_ft > 0),
elev_m INT CHECK (elev_m > 0),
prom_ft INT,
prom_m INT,
isol_mi DECIMAL(6,2),
isol_km DECIMAL(6,2),
latitude DECIMAL(9,6) NOT NULL CHECK (latitude BETWEEN -90 AND 90),
longitude DECIMAL(9,6) NOT NULL CHECK (longitude BETWEEN -180 AND 180)
);

-- Creating table for weathercodes in Silver schema
create table silver.weathercodes (
weather_code INT NOT NULL,
time_of_day VARCHAR(5) NOT NULL CHECK (time_of_day IN ('day', 'night')),
description TEXT NOT NULL,
image_url TEXT NOT NULL,
PRIMARY KEY (weather_code, time_of_day)
);

-- Creating OW Alerts table in Silver schema
create table silver.openweather_alerts (
alert_id_pk SERIAL PRIMARY KEY,
mtn_id VARCHAR(3) NOT NULL,
latitude DECIMAL(9,6) NOT NULL CHECK (latitude BETWEEN -90 AND 90),
longitude DECIMAL(9,6) NOT NULL CHECK (longitude BETWEEN -180 AND 180),
alert_sender_name TEXT,
alert_event TEXT NOT NULL,
alert_start TIMESTAMPTZ NOT NULL,
alert_end TIMESTAMPTZ NOT NULL CHECK (alert_end >= alert_start),
alert_description TEXT CHECK (length(alert_description) <= 5000),
alert_tags JSONB,
-- for upsert purposes
unique (mtn_id, alert_event, alert_start)
);

--Creating OM Daily Forecast table in Silver schema
drop table if exists silver.openmeteo_daily;
create table silver.openmeteo_daily (
mtn_id VARCHAR(3) NOT NULL,
latitude DECIMAL(9,6) NOT NULL CHECK (latitude BETWEEN -90 AND 90),
longitude DECIMAL(9,6) NOT NULL CHECK (longitude BETWEEN -180 AND 180),
elevation_m INT CHECK (elevation_m > 0),
timezone VARCHAR(50) NOT NULL,
pulled_at TIMESTAMPTZ,
dly_time DATE NOT NULL,
dly_sunset TIMESTAMPTZ,
dly_sunrise TIMESTAMPTZ,
dly_rain_sum_mm NUMERIC(10,2) CHECK(dly_rain_sum_mm >= 0),
dly_showers_sum_mm NUMERIC(10,2) CHECK(dly_showers_sum_mm >= 0),
dly_snowfall_sum_cm NUMERIC(10,2) CHECK(dly_snowfall_sum_cm >= 0),
dly_uv_index_max NUMERIC(5,2),
dly_weather_code INT,
dly_visibility_max_m NUMERIC(10,2),
dly_visibility_min_m NUMERIC(10,2),
dly_cloud_cover_max_pct INT CHECK(dly_cloud_cover_max_pct BETWEEN 0 AND 100),
dly_cloud_cover_min_pct INT CHECK(dly_cloud_cover_min_pct BETWEEN 0 AND 100),
dly_visibility_mean_m NUMERIC(10,2),
dly_cloud_cover_mean_pct INT CHECK(dly_cloud_cover_mean_pct BETWEEN 0 AND 100),
dly_dew_point_2m_max_celsius NUMERIC(5,2),
dly_dew_point_2m_min_celsius NUMERIC(5,2),
dly_daylight_duration_seconds NUMERIC(10,2) CHECK(dly_daylight_duration_seconds >= 0),
dly_dew_point_2m_mean_celsius NUMERIC(5,2),
dly_precipitation_sum_mm NUMERIC(10,2) CHECK(dly_precipitation_sum_mm >= 0),
dly_sunshine_duration_seconds NUMERIC(10,2) CHECK(dly_sunshine_duration_seconds >= 0),
dly_temperature_2m_max_celsius NUMERIC(5,2),
dly_temperature_2m_min_celsius NUMERIC(5,2),
dly_wind_gusts_10m_max_kmh NUMERIC(10,2),
dly_wind_gusts_10m_min_kmh NUMERIC(10,2),
dly_wind_speed_10m_max_kmh NUMERIC(10,2),
dly_wind_speed_10m_min_kmh NUMERIC(10,2),
dly_precipitation_hours NUMERIC(10,2) CHECK(dly_precipitation_hours >= 0),
dly_temperature_2m_mean_celsius NUMERIC(5,2),
dly_wind_gusts_10m_mean_kmh NUMERIC(10,2),
dly_wind_speed_10m_mean_kmh NUMERIC(10,2),
dly_surface_pressure_max_hpa NUMERIC(10,2),
dly_surface_pressure_min_hpa NUMERIC(10,2),
dly_surface_pressure_mean_hpa NUMERIC(10,2),
dly_apparent_temperature_max_celsius NUMERIC(5,2),
dly_apparent_temperature_min_celsius NUMERIC(5,2),
dly_relative_humidity_2m_max_pct INT CHECK(dly_relative_humidity_2m_max_pct BETWEEN 0 AND 100),
dly_relative_humidity_2m_min_pct INT CHECK(dly_relative_humidity_2m_min_pct BETWEEN 0 AND 100),
dly_apparent_temperature_mean_celsius NUMERIC(5,2),
dly_relative_humidity_2m_mean_pct INT CHECK(dly_relative_humidity_2m_mean_pct BETWEEN 0 AND 100),
dly_wind_dir_10m_dominant INT,
dly_precipitation_probability_max_pct INT CHECK(dly_precipitation_probability_max_pct BETWEEN 0 AND 100),
dly_precipitation_probability_min_pct INT CHECK(dly_precipitation_probability_min_pct BETWEEN 0 AND 100),
dly_precipitation_probability_mean_pct INT CHECK(dly_precipitation_probability_mean_pct BETWEEN 0 AND 100),
PRIMARY KEY(mtn_id, dly_time)
);