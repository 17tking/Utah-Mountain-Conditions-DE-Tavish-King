/*

Script Purpose:
	Inserting bronze.openmeteo_daily data into silver layer with constraints for idempotency.

Note:
	Incremental logic ensures only one forecast per mountain per calendar day (e.g. '2025-12-25'). 
	If the pipeline runs multiple times on the same day, existing records are 
	updated rather than duplicated.

	latitude, longitude, elevation_m, and timezone are mountain-level attributes
	stored in silver.wiki_mtns and are not repeated here (3NF).

*/

insert into silver.openmeteo_daily (
    mtn_id, measured_at_m, pulled_at, dly_time, dly_sunset, dly_sunrise,
    dly_weather_code, dly_rain_sum_mm, dly_showers_sum_mm, dly_snowfall_sum_cm,
    dly_uv_index_max, dly_visibility_max_m, dly_visibility_min_m, dly_visibility_mean_m,
    dly_cloud_cover_max_pct, dly_cloud_cover_min_pct, dly_cloud_cover_mean_pct,
    dly_dew_point_2m_max_celsius, dly_dew_point_2m_min_celsius, dly_dew_point_2m_mean_celsius,
    dly_daylight_duration_seconds, dly_precipitation_sum_mm, dly_precipitation_hours,
    dly_precipitation_probability_max_pct, dly_precipitation_probability_min_pct, dly_precipitation_probability_mean_pct,
    dly_sunshine_duration_seconds, dly_temperature_2m_max_celsius, dly_temperature_2m_min_celsius,
    dly_temperature_2m_mean_celsius, dly_apparent_temperature_max_celsius, dly_apparent_temperature_min_celsius,
    dly_apparent_temperature_mean_celsius, dly_wind_gusts_10m_max_kmh, dly_wind_gusts_10m_min_kmh,
    dly_wind_gusts_10m_mean_kmh, dly_wind_speed_10m_max_kmh, dly_wind_speed_10m_min_kmh,
    dly_wind_speed_10m_mean_kmh, dly_wind_direction_10m_dominant,
    dly_surface_pressure_max_hpa, dly_surface_pressure_min_hpa, dly_surface_pressure_mean_hpa,
    dly_relative_humidity_2m_max_pct, dly_relative_humidity_2m_min_pct, dly_relative_humidity_2m_mean_pct
)
select distinct on (mtn_id, (daily_forecast -> 'daily' -> 'time' ->> idx)::date)
    mtn_id,
    measured_at_m,
    pulled_at,
    (daily_forecast -> 'daily' -> 'time'                        ->> idx)::date          as dly_time,
    (daily_forecast -> 'daily' -> 'sunset'                      ->> idx)::timestamptz   as dly_sunset,
    (daily_forecast -> 'daily' -> 'sunrise'                     ->> idx)::timestamptz   as dly_sunrise,
    (daily_forecast -> 'daily' -> 'weather_code'                ->> idx)::int           as dly_weather_code,
    (daily_forecast -> 'daily' -> 'rain_sum'                    ->> idx)::numeric       as dly_rain_sum_mm,
    (daily_forecast -> 'daily' -> 'showers_sum'                 ->> idx)::numeric       as dly_showers_sum_mm,
    (daily_forecast -> 'daily' -> 'snowfall_sum'                ->> idx)::numeric       as dly_snowfall_sum_cm,
    (daily_forecast -> 'daily' -> 'uv_index_max'                ->> idx)::numeric       as dly_uv_index_max,
    (daily_forecast -> 'daily' -> 'visibility_max'              ->> idx)::numeric       as dly_visibility_max_m,
    (daily_forecast -> 'daily' -> 'visibility_min'              ->> idx)::numeric       as dly_visibility_min_m,
    (daily_forecast -> 'daily' -> 'visibility_mean'             ->> idx)::numeric       as dly_visibility_mean_m,
    (daily_forecast -> 'daily' -> 'cloud_cover_max'             ->> idx)::int           as dly_cloud_cover_max_pct,
    (daily_forecast -> 'daily' -> 'cloud_cover_min'             ->> idx)::int           as dly_cloud_cover_min_pct,
    (daily_forecast -> 'daily' -> 'cloud_cover_mean'            ->> idx)::int           as dly_cloud_cover_mean_pct,
    (daily_forecast -> 'daily' -> 'dew_point_2m_max'            ->> idx)::numeric       as dly_dew_point_2m_max_celsius,
    (daily_forecast -> 'daily' -> 'dew_point_2m_min'            ->> idx)::numeric       as dly_dew_point_2m_min_celsius,
    (daily_forecast -> 'daily' -> 'dew_point_2m_mean'           ->> idx)::numeric       as dly_dew_point_2m_mean_celsius,
    (daily_forecast -> 'daily' -> 'daylight_duration'           ->> idx)::numeric       as dly_daylight_duration_seconds,
    (daily_forecast -> 'daily' -> 'precipitation_sum'           ->> idx)::numeric       as dly_precipitation_sum_mm,
    (daily_forecast -> 'daily' -> 'precipitation_hours'         ->> idx)::numeric       as dly_precipitation_hours,
    (daily_forecast -> 'daily' -> 'precipitation_probability_max'  ->> idx)::int        as dly_precipitation_probability_max_pct,
    (daily_forecast -> 'daily' -> 'precipitation_probability_min'  ->> idx)::int        as dly_precipitation_probability_min_pct,
    (daily_forecast -> 'daily' -> 'precipitation_probability_mean' ->> idx)::int        as dly_precipitation_probability_mean_pct,
    (daily_forecast -> 'daily' -> 'sunshine_duration'           ->> idx)::numeric       as dly_sunshine_duration_seconds,
    (daily_forecast -> 'daily' -> 'temperature_2m_max'          ->> idx)::numeric       as dly_temperature_2m_max_celsius,
    (daily_forecast -> 'daily' -> 'temperature_2m_min'          ->> idx)::numeric       as dly_temperature_2m_min_celsius,
    (daily_forecast -> 'daily' -> 'temperature_2m_mean'         ->> idx)::numeric       as dly_temperature_2m_mean_celsius,
    (daily_forecast -> 'daily' -> 'apparent_temperature_max'    ->> idx)::numeric       as dly_apparent_temperature_max_celsius,
    (daily_forecast -> 'daily' -> 'apparent_temperature_min'    ->> idx)::numeric       as dly_apparent_temperature_min_celsius,
    (daily_forecast -> 'daily' -> 'apparent_temperature_mean'   ->> idx)::numeric       as dly_apparent_temperature_mean_celsius,
    (daily_forecast -> 'daily' -> 'wind_gusts_10m_max'          ->> idx)::numeric       as dly_wind_gusts_10m_max_kmh,
    (daily_forecast -> 'daily' -> 'wind_gusts_10m_min'          ->> idx)::numeric       as dly_wind_gusts_10m_min_kmh,
    (daily_forecast -> 'daily' -> 'wind_gusts_10m_mean'         ->> idx)::numeric       as dly_wind_gusts_10m_mean_kmh,
    (daily_forecast -> 'daily' -> 'wind_speed_10m_max'          ->> idx)::numeric       as dly_wind_speed_10m_max_kmh,
    (daily_forecast -> 'daily' -> 'wind_speed_10m_min'          ->> idx)::numeric       as dly_wind_speed_10m_min_kmh,
    (daily_forecast -> 'daily' -> 'wind_speed_10m_mean'         ->> idx)::numeric       as dly_wind_speed_10m_mean_kmh,
    (daily_forecast -> 'daily' -> 'wind_direction_10m_dominant' ->> idx)::int           as dly_wind_direction_10m_dominant,
    (daily_forecast -> 'daily' -> 'surface_pressure_max'        ->> idx)::numeric       as dly_surface_pressure_max_hpa,
    (daily_forecast -> 'daily' -> 'surface_pressure_min'        ->> idx)::numeric       as dly_surface_pressure_min_hpa,
    (daily_forecast -> 'daily' -> 'surface_pressure_mean'       ->> idx)::numeric       as dly_surface_pressure_mean_hpa,
    (daily_forecast -> 'daily' -> 'relative_humidity_2m_max'    ->> idx)::int           as dly_relative_humidity_2m_max_pct,
    (daily_forecast -> 'daily' -> 'relative_humidity_2m_min'    ->> idx)::int           as dly_relative_humidity_2m_min_pct,
    (daily_forecast -> 'daily' -> 'relative_humidity_2m_mean'   ->> idx)::int           as dly_relative_humidity_2m_mean_pct
from bronze.openmeteo_daily
cross join lateral generate_series(
    0,
    jsonb_array_length(daily_forecast -> 'daily' -> 'time') - 1
) as idx
where pulled_at::date > coalesce(
    (select max(pulled_at::date) from silver.openmeteo_daily),
    '1900-01-01'::date
)
order by mtn_id, (daily_forecast -> 'daily' -> 'time' ->> idx)::date, pulled_at desc
on conflict (mtn_id, dly_time)
do update set
    measured_at_m                           = excluded.measured_at_m,
    pulled_at                               = excluded.pulled_at,
    dly_sunset                              = excluded.dly_sunset,
    dly_sunrise                             = excluded.dly_sunrise,
    dly_weather_code                        = excluded.dly_weather_code,
    dly_rain_sum_mm                         = excluded.dly_rain_sum_mm,
    dly_showers_sum_mm                      = excluded.dly_showers_sum_mm,
    dly_snowfall_sum_cm                     = excluded.dly_snowfall_sum_cm,
    dly_uv_index_max                        = excluded.dly_uv_index_max,
    dly_visibility_max_m                    = excluded.dly_visibility_max_m,
    dly_visibility_min_m                    = excluded.dly_visibility_min_m,
    dly_visibility_mean_m                   = excluded.dly_visibility_mean_m,
    dly_cloud_cover_max_pct                 = excluded.dly_cloud_cover_max_pct,
    dly_cloud_cover_min_pct                 = excluded.dly_cloud_cover_min_pct,
    dly_cloud_cover_mean_pct                = excluded.dly_cloud_cover_mean_pct,
    dly_dew_point_2m_max_celsius            = excluded.dly_dew_point_2m_max_celsius,
    dly_dew_point_2m_min_celsius            = excluded.dly_dew_point_2m_min_celsius,
    dly_dew_point_2m_mean_celsius           = excluded.dly_dew_point_2m_mean_celsius,
    dly_daylight_duration_seconds           = excluded.dly_daylight_duration_seconds,
    dly_precipitation_sum_mm                = excluded.dly_precipitation_sum_mm,
    dly_precipitation_hours                 = excluded.dly_precipitation_hours,
    dly_precipitation_probability_max_pct   = excluded.dly_precipitation_probability_max_pct,
    dly_precipitation_probability_min_pct   = excluded.dly_precipitation_probability_min_pct,
    dly_precipitation_probability_mean_pct  = excluded.dly_precipitation_probability_mean_pct,
    dly_sunshine_duration_seconds           = excluded.dly_sunshine_duration_seconds,
    dly_temperature_2m_max_celsius          = excluded.dly_temperature_2m_max_celsius,
    dly_temperature_2m_min_celsius          = excluded.dly_temperature_2m_min_celsius,
    dly_temperature_2m_mean_celsius         = excluded.dly_temperature_2m_mean_celsius,
    dly_apparent_temperature_max_celsius    = excluded.dly_apparent_temperature_max_celsius,
    dly_apparent_temperature_min_celsius    = excluded.dly_apparent_temperature_min_celsius,
    dly_apparent_temperature_mean_celsius   = excluded.dly_apparent_temperature_mean_celsius,
    dly_wind_gusts_10m_max_kmh              = excluded.dly_wind_gusts_10m_max_kmh,
    dly_wind_gusts_10m_min_kmh              = excluded.dly_wind_gusts_10m_min_kmh,
    dly_wind_gusts_10m_mean_kmh             = excluded.dly_wind_gusts_10m_mean_kmh,
    dly_wind_speed_10m_max_kmh              = excluded.dly_wind_speed_10m_max_kmh,
    dly_wind_speed_10m_min_kmh              = excluded.dly_wind_speed_10m_min_kmh,
    dly_wind_speed_10m_mean_kmh             = excluded.dly_wind_speed_10m_mean_kmh,
    dly_wind_direction_10m_dominant         = excluded.dly_wind_direction_10m_dominant,
    dly_surface_pressure_max_hpa            = excluded.dly_surface_pressure_max_hpa,
    dly_surface_pressure_min_hpa            = excluded.dly_surface_pressure_min_hpa,
    dly_surface_pressure_mean_hpa           = excluded.dly_surface_pressure_mean_hpa,
    dly_relative_humidity_2m_max_pct        = excluded.dly_relative_humidity_2m_max_pct,
    dly_relative_humidity_2m_min_pct        = excluded.dly_relative_humidity_2m_min_pct,
    dly_relative_humidity_2m_mean_pct       = excluded.dly_relative_humidity_2m_mean_pct;