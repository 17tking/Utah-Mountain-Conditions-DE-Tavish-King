from airflow import DAG
from airflow.operators.python import PythonOperator
from datetime import datetime
import psycopg2
import os
from dotenv import load_dotenv

load_dotenv()

def extract():
    print("Extracting data from API...")
    # your API call logic goes here

def load_to_bronze():
    conn = psycopg2.connect(
        host=os.getenv("DB_HOST"),
        port=os.getenv("DB_PORT"),
        dbname=os.getenv("DB_NAME"),
        user=os.getenv("DB_USER"),
        password=os.getenv("DB_PASSWORD")
    )
    cursor = conn.cursor()
    # your insert logic goes here
    conn.commit()
    cursor.close()
    conn.close()
    print("Loaded to bronze layer")

def transform_to_silver():
    conn = psycopg2.connect(
        host=os.getenv("DB_HOST"),
        port=os.getenv("DB_PORT"),
        dbname=os.getenv("DB_NAME"),
        user=os.getenv("DB_USER"),
        password=os.getenv("DB_PASSWORD")
    )
    cursor = conn.cursor()
    # your silver transform SQL goes here
    conn.commit()
    cursor.close()
    conn.close()
    print("Transformed to silver layer")

with DAG(
    dag_id="utah_mountain_pipeline",
    start_date=datetime(2024, 1, 1),
    schedule="@hourly",
    catchup=False
) as dag:

    extract_task = PythonOperator(
        task_id="extract",
        python_callable=extract
    )

    bronze_task = PythonOperator(
        task_id="load_to_bronze",
        python_callable=load_to_bronze
    )

    silver_task = PythonOperator(
        task_id="transform_to_silver",
        python_callable=transform_to_silver
    )

    # dependency chain: extract -> bronze -> silver
    extract_task >> bronze_task >> silver_task
