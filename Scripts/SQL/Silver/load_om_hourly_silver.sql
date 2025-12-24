/*

Script Purpose:
	Inserting bronze.openmeteo_hourly data into silver layer with constraints for idempotency.

Notes:
	The pipeline maintains one forecast record per mountain per hour. 
	Running the insert multiple times on the same hour will update 
	existing records (upsert) rather than create duplicates, while 
	new hours are appended to preserve forecast history.

*/

insert into silver.openmeteo_hourly (mtn_id, latitude, longitude, elevation_m, timezone, pulled_at, hrly_time,
										hrly_rain_mm, hrly_is_day, hrly_showers_mm, hrly_snowfall_cm, hrly_uv_index,
										hrly_snow_depth_m, hrly_visibility_m, hrly_cloud_cover_pct, hrly_dew_point_2m_celsius,
										hrly_weather_code, hrly_precipitation_mm, hrly_temperature_2m_celsius, hrly_wind_gusts_10m_kmh,
										hrly_wind_speed_10m_kmh, hrly_wind_speed_80m_kmh, hrly_surface_pressure_hpa, 
										hrly_sunshine_duration_seconds, hrly_wind_direction_10m, hrly_wind_direction_80m, hrly_apparent_temperature_celsius, 
										hrly_relative_humidity_2m_pct, hrly_freezing_level_height_m, hrly_precipitation_probability_pct
)
select distinct on (mtn_id, (hourly_forecast -> 'hourly' ->> 'time')::timestamp)
	mtn_id,
	latitude,
	longitude,
	elevation,
	timezone,
	pulled_at,
	-- hourly forecast metrics
	(hourly_forecast -> 'hourly' ->> 'time')::timestamp as hrly_time,
	(hourly_forecast -> 'hourly' -> 'rain' ->> 0)::numeric as hrly_rain_mm,
	(hourly_forecast -> 'hourly' -> 'is_day' ->> 0)::int as hrly_is_day,
	(hourly_forecast -> 'hourly' -> 'showers' ->> 0)::numeric as hrly_showers_mm,
	(hourly_forecast -> 'hourly' -> 'snowfall' ->> 0)::numeric as hrly_snowfall_cm,
	(hourly_forecast -> 'hourly' -> 'uv_index' ->> 0)::numeric as hrly_uv_index,
	(hourly_forecast -> 'hourly' -> 'snow_depth' ->> 0)::numeric as hrly_snow_depth_m,
	(hourly_forecast -> 'hourly' -> 'visibility' ->> 0)::numeric as hrly_visibility_m,
	(hourly_forecast -> 'hourly' -> 'cloud_cover' ->> 0)::int as hrly_cloud_cover_pct,
	(hourly_forecast -> 'hourly' -> 'dew_point_2m' ->> 0)::numeric as hrly_dew_point_2m_celsius,
	(hourly_forecast -> 'hourly' -> 'weather_code' ->> 0)::int as hrly_weather_code,
	(hourly_forecast -> 'hourly' -> 'precipitation' ->> 0)::numeric as hrly_precipitation_mm,
	(hourly_forecast -> 'hourly' -> 'temperature_2m' ->> 0)::numeric as hrly_temperature_2m_celsius,
	(hourly_forecast -> 'hourly' -> 'wind_gusts_10m' ->> 0)::numeric as hrly_wind_gusts_10m_kmh,
	(hourly_forecast -> 'hourly' -> 'wind_speed_10m' ->> 0)::numeric as hrly_wind_speed_10m_kmh,
	(hourly_forecast -> 'hourly' -> 'wind_speed_80m' ->> 0)::numeric as hrly_wind_speed_80m_kmh,
	(hourly_forecast -> 'hourly' -> 'surface_pressure' ->> 0)::numeric as hrly_surface_pressure_hpa,
	(hourly_forecast -> 'hourly' -> 'sunshine_duration' ->> 0)::numeric as hrly_sunshine_duration_seconds,
	(hourly_forecast -> 'hourly' -> 'wind_direction_10m' ->> 0)::int as hrly_wind_direction_10m,
	(hourly_forecast -> 'hourly' -> 'wind_direction_80m' ->> 0)::int as hrly_wind_direction_80m,
	(hourly_forecast -> 'hourly' -> 'apparent_temperature' ->> 0)::numeric as hrly_apparent_temperature_celsius,
	(hourly_forecast -> 'hourly' -> 'relative_humidity_2m' ->> 0)::int as hrly_relative_humidity_2m_pct,
	(hourly_forecast -> 'hourly' -> 'freezing_level_height' ->> 0)::numeric as hrly_freezing_level_height_m,
	(hourly_forecast -> 'hourly' -> 'precipitation_probability' ->> 0)::int as hrly_precipitation_probability_pct
from bronze.openmeteo_hourly
-- incremental logic
where pulled_at::timestamp >= coalesce(
	(select max(pulled_at::timestamp) from silver.openmeteo_hourly),
	'1900-01-01'::timestamp
)
order by mtn_id, (hourly_forecast -> 'hourly' ->> 'time')::timestamp, pulled_at desc
on conflict (mtn_id, hrly_time) 
do update 
set
	pulled_at = excluded.pulled_at,
	latitude = excluded.latitude,
	longitude = excluded.longitude,
	elevation_m = excluded.elevation_m,
	timezone = excluded.timezone,
	hrly_rain_mm = excluded.hrly_rain_mm,
    hrly_is_day = excluded.hrly_is_day,
    hrly_showers_mm = excluded.hrly_showers_mm,
    hrly_snowfall_cm = excluded.hrly_snowfall_cm,
    hrly_uv_index = excluded.hrly_uv_index,
    hrly_snow_depth_m = excluded.hrly_snow_depth_m,
    hrly_visibility_m = excluded.hrly_visibility_m,
    hrly_cloud_cover_pct = excluded.hrly_cloud_cover_pct,
    hrly_dew_point_2m_celsius = excluded.hrly_dew_point_2m_celsius,
    hrly_weather_code = excluded.hrly_weather_code,
    hrly_precipitation_mm = excluded.hrly_precipitation_mm,
    hrly_temperature_2m_celsius = excluded.hrly_temperature_2m_celsius,
    hrly_wind_gusts_10m_kmh = excluded.hrly_wind_gusts_10m_kmh,
    hrly_wind_speed_10m_kmh = excluded.hrly_wind_speed_10m_kmh,
    hrly_wind_speed_80m_kmh = excluded.hrly_wind_speed_80m_kmh,
    hrly_surface_pressure_hpa = excluded.hrly_surface_pressure_hpa,
    hrly_sunshine_duration_seconds = excluded.hrly_sunshine_duration_seconds,
    hrly_wind_direction_10m = excluded.hrly_wind_direction_10m,
    hrly_wind_direction_80m = excluded.hrly_wind_direction_80m,
    hrly_apparent_temperature_celsius = excluded.hrly_apparent_temperature_celsius,
    hrly_relative_humidity_2m_pct = excluded.hrly_relative_humidity_2m_pct,
    hrly_freezing_level_height_m = excluded.hrly_freezing_level_height_m,
    hrly_precipitation_probability_pct = excluded.hrly_precipitation_probability_pct;