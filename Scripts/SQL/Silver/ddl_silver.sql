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
create table silver.dim_wiki_mtns (
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
select * from bronze.openmeteo_daily;

create table silver.openmeteo_daily (
mtn_id,
latitude,
longitude,
elevation_m,
timezone,
pulled_at_utc,
dly_time_utc,
dly_sunset_utc,
dly_sunrise_utc,
dly_rain_sum_mm,
dly_showers_sum_mm,
dly_snowfall_sum_cm,
dly_uv_index_max,
dly_weather_code,
dly_visibility_max_m,
dly_visibility_min_m,
dly_cloud_cover_max_pct,
dly_cloud_cover_min_pct,
dly_visibility_mean_m,
dly_cloud_cover_mean_pct,
dly_dew_point_2m_max_celcius,
dly_dew_point_2m_min_celcius,
dly_daylight_duration_seconds,
dly_dew_point_2m_mean_celcius,
dly_precipitation_sum_mm,
dly_sunshine_duration_seconds,
dly_temperature_2m_max_celcius,
dly_temperature_2m_min_celcius,
dly_wind_gusts_10m_max_kmh,
dly_wind_gusts_10m_min_kmh,
dly_wind_speed_10m_max_kmh,
dly_wind_speed_10m_min_kmh,
dly_precipitation_hours,
dly_temperature_2m_mean_celcius,
dly_wind_gusts_10m_mean_kmh,
dly_wind_speed_10m_mean_kmh,
dly_surface_pressure_max_hpa,
dly_surface_pressure_min_hpa,
dly_surface_pressure_mean_hpa,
dly_apparent_temperature_max_celcius,
dly_apparent_temperature_min_celcius,
dly_relative_humidity_2m_max_pct,
dly_relative_humidity_2m_min_pct,
dly_apparent_temperature_mean_celcius,
dly_relative_humidity_2m_mean_pct,
dly_wind_dir_10m_dominant,
dly_precipitation_probability_max_pct,
dly_precipitation_probability_min_pct,
dly_precipitation_probability_mean_pct,
);

