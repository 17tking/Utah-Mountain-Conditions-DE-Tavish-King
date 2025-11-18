import requests
import psycopg2
from psycopg2.extras import execute_values
import json
from datetime import timezone, datetime
import time
import os
from dotenv import load_dotenv

# ===============================================================
# This script extracts daily weather alerts for all summits listed
# in the wiki_mtns table using the OpenWeather One Call3.0 API.
#
# It stores the raw alert data in the bronze.alerts PostgreSQL table
# as JSONB, ensuring no duplicates via a unique index on (mtn_id,
# event, start, end). 
# 
# The script handles incremental loading (1x daily) and
# timestamps each pull for tracking purposes.
# ===============================================================
load_dotenv()

# Open weather api key
OW_KEY = os.getenv('owkey')


# -----------------------------------------
# Function to retrieve summit coordinates
# -----------------------------------------
def get_summits():
    conn = psycopg2.connect(
        dbname=os.getenv('database'),
        user=os.getenv('user'),
        password=os.getenv('password'),
        host=os.getenv('host'),
        port=os.getenv('port')
)
    cur = conn.cursor()

    query = """
        select mtn_id, latitude, longitude
        from bronze.wiki_mtns
        where latitude is not null
            and longitude is not null
    """

    cur.execute(query)
    rows = cur.fetchall()

    cur.close()
    conn.close()

    return [
        {"mtn_id": r[0], "latitude": float(r[1]), "longitude": float(r[2])}
        for r in rows
    ]


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
        time.sleep(0.3)

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
        insert into bronze.alerts (mtn_id, latitude, longitude, pulled_at, alert)
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
        print(f"Inserted {cur.rowcount} new alerts into bronze.alerts")
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
    results = extract_all_summits()
    print("============================================")
    print(f"Fetched {len(results)} alerts.")
    print("============================================")
    load_alerts_to_postgres(results)
    print("============================================")
