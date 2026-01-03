import requests
import psycopg2
from psycopg2.extras import execute_values
from datetime import timezone, datetime
from dotenv import load_dotenv
import os
import json
import time
from utils import get_summits  # custom function to retrieve summits list

start_time = time.time()
# ===============================================================================================
# This script extracts on-the-hour weather forecasts for all summits listed from the Open-Meteo API.
# It stores the raw JSON response along with basic metadata (latitude, longitude, elevation, timezone)
# in the `bronze.openmeteo_hourly` PostgreSQL table.
# 
# This script is intended to run 23x/day starting at @ 1am and ending at 12am to maintain 
# up-to-date hourly forecast data.
# =================================================================================================
load_dotenv()

try:
    conn = psycopg2.connect(
        host=os.getenv("host"),
        dbname=os.getenv("database"),
        user=os.getenv("user"),
        password=os.getenv("password"),
        port=os.getenv("port")
    )
    cur = conn.cursor()

    # -----------------------
    # Open-Meteo API Setup
    # -----------------------
    meteo_url = "https://api.open-meteo.com/v1/forecast"

    # Base parameters for hourly forecast. Latitude and longitude will be set per summit.
    hourly_params = {
        "latitude": None,
    	"longitude": None,
    	"hourly": [
            "temperature_2m", "relative_humidity_2m", "dew_point_2m", "apparent_temperature", "precipitation_probability", "precipitation", "rain", "showers", "snowfall", "snow_depth", "weather_code", "surface_pressure", "cloud_cover", "visibility", "wind_speed_10m", "wind_speed_80m", "wind_direction_10m", "wind_direction_80m", "wind_gusts_10m", "uv_index", "is_day", "sunshine_duration", "freezing_level_height"
        ],
    	"models": "best_match",
    	"timezone": "auto",
        "forecast_days": 1
    }

    # ------------------
    # Retrieve Summits
    # ------------------
    summits = get_summits()
    rows = [] 

    # ------------------------------
    # API Loop and Data Extraction
    # ------------------------------
    print("=" * 50)
    print(f">> Extracting Hourly Forecast data from OpenMeteo...")
    print("=" * 50)

    for s in summits:
        # Copy base params so each summit has its own lat/lon
        hr_params = hourly_params.copy()
        hr_params["latitude"] = s["latitude"]
        hr_params["longitude"] = s["longitude"]

        # Make request to Open-Meteo API
        r = requests.get(meteo_url, params=hr_params)
        time.sleep(1)
        if r.status_code != 200:
            print(f"Failed for summit {s['name']}")
            continue

        # Parse JSON response
        raw_json = r.json()

        # Extract basic metadata for convenience
        latitude = raw_json.get("latitude")
        longitude = raw_json.get("longitude")
        elevation = raw_json.get("elevation")
        tz_name = raw_json.get("timezone")
        tz_abbrev = raw_json.get("timezone_abbreviation")
        utc_offset = raw_json.get("utc_offset_seconds")

        # Record ingestion time in UTC
        pulled_at = datetime.now(timezone.utc).isoformat()

        # Append as tuple for batch insert
        # Note: raw_json must be serialized to JSON string for PostgreSQL JSONB column
        rows.append((
            s["mtn_id"],
            latitude,
            longitude,
            elevation,
            tz_name,
            tz_abbrev,
            utc_offset,
            pulled_at,
            json.dumps(raw_json)
        ))

    # ------------------------------------
    # Insert into PostgreSQL Bronze Table
    # ------------------------------------
    insert_hourly_query = """
        INSERT INTO bronze.openmeteo_hourly (
            mtn_id,
            latitude,
            longitude,
            elevation,
            timezone,
            timezone_abbreviation,
            utc_offset_seconds,
            pulled_at,
            hourly_forecast
        ) VALUES %s
    """

    execute_values(cur, insert_hourly_query, rows)
    conn.commit()
    print(f"Kobe! {cur.rowcount} rows inserted into bronze.openmeteo_hourly")
    
    cur.close()
    conn.close()

except Exception as e:
    print("=" * 50)
    print("ERROR OCCURRED DURING HOURLY FORECAST INGEST")
    print(f"Error Message: {str(e)}")
    print(f"Error Type: {type(e).__name__}")
    print("=" * 50)

end_time = time.time()
print("-" * 50)
print(f">> Load Duration: {round(end_time - start_time, 2)} secs")
print("-" * 50)