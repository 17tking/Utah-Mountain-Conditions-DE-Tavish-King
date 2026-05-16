from airflow import DAG
from airflow.operators.bash import BashOperator
from datetime import datetime, timedelta
#from airflow.models import Variable
import pendulum

# ===============================================================================================
# This DAG runs all ETL python scripts as tasks. 
# Extracts weather data from OpenMeteo & OpenWeather APIs, transforms to silver layer
# Schedule: Daily @ 1am MDT
# Retries: 2 attempts with 5-minute delay
#   > note: scripts already contain 3 retries with delays between each mtn_id call
#   > 5-minute delay is to prevent calling API too hard
# =================================================================================================

local_tz = pendulum.timezone("America/Denver")
etl_path = "/opt/airflow/scripts/Python"

default_args = {
    'owner': 'tavish',
    'retries': 2,
    'retry_delay': timedelta(minutes=5),
    'email_on_failure': False, 
    'email_on_retry': False,
    #'email': [Variable.get('email')] # added email var to airflow admin
}


with DAG(
    dag_id="mtn_conditions_pipeline",
    default_args=default_args,
    description="ETL pipeline for Utah mountain weather conditions",
    start_date=datetime(2025, 1, 1, tzinfo=local_tz),
    schedule="0 1 * * *", #1am daily in cron format
    catchup=False,
    tags=['weather', 'etl', 'mountains']
) as dag:
    

    # EXTRACT & LOAD TO BRONZE
    openmeteo_daily_task = BashOperator(
        task_id="om_daily_etl",
        bash_command=f'python "{etl_path}/extract_load_openmeteo_daily_forecast.py"'
    )

    openmeteo_hourly_task = BashOperator(
        task_id="om_hourly_etl",
        bash_command=f'python "{etl_path}/extract_load_openmeteo_hour_forecast.py"'
    )

    openmeteo_lightning_task = BashOperator(
        task_id="om_ltng_etl",
        bash_command=f'python "{etl_path}/extract_load_openmeteo_lightning_forecast.py"'
    )

    openweather_alerts_task = BashOperator(
        task_id="ow_alerts_etl",
        bash_command=f'python "{etl_path}/extract_load_openweather_alerts.py"'
    )

    # LOAD/TRANSFORM TO SILVER LAYER
    load_daily_task = BashOperator(
        task_id="load_daily_silver",
        bash_command='psql -h host.docker.internal -U tavishk17 -d utahmountains -f "/opt/airflow/scripts/SQL/Silver/load_om_daily_silver.sql"',
        env={'PGPASSWORD': '{{ var.value.password }}'}
    )
    
    load_hourly_task = BashOperator(
        task_id="load_hourly_silver",
        bash_command='psql -h host.docker.internal -U tavishk17 -d utahmountains -f "/opt/airflow/scripts/SQL/Silver/load_om_hourly_silver.sql"',
        env={'PGPASSWORD': '{{ var.value.password }}'}
    )

    load_lightning_task = BashOperator(
        task_id="load_ltng_silver",
        bash_command='psql -h host.docker.internal -U tavishk17 -d utahmountains -f "/opt/airflow/scripts/SQL/Silver/load_om_lightning_silver.sql"',
        env={'PGPASSWORD': '{{ var.value.password }}'}
    )

    load_alerts_task = BashOperator(
        task_id="load_alerts_silver",
        bash_command='psql -h host.docker.internal -U tavishk17 -d utahmountains -f "/opt/airflow/scripts/SQL/Silver/load_ow_alerts_silver.sql"',
        env={'PGPASSWORD': '{{ var.value.password }}'}
    )

    # ====================
    # TASK DEPENDENCIES
    # ====================

    # Run Bronze tasks sequentially (prevent hitting the API too hard)
    openmeteo_daily_task >> openmeteo_hourly_task >> openmeteo_lightning_task >> openweather_alerts_task
    
    # After all bronze loads complete, silver transforms run in parallel
    openweather_alerts_task >> [
        load_daily_task,
        load_hourly_task,
        load_lightning_task,
        load_alerts_task,
    ]
    

