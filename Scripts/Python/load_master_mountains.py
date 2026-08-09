import pandas as pd
import psycopg2
import psycopg2.extras as extras
from psycopg2 import sql
from bs4 import BeautifulSoup
#import requests
#import re
import os
#import time
from dotenv import load_dotenv

# ============================================================
# This script loads the master_mountains.csv file
# into the bronze.mountains_stg PostgreSQL table.
#
# This script is a part of 'mountain_conditions_dag.py'. It is ran
# before the SQL script 'load_mountains_silver.sql'.
#  
# The table is truncated and reloaded each run to stay current with
# any corrections to the source data.
#
# ============================================================


# -----------
# Load
# -----------
def load_mountains(master_mountains):
    print("=" * 50)
    print(">> Loading mountain data into bronze.mountains_stg...")
    print("=" * 50)

    conn = psycopg2.connect(
        dbname=os.getenv('DB_NAME'),
        user=os.getenv('DB_USERNAME'),
        password=os.getenv('DB_PASSWORD'),
        host=os.getenv('DB_HOST'),
        port=os.getenv('DB_PORT')
    )
    cur = conn.cursor()

    try:
        # Truncate first to avoid duplicates on re-runs
        cur.execute("TRUNCATE TABLE bronze.mountains_stg CASCADE;")

        # Build INSERT using psycopg2.sql to avoid f-string SQL injection risk
        columns = sql.SQL(", ").join(sql.Identifier(c) for c in master_mountains.columns)
        insert_query = sql.SQL(
            "INSERT INTO bronze.mountains_stg ({columns}) VALUES %s"
        ).format(columns=columns)

        rows = [tuple(row) for row in master_mountains.itertuples(index=False, name=None)]
        extras.execute_values(cur, insert_query, rows)
        conn.commit()
        print(f"Hallelujah! {len(master_mountains)} rows inserted into bronze.mountains_stg.")

    except Exception as e:
        conn.rollback()
        print(f"Error loading data: {e}")
        raise
    finally:
        cur.close()
        conn.close()


# -------
# Main
# -------
def main():
    load_dotenv()

    # Read the master CSV
    print("=" * 50)
    print(">> Reading master_mountains.csv...")
    print("=" * 50)

    master_mountains = pd.read_csv('/opt/airflow/master_mountains.csv')
    print(f"Loaded {len(master_mountains)} rows from CSV.")

    # load into database
    load_mountains(master_mountains)

    print("=" * 50)
    print(">> Done.")
    print("=" * 50)


if __name__ == "__main__":
    main()