from airflow import DAG
from airflow.operators.python import PythonOperator
from datetime import datetime
import psycopg2
import os
from dotenv import load_dotenv

load_dotenv()

def insert_record():
    conn = psycopg2.connect(
        host=os.getenv("DB_HOST"),
        port=os.getenv("DB_PORT"),
        dbname=os.getenv("DB_NAME"),
        user=os.getenv("DB_USER"),
        password=os.getenv("DB_PASSWORD")
    )
    cursor = conn.cursor()
    cursor.execute("""
        INSERT INTO bronze.raw_weather (peak_id, pulled_at, raw_payload)
        VALUES (%s, %s, %s)
    """, (1, datetime.utcnow(), '{"temp": 32, "wind": 10}'))
    conn.commit()
    print("Record inserted successfully")
    cursor.close()
    conn.close()

with DAG(
    dag_id="postgres_insert_test",
    start_date=datetime(2024, 1, 1),
    schedule=None,
    catchup=False
) as dag:

    insert_task = PythonOperator(
        task_id="insert_record",
        python_callable=insert_record
    )
