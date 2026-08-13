import os
import psycopg2
from dotenv import load_dotenv
from utils import generate_id

load_dotenv()


def get_conn():
    return psycopg2.connect(
        host=os.getenv("localhost"),
        dbname=os.getenv("DB_NAME"),
        user=os.getenv("DB_USERNAME"),
        password=os.getenv("DB_PASSWORD"),
        port=os.getenv("DB_PORT")
    )


def populate_ids():
    conn = get_conn()

    try:
        with conn.cursor() as cur:

            # Get all existing rows that don't have an ID
            cur.execute("""
                SELECT mountain_id, alert_event, alert_start, alert_end
                FROM silver.alerts
                WHERE alert_id IS NULL;
            """)

            rows = cur.fetchall()

            print(f"Found {len(rows)} rows missing alert_id")

            for mountain_id, alert_event, alert_start, alert_end in rows:

                new_id = generate_id()

                cur.execute("""
                    UPDATE silver.alerts
                    SET alert_id = %s
                    WHERE mountain_id = %s
                      AND alert_event = %s
                      AND alert_start = %s
                      AND alert_end = %s
                      AND alert_id IS NULL;
                """, (
                    new_id,
                    mountain_id,
                    alert_event,
                    alert_start,
                    alert_end
                ))

        conn.commit()

        print(f"Successfully populated {len(rows)} alert_ids")

    except Exception:
        conn.rollback()
        raise

    finally:
        conn.close()


if __name__ == "__main__":
    populate_ids()