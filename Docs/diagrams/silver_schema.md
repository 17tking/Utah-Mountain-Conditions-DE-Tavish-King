# Silver Layer Schema Documentation

## Overview

The Silver layer stores cleaned, normalized, and validated data extracted from Bronze raw tables. All tables are designed in 3rd Normal Form (3NF) to eliminate redundancy and ensure data integrity. JSON fields from Bronze are transformed into typed relational columns. No business logic or aggregation is applied at this layer except in `silver.openmeteo_lightning`. Average and Max are used to condense table and save local storage.

**Design principles:**
- All tables include constraints to enforce data quality
- Tables are designed for incremental loading with upserts
- `latitude`, `longitude`, `elevation_m`, and `timezone` are mountain-level attributes stored only in `silver.wiki_mtns` — not repeated in fact tables (3NF)

---

## Tables

### `silver.wiki_mtns`
Reference table for all tracked Utah mountain summits. Serves as the primary dimension table and is referenced by all fact tables via `mtn_id`.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `mtn_id` | INT | PRIMARY KEY | Unique mountain identifier |
| `mtn_name` | VARCHAR(100) | | Mountain name |
| `mtn_range` | VARCHAR(100) | | Mountain range name |
| `elev_ft` | INT | CHECK > 0 | Summit elevation in feet |
| `elev_m` | INT | CHECK > 0 | Summit elevation in meters |
| `prom_ft` | INT | | Topographic prominence in feet |
| `prom_m` | INT | | Topographic prominence in meters |
| `isol_mi` | DECIMAL(6,2) | | Isolation in miles |
| `isol_km` | DECIMAL(6,2) | | Isolation in kilometers |
| `latitude` | DECIMAL(9,6) | NOT NULL, BETWEEN -90 AND 90 | Summit latitude |
| `longitude` | DECIMAL(9,6) | NOT NULL, BETWEEN -180 AND 180 | Summit longitude |
| `timezone` | VARCHAR(50) | | Local timezone string |

---

### `silver.weathercodes`
Lookup table mapping WMO weather codes to human-readable descriptions and icons.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `weather_code` | INT | PRIMARY KEY | WMO weather code |
| `time_of_day` | VARCHAR(5) | CHECK IN ('day', 'night') | Day or night variant |
| `description` | TEXT | NOT NULL | Human-readable weather description |
| `image_url` | TEXT | NOT NULL | URL to weather icon image |

---

### `silver.openweather_alerts`
Active weather alerts per mountain sourced from the OpenWeather API. One row per unique alert event.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `mtn_id` | INT | NOT NULL, FK → wiki_mtns | Mountain identifier |
| `alert_sender_name` | TEXT | | Name of the alert issuing agency |
| `alert_event` | TEXT | NOT NULL | Alert event type (e.g. "Wind Advisory") |
| `alert_start` | TIMESTAMPTZ | NOT NULL | Alert start time (America/Denver) |
| `alert_end` | TIMESTAMPTZ | NOT NULL, CHECK >= alert_start | Alert end time (America/Denver) |
| `alert_description` | TEXT | CHECK length <= 5000 | Full alert description text |
| `alert_tags` | JSONB | | Additional alert tags from API |

**Primary Key:** `(mtn_id, alert_event, alert_start)`

---

### `silver.openmeteo_daily`
Daily weather forecast data per mountain sourced from the Open-Meteo API. One row per mountain per forecast day.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `mtn_id` | INT | NOT NULL, FK → wiki_mtns | Mountain identifier |
| `measured_at_m` | INT | | Elevation at which forecast is measured |
| `pulled_at` | TIMESTAMPTZ | | Ingestion timestamp (MT) |
| `dly_time` | DATE | NOT NULL | Forecast date |
| `dly_sunrise` | TIMESTAMPTZ | | Sunrise time |
| `dly_sunset` | TIMESTAMPTZ | | Sunset time |
| `dly_weather_code` | INT | FK → weathercodes | WMO weather code |
| `dly_rain_sum_mm` | NUMERIC(10,2) | CHECK >= 0 | Total rain in mm |
| `dly_showers_sum_mm` | NUMERIC(10,2) | CHECK >= 0 | Total showers in mm |
| `dly_snowfall_sum_cm` | NUMERIC(10,2) | CHECK >= 0 | Total snowfall in cm |
| `dly_uv_index_max` | NUMERIC(5,2) | | Max UV index |
| `dly_visibility_max_m` | NUMERIC(10,2) | | Max visibility in meters |
| `dly_visibility_min_m` | NUMERIC(10,2) | | Min visibility in meters |
| `dly_visibility_mean_m` | NUMERIC(10,2) | | Mean visibility in meters |
| `dly_cloud_cover_max_pct` | INT | CHECK 0–100 | Max cloud cover % |
| `dly_cloud_cover_min_pct` | INT | CHECK 0–100 | Min cloud cover % |
| `dly_cloud_cover_mean_pct` | INT | CHECK 0–100 | Mean cloud cover % |
| `dly_dew_point_2m_max_celsius` | NUMERIC(5,2) | | Max dew point at 2m in °C |
| `dly_dew_point_2m_min_celsius` | NUMERIC(5,2) | | Min dew point at 2m in °C |
| `dly_dew_point_2m_mean_celsius` | NUMERIC(5,2) | | Mean dew point at 2m in °C |
| `dly_daylight_duration_seconds` | NUMERIC(10,2) | CHECK >= 0 | Total daylight duration in seconds |
| `dly_precipitation_sum_mm` | NUMERIC(10,2) | CHECK >= 0 | Total precipitation in mm |
| `dly_precipitation_hours` | NUMERIC(10,2) | CHECK >= 0 | Hours with precipitation |
| `dly_precipitation_probability_max_pct` | INT | CHECK 0–100 | Max precip probability % |
| `dly_precipitation_probability_min_pct` | INT | CHECK 0–100 | Min precip probability % |
| `dly_precipitation_probability_mean_pct` | INT | CHECK 0–100 | Mean precip probability % |
| `dly_sunshine_duration_seconds` | NUMERIC(10,2) | CHECK >= 0 | Total sunshine duration in seconds |
| `dly_temperature_2m_max_celsius` | NUMERIC(5,2) | | Max temperature at 2m in °C |
| `dly_temperature_2m_min_celsius` | NUMERIC(5,2) | | Min temperature at 2m in °C |
| `dly_temperature_2m_mean_celsius` | NUMERIC(5,2) | | Mean temperature at 2m in °C |
| `dly_apparent_temperature_max_celsius` | NUMERIC(5,2) | | Max feels-like temp in °C |
| `dly_apparent_temperature_min_celsius` | NUMERIC(5,2) | | Min feels-like temp in °C |
| `dly_apparent_temperature_mean_celsius` | NUMERIC(5,2) | | Mean feels-like temp in °C |
| `dly_wind_gusts_10m_max_kmh` | NUMERIC(10,2) | | Max wind gusts at 10m in km/h |
| `dly_wind_gusts_10m_min_kmh` | NUMERIC(10,2) | | Min wind gusts at 10m in km/h |
| `dly_wind_gusts_10m_mean_kmh` | NUMERIC(10,2) | | Mean wind gusts at 10m in km/h |
| `dly_wind_speed_10m_max_kmh` | NUMERIC(10,2) | | Max wind speed at 10m in km/h |
| `dly_wind_speed_10m_min_kmh` | NUMERIC(10,2) | | Min wind speed at 10m in km/h |
| `dly_wind_speed_10m_mean_kmh` | NUMERIC(10,2) | | Mean wind speed at 10m in km/h |
| `dly_wind_direction_10m_dominant` | INT | | Dominant wind direction in degrees |
| `dly_surface_pressure_max_hpa` | NUMERIC(10,2) | | Max surface pressure in hPa |
| `dly_surface_pressure_min_hpa` | NUMERIC(10,2) | | Min surface pressure in hPa |
| `dly_surface_pressure_mean_hpa` | NUMERIC(10,2) | | Mean surface pressure in hPa |
| `dly_relative_humidity_2m_max_pct` | INT | CHECK 0–100 | Max relative humidity at 2m % |
| `dly_relative_humidity_2m_min_pct` | INT | CHECK 0–100 | Min relative humidity at 2m % |
| `dly_relative_humidity_2m_mean_pct` | INT | CHECK 0–100 | Mean relative humidity at 2m % |

**Primary Key:** `(mtn_id, dly_time)`

---

### `silver.openmeteo_hourly`
Hourly weather forecast data per mountain sourced from the Open-Meteo API. One row per mountain per forecast hour.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `mtn_id` | INT | NOT NULL, FK → wiki_mtns | Mountain identifier |
| `measured_at_m` | INT | | Elevation at which forecast is measured |
| `pulled_at` | TIMESTAMPTZ | | Ingestion timestamp (MT) |
| `hrly_time` | TIMESTAMP | NOT NULL | Forecast hour timestamp |
| `hrly_weather_code` | INT | FK → weathercodes | WMO weather code |
| `hrly_rain_mm` | NUMERIC(10,2) | CHECK >= 0 | Rain in mm |
| `hrly_showers_mm` | NUMERIC(10,2) | CHECK >= 0 | Showers in mm |
| `hrly_snowfall_cm` | NUMERIC(10,2) | CHECK >= 0 | Snowfall in cm |
| `hrly_snow_depth_m` | NUMERIC(10,2) | CHECK >= 0 | Snow depth in meters |
| `hrly_precipitation_mm` | NUMERIC(10,2) | CHECK >= 0 | Total precipitation in mm |
| `hrly_precipitation_probability_pct` | INT | CHECK 0–100 | Precipitation probability % |
| `hrly_uv_index` | NUMERIC(5,2) | | UV index |
| `hrly_is_day` | INT | | 1 = daytime, 0 = nighttime |
| `hrly_visibility_m` | NUMERIC(10,2) | | Visibility in meters |
| `hrly_cloud_cover_pct` | INT | CHECK 0–100 | Cloud cover % |
| `hrly_dew_point_2m_celsius` | NUMERIC(5,2) | | Dew point at 2m in °C |
| `hrly_temperature_2m_celsius` | NUMERIC(5,2) | | Temperature at 2m in °C |
| `hrly_apparent_temperature_celsius` | NUMERIC(5,2) | | Feels-like temperature in °C |
| `hrly_relative_humidity_2m_pct` | INT | CHECK 0–100 | Relative humidity at 2m % |
| `hrly_wind_gusts_10m_kmh` | NUMERIC(10,2) | | Wind gusts at 10m in km/h |
| `hrly_wind_speed_10m_kmh` | NUMERIC(10,2) | | Wind speed at 10m in km/h |
| `hrly_wind_speed_80m_kmh` | NUMERIC(10,2) | | Wind speed at 80m in km/h |
| `hrly_wind_direction_10m` | INT | | Wind direction at 10m in degrees |
| `hrly_wind_direction_80m` | INT | | Wind direction at 80m in degrees |
| `hrly_surface_pressure_hpa` | NUMERIC(10,2) | | Surface pressure in hPa |
| `hrly_sunshine_duration_seconds` | NUMERIC(10,2) | | Sunshine duration in seconds |
| `hrly_freezing_level_height_m` | NUMERIC(10,2) | | Freezing level height in meters |

**Primary Key:** `(mtn_id, hrly_time)`

---

### `silver.openmeteo_lightning`
Hourly lightning potential data per mountain, aggregated from 15-minute interval bronze data. One row per mountain per hour.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `mtn_id` | INT | NOT NULL, FK → wiki_mtns | Mountain identifier |
| `measured_at_m` | INT | | Elevation at which forecast is measured |
| `pulled_at` | TIMESTAMPTZ | | Ingestion timestamp (MT) |
| `ltng_time` | TIMESTAMP | NOT NULL | Forecast hour timestamp |
| `ltng_potential_j_kg_max` | NUMERIC(10,2) | | Max lightning potential in J/kg for the hour |
| `ltng_potential_j_kg_mean` | NUMERIC(10,2) | | Mean lightning potential in J/kg for the hour |

**Primary Key:** `(mtn_id, ltng_time)`

---

## Relationships

```
silver.wiki_mtns (mtn_id)
    ├── silver.openweather_alerts (mtn_id)
    ├── silver.openmeteo_daily (mtn_id)
    ├── silver.openmeteo_hourly (mtn_id)
    └── silver.openmeteo_lightning (mtn_id)

silver.weathercodes (weather_code)
    ├── silver.openmeteo_daily (dly_weather_code)
    └── silver.openmeteo_hourly (hrly_weather_code)
```
