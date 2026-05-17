from airflow import DAG
from airflow.operators.python import PythonOperator
from datetime import datetime, timezone

import requests
import os
import psycopg2
from dotenv import load_dotenv
import pendulum

load_dotenv()

local_tz = pendulum.timezone("America/Denver")
ENDPOINT_URL = "http://airflow-apiserver:8080"


# --- Airflow REST API ---
def get_token():
    resp = requests.post(
        f"{ENDPOINT_URL}/auth/token",
        json={
            "username": os.getenv("USERNAME_AIRFLOW_INSTANCE"),
            "password": os.getenv("PASSWORD_AIRFLOW_INSTANCE")
        }
    )
    resp.raise_for_status()
    return resp.json()["access_token"]


def fetch_task_instances(token):
    headers = {"Authorization": f"Bearer {token}"}


    resp = requests.get(
        f"{ENDPOINT_URL}/api/v2/dags/~/dagRuns/~/taskInstances",
        headers=headers,
        params={
            "limit": 10000,
            "order_by": "-start_date"
        }
    )
    resp.raise_for_status()

    fields = [
        "task_id", "dag_id", "dag_run_id", "state",
        "start_date", "end_date", "duration",
        "try_number", "operator_name"
    ]

    task_instances = resp.json().get("task_instances", [])
    
    print(f"API returned {len(task_instances)} total task instances")
    if task_instances:
        print(f"Most recent: {task_instances[0].get('start_date')}")
        print(f"Oldest: {task_instances[-1].get('start_date')}")
    
    return [
        {k: ti[k] for k in fields}
        for ti in task_instances
    ]


# --- Postgres ---
def get_conn():
    return psycopg2.connect(
        host=os.getenv("DB_HOST"),
        dbname=os.getenv("DB_NAME"),
        user=os.getenv("DB_USERNAME"),
        password=os.getenv("DB_PASSWORD"),
        port=os.getenv("DB_PORT")
    )


def run_load_task_instances():
    sql = """
        INSERT INTO meta.task_instances (
            task_id, dag_id, dag_run_id, state,
            start_date, end_date, duration,
            try_number, operator_name
        )
        VALUES (
            %(task_id)s, %(dag_id)s, %(dag_run_id)s, %(state)s,
            %(start_date)s, %(end_date)s, %(duration)s,
            %(try_number)s, %(operator_name)s
        )
        ON CONFLICT (dag_id, dag_run_id, task_id)
        DO UPDATE SET
            state         = EXCLUDED.state,
            end_date      = EXCLUDED.end_date,
            duration      = EXCLUDED.duration,
            try_number    = EXCLUDED.try_number;
    """

    token = get_token()
    records = fetch_task_instances(token)

    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.executemany(sql, records)
        conn.commit()
        print(f"Loaded {len(records)} task instances into meta.task_instances")
    except Exception as e:
        conn.rollback()
        raise e
    finally:
        conn.close()

# DAG for load_task_instances
with DAG(
    dag_id="load_task_instances",
    schedule="0 4 * * *",
    start_date=datetime(2025, 1, 1, tzinfo=local_tz),
    catchup=False,
    tags=["meta"],
) as dag:

    load = PythonOperator(
        task_id="load_task_instances",
        python_callable=run_load_task_instances,
    )