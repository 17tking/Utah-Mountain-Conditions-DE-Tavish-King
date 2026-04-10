from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.providers.postgres.hooks.postgres import PostgresHook
from datetime import datetime

def test_connection():
    hook = PostgresHook(postgres_conn_id="utahmountains_db")
    conn = hook.get_conn()
    cursor = conn.cursor()
    cursor.execute("SELECT mtn_name FROM silver.wiki_mtns WHERE mtn_id = 1;")
    result = cursor.fetchone()
    print(f"Connection successful: {result}")
    conn.close()

with DAG(
    dag_id="test_db_connection",
    start_date=datetime(2024, 1, 1),
    schedule=None,
    catchup=False,
) as dag:
    test_task = PythonOperator(
        task_id="test_connection",
        python_callable=test_connection,
    )