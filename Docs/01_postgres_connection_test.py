from airflow import DAG
from airflow.operators.python import PythonOperator
from datetime import datetime
import psycopg2
from dotenv import load_dotenv
import os

load_dotenv()

def connect_to_postgres():
    conn = psycopg2.connect(
        host=os.getenv("DB_HOST"),
        port=os.getenv("DB_PORT"),
        dbname=os.getenv("DB_NAME"),
        user=os.getenv("DB_USER"),
        password=os.getenv("DB_PASSWORD")
    )
    cursor = conn.cursor()
    cursor.execute("SELECT current_database();")
    result = cursor.fetchone()
    print(f"Connected to: {result[0]}")
    cursor.close()
    conn.close()

with DAG(
    dag_id="postgres_connection_test",
    start_date=datetime(2024, 1, 1),
    schedule=None,
    catchup=False
) as dag:

    test_connection = PythonOperator(
        task_id="test_postgres_connection",
        python_callable=connect_to_postgres
    )
