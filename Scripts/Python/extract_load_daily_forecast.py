import psycopg2
from psycopg2.extras import execute_values
from datetime import timezone, datetime
from dotenv import load_dotenv
import os
import json
import time
import copy
from utils import get_summits, log_api_call, call_api_with_retry, generate_id  # custom function to retrieve summits list
 
# ===============================================================================================
# This script extracts daily weather forecasts for all summits listed from the Open-Meteo API.
# It stores the raw JSON response along with basic metadata (latitude, longitude, elevation)
# in the `bronze.daily_stg` PostgreSQL table.
#
# This script is intended to run daily @ 1am to maintain up-to-date forecast data.
# =================================================================================================
 
 
def main():
    start_time = time.time()
 
    load_dotenv()
 
    # -----------------------
    # Open-Meteo API Setup
    # -----------------------
    meteo_url = "https://api.open-meteo.com/v1/forecast"
 
    # Base parameters for daily forecast. Latitude and longitude will be set per summit.
    daily_params = {
        "latitude": None,
        "longitude": None,
        "daily": [
            "weather_code", "temperature_2m_max", "temperature_2m_min",
            "apparent_temperature_max", "apparent_temperature_min",
            "sunrise", "sunset", "daylight_duration", "sunshine_duration",
            "uv_index_max", "rain_sum", "showers_sum", "snowfall_sum",
            "precipitation_sum", "precipitation_probability_max",
            "wind_speed_10m_max", "wind_gusts_10m_max",
            "wind_direction_10m_dominant", "precipitation_hours",
            "precipitation_probability_min", "wind_speed_10m_min",
            "wind_gusts_10m_min", "cloud_cover_max", "cloud_cover_min",
            "relative_humidity_2m_min", "relative_humidity_2m_max",
            "temperature_2m_mean", "apparent_temperature_mean",
            "visibility_min", "visibility_max", "surface_pressure_mean",
            "cloud_cover_mean", "precipitation_probability_mean",
            "relative_humidity_2m_mean", "surface_pressure_min",
            "surface_pressure_max", "visibility_mean",
            "wind_gusts_10m_mean", "wind_speed_10m_mean",
            "dew_point_2m_mean", "dew_point_2m_max", "dew_point_2m_min"
        ],
        "models": "best_match",
        "timezone": "auto",
        "forecast_days": 7
    }
 
    # ------------------
    # Retrieve Summits
    # ------------------
    summits = get_summits()
    rows = []
    failed_summits = []
 
    # ------------------------------
    # API Loop and Data Extraction
    # ------------------------------
    print("=" * 50)
    print(f">> Extracting Daily Forecast data from OpenMeteo...")
    print("=" * 50)
 
    for s in summits:
        # Deep copy base params so each summit has its own lat/lon
        # and the shared "daily" list is not mutated
        params = copy.deepcopy(daily_params)
        params["latitude"] = s["mountain_latitude"]
        params["longitude"] = s["mountain_longitude"]
 
        # Make request to Open-Meteo API
        start = time.time()
        r = call_api_with_retry(meteo_url, params)
        elapsed_ms = round((time.time() - start) * 1000)
        time.sleep(5)
 
        log_api_call(
            source='openmeteo',
            endpoint=meteo_url,
            mountain_id=s['mountain_id'],
            status_code=r.status_code,
            response_time=elapsed_ms,
            success=r.status_code == 200
        )
        
        if r is None or r.status_code != 200:
            print(f"Failed for summit mountain_id={s['mountain_id']} — status {r.status_code}")
            print(f"Response: {r.text}")
            failed_summits.append(s["mountain_id"])
            continue

        # Generate ID for daily_id field
        daily_id = generate_id()

        # Parse JSON response
        daily_json = r.json()
 
        # Extract basic metadata for convenience
        daily_latitude = daily_json.get("latitude")
        daily_longitude = daily_json.get("longitude")
        measured_at = daily_json.get("elevation")
 
        # Record ingestion time in UTC
        create_date = datetime.now(timezone.utc).isoformat()
 
        # Append as tuple for batch insert
        # Note: raw_json must be serialized to JSON string for PostgreSQL JSONB column
        rows.append((
            daily_id,
            s["mountain_id"],
            daily_latitude,
            daily_longitude,
            measured_at,
            create_date,
            json.dumps(daily_json)
        ))
 
    # ------------------------------------
    # Insert into PostgreSQL Bronze Table
    # ------------------------------------
    insert_daily_query = """
        INSERT INTO bronze.daily_stg (
            daily_id,
            mountain_id,
            daily_latitude,
            daily_longitude,
            measured_at,
            create_date,
            daily_json
        ) VALUES %s
    """
 
    conn = psycopg2.connect(
        dbname=os.getenv('DB_NAME'),
        user=os.getenv('DB_USERNAME'),
        password=os.getenv('DB_PASSWORD'),
        host=os.getenv('DB_HOST'),
        port=os.getenv('DB_PORT')
    )
    cur = conn.cursor()
 
    try:
        execute_values(cur, insert_daily_query, rows)
        conn.commit()
        print(f"Yeehaw! {cur.rowcount} rows inserted into bronze.daily_stg")
    except Exception as e:
        conn.rollback()
        print("=" * 50)
        print("ERROR OCCURRED DURING DAILY FORECAST INSERT")
        print(f"Error Message: {str(e)}")
        print(f"Error Type: {type(e).__name__}")
        print("=" * 50)
        raise
    finally:
        cur.close()
        conn.close()
 
    # Raise after DB work is done so partial failures don't get swallowed
    if failed_summits:
        raise RuntimeError(f"API calls failed for {len(failed_summits)} summit(s): {failed_summits}")
 
    end_time = time.time()
    print("-" * 50)
    print(f">> Load Duration: {round(end_time - start_time, 2)} secs")
    print("-" * 50)
 
 
if __name__ == "__main__":
    main()