import json
import os
import psycopg2
from psycopg2.extras import execute_values
from dotenv import load_dotenv

# ===============================================================================================
# This script loads a static weather code reference table directly into the Silver layer.
# Source: Wiki Data/descriptions.json
#
# This is a one-time load. Constraints on silver.weathercodes prevent duplicate inserts
# if accidentally re-run.
# ===============================================================================================

def main():
    load_dotenv()

    # Load weather code data from local JSON
    with open("weather_codes/descriptions.json", "r", encoding="utf-8") as f:
        weathercodes = json.load(f)

    rows = []
    for code, tod_data in weathercodes.items():
        weather_code = int(code)
        for time_of_day, values in tod_data.items():
            rows.append((
                weather_code,
                values["description"],
                values["image"]
            ))

    # ------------------------------------
    # Insert into PostgreSQL Silver Table
    # ------------------------------------
    insert_weathercodes_query = """
        INSERT INTO silver.weathercodes (
            weather_code,
            description,
            image_url
        )
        VALUES %s
        ON CONFLICT DO NOTHING
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
        execute_values(cur, insert_weathercodes_query, rows)
        conn.commit()
        print(f"ZAM! Inserted {len(rows)} weather code rows into silver.weathercodes.")
    except Exception as e:
        conn.rollback()
        print("=" * 60)
        print("ERROR OCCURRED DURING WEATHERCODE INGEST")
        print(f"Error Message: {str(e)}")
        print(f"Error Type: {type(e).__name__}")
        print("=" * 60)
        raise
    finally:
        cur.close()
        conn.close()


if __name__ == "__main__":
    main()