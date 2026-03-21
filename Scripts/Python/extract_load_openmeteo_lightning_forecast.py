import requests
import psycopg2
from psycopg2.extras import execute_values
from datetime import timezone, datetime
from dotenv import load_dotenv
import os
import json
import time
import copy
from utils import get_summits, log_api_call  # custom function to retrieve summits list

# ===============================================================================================
# This script extracts 15-minutely lightning potential (LPI) forecasts for all summits listed from the Open-Meteo API.
# It stores the raw JSON response along with basic metadata (latitude, longitude, elevation, timezone)
# in the `bronze.openmeteo_lightning` PostgreSQL table.
# 
# This script is intended to run 23x/day starting at @ 12am and ending at 11pm to maintain 
# up-to-date hourly forecast data.
# =================================================================================================
 
 
def main():
    start_time = time.time()
 
    load_dotenv()
 
    # -----------------------
    # Open-Meteo API Setup
    # -----------------------
    meteo_url = "https://api.open-meteo.com/v1/forecast"
 
    # Base parameters for lightning forecast. Latitude and longitude will be set per summit.
    base_params = {
        "latitude": None,
        "longitude": None,
        "models": "best_match",
        "minutely_15": "lightning_potential",
        "timezone": "auto",
        "forecast_days": 1,
        "forecast_minutely_15": 96,
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
    print(f">> Extracting Lightning Forecast data from OpenMeteo...")
    print("=" * 50)
 
    for s in summits:
        # Deep copy base params so each summit has its own lat/lon
        params = copy.deepcopy(base_params)
        params["latitude"] = s["latitude"]
        params["longitude"] = s["longitude"]
 
        # Make request to Open-Meteo API
        
        start = time.time()
        r = requests.get(meteo_url, params=params, timeout=10)
        elapsed_ms = round((time.time() - start) * 1000)
        time.sleep(1)
 
        log_api_call(
            api_source='openmeteo',
            endpoint=meteo_url,
            mtn_id=s['mtn_id'],
            status_code=r.status_code,
            response_ms=elapsed_ms,
            success=r.status_code == 200
        )
        
        if r.status_code != 200:
            print(f"Failed for summit mtn_id={s['mtn_id']} — status {r.status_code}")
            failed_summits.append(s["mtn_id"])
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
    print("=" * 60)
    print(f">> Inserting Lightning Forecast data into bronze.openmeteo_lightning...")
    print("=" * 60)
 
    insert_lightning_query = """
        INSERT INTO bronze.openmeteo_lightning (
            mtn_id,
            latitude,
            longitude,
            elevation,
            timezone,
            timezone_abbreviation,
            utc_offset_seconds,
            pulled_at,
            lightning_forecast
        ) VALUES %s
    """
 
    conn = psycopg2.connect(
        host=os.getenv("host"),
        dbname=os.getenv("database"),
        user=os.getenv("user"),
        password=os.getenv("password"),
        port=os.getenv("port")
    )
    cur = conn.cursor()
 
    try:
        execute_values(cur, insert_lightning_query, rows)
        conn.commit()
        print(f"Bullseye! {cur.rowcount} rows inserted into bronze.openmeteo_lightning")
    except Exception as e:
        conn.rollback()
        print("=" * 60)
        print("ERROR OCCURRED DURING LIGHTNING INGEST")
        print(f"Error Message: {str(e)}")
        print(f"Error Type: {type(e).__name__}")
        print("=" * 60)
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