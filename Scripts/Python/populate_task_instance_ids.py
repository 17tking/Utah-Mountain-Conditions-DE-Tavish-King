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


def populate_task_instance_ids():
    conn = get_conn()

    try:
        with conn.cursor() as cur:

            # Get all existing rows that don't have an ID
            cur.execute("""
                SELECT dag_id, dag_run_id, task_id
                FROM meta.task_instances
                WHERE task_instance_id IS NULL;
            """)

            rows = cur.fetchall()

            print(f"Found {len(rows)} rows missing task_instance_id")

            for dag_id, dag_run_id, task_id in rows:

                new_id = generate_id()

                cur.execute("""
                    UPDATE meta.task_instances
                    SET task_instance_id = %s
                    WHERE dag_id = %s
                      AND dag_run_id = %s
                      AND task_id = %s
                      AND task_instance_id IS NULL;
                """, (
                    new_id,
                    dag_id,
                    dag_run_id,
                    task_id
                ))

        conn.commit()

        print(f"Successfully populated {len(rows)} task_instance_ids")

    except Exception:
        conn.rollback()
        raise

    finally:
        conn.close()


if __name__ == "__main__":
    populate_task_instance_ids()