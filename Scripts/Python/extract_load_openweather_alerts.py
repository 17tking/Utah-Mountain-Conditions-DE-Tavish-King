import requests
import psycopg2
from psycopg2.extras import execute_values
import json
from datetime import timezone, datetime
import time
import os
from dotenv import load_dotenv
from utils import get_summits

# ===============================================================
# This script extracts daily weather alerts for all summits listed
# in the wiki_mtns table using the OpenWeather One Call3.0 API.
#
# It stores the raw alert data in the bronze.alerts PostgreSQL table
# as JSONB, ensuring no duplicates via a unique index on (mtn_id,
# event, start, end). 
# 
# The script also handles incremental loading (1x daily) and
# timestamps each pull for tracking purposes.
# ===============================================================
load_dotenv()

# Open weather api key
OW_KEY = os.getenv('owkey')

# ------------
# API Caller
# ------------
def fetch_alerts(latitude, longitude):
    ow_url = (
        f"https://api.openweathermap.org/data/3.0/onecall?"
        f"lat={latitude}&lon={longitude}&exclude=current,minutely,hourly,daily&appid={OW_KEY}"
    )

    try:
        r = requests.get(ow_url, timeout=10)
        r.raise_for_status()
        alert_data = r.json()
    except Exception as e:
        print(f"API error for ({latitude}, {longitude}): {e}")
        return []
    
    alerts = alert_data.get("alerts") or []
    return alerts

# -----------------------------
# Loops through all 50 summits
# -----------------------------
def extract_all_summits():
    results = []
    summits = get_summits()

    for s in summits:
        alerts = fetch_alerts(s["latitude"], s["longitude"])
        pulled_at = datetime.now(timezone.utc).isoformat() #timezone aware + ISO string

        for a in alerts:
            results.append({
                "mtn_id": s["mtn_id"],
                "latitude": float(s["latitude"]),
                "longitude": float(s["longitude"]),
                "pulled_at": pulled_at,
                "alert": a #raw json object (bronze layer)
            })

        # API buffer
        time.sleep(0.5)

    return results

# -----------------------------------------
# Loading raw json alert data to postgreSQL
# -----------------------------------------

def load_alerts_to_postgres(results):
    if not results:
        print("No alerts to load.")
        return
    
    conn = psycopg2.connect(
        dbname=os.getenv('database'),
        user=os.getenv('user'),
        password=os.getenv('password'),
        host=os.getenv('host'),
        port=os.getenv('port')
    )
    cur = conn.cursor()

    insert_alerts_query = """
        insert into bronze.openweather_alerts (mtn_id, latitude, longitude, pulled_at, alert)
        values %s
        on conflict do nothing;
"""

    # Preparing data for execute values
    values = [
        (
            r["mtn_id"],
            r["latitude"],
            r["longitude"],
            r["pulled_at"],
            json.dumps(r["alert"])
        )
        for r in results
    ]

    try:
        execute_values(cur, insert_alerts_query, values)
        conn.commit()
        print(f"Sick! {cur.rowcount} new alerts inserted into bronze.openweather_alerts")
    except Exception as e:
        conn.rollback()
        print(f"Error inserting alerts: {e}")
    finally:
        cur.close()
        conn.close()


# -------
# Main
# -------
if __name__ == "__main__":
    start_time = time.time()
    print("=" * 50)
    print(f">> Extracting Alert data from OpenWeather...")
    print("=" * 50)
    results = extract_all_summits()
    print("=" * 50)
    print(f">> Fetched {len(results)} alerts.")
    print("=" * 50)
    load_alerts_to_postgres(results)
    print("=" * 50)
    end_time = time.time()
    print(f">> Load Duration: {round(end_time - start_time, 2)} secs")
