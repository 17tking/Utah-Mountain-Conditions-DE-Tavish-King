from airflow import DAG
from airflow.operators.python import PythonOperator
from datetime import datetime
import psycopg2
import os
from dotenv import load_dotenv

load_dotenv()

def query_postgres():
    conn = psycopg2.connect(
        host=os.getenv("DB_HOST"),
        port=os.getenv("DB_PORT"),
        dbname=os.getenv("DB_NAME"),
        user=os.getenv("DB_USER"),
        password=os.getenv("DB_PASSWORD")
    )
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM bronze.raw_weather LIMIT 5;")
    rows = cursor.fetchall()
    for row in rows:
        print(row)
    cursor.close()
    conn.close()

with DAG(
    dag_id="postgres_query_test",
    start_date=datetime(2024, 1, 1),
    schedule=None,
    catchup=False
) as dag:

    run_query = PythonOperator(
        task_id="query_postgres",
        python_callable=query_postgres
    )
