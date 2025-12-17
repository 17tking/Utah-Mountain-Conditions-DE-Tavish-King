import json
import os
import psycopg2
from psycopg2.extras import execute_values
from dotenv import load_dotenv

# ===============================================================================================
# This script is making a reference table of weather codes and their description and image. The
# raw json is loaded directly into the Silver layer of the 'utahmountains' database. 
#
# Note: If this is accidentally ran a second time, constraints are in place to ensure duplicates
#       are not inserted.
# ===============================================================================================
load_dotenv()

try:
# Connecting to SQL database
    conn = psycopg2.connect(
            host=os.getenv("host"),
            dbname=os.getenv("database"),
            user=os.getenv("user"),
            password=os.getenv("password"),
            port=os.getenv("port")
        )
    cur = conn.cursor()

    # Pulling weathercode data from WikiData folder
    with open("Wiki Data/descriptions.json", "r", encoding="utf-8") as f:
        weathercodes = json.load(f)

    rows = []

    for code, tod_data in weathercodes.items():
        weather_code = int(code)

        for time_of_day, values in tod_data.items():
            rows.append((
                weather_code,
                time_of_day,
                values["description"],
                values["image"]
            ))

    # ------------------------------------
    # Insert into PostgreSQL Bronze Table
    # ------------------------------------
    insert_weathercodes_query = """
        INSERT INTO silver.weathercodes (
        weather_code,
        time_of_day,
        description,
        image_url
        ) 
        VALUES %s;
        """
    with conn:
        with conn.cursor() as cur:
            execute_values(cur, insert_weathercodes_query, rows)

    conn.close()
    print(f"ZAM! Inserted {len(rows)} weather code rows into the Silver layer.")

except Exception as e:
    print("=" * 60)
    print("ERROR OCCURRED DURING WEATHERCODE INGEST")
    print(f"Error Message: {str(e)}")
    print(f"Error Type: {type(e).__name__}")
    print("=" * 60)