import pandas as pd
import psycopg2
import psycopg2.extras as extras
from dotenv import load_dotenv
import os

# ======================================
# This script loads clean_mtns into PostgreSQL
# bronze layer (schema = bronze).
# ======================================
clean_mtns = pd.read_csv("Wiki Data/clean_mtns.csv")

# -----------------
# Loading into SQL
# -----------------
load_dotenv()
# PostgreSQL connection info
conn = psycopg2.connect(
    dbname=os.getenv('database'),
    user=os.getenv('user'),
    password=os.getenv('password'),
    host=os.getenv('host'),
    port=os.getenv('port')
)
cur = conn.cursor()
print("========================")
print("Connected to PostgreSQL!")
print("========================")

# ---------------------------------------------------------
# Truncate table first to avoid duplicates
# ---------------------------------------------------------
try:
    cur.execute("TRUNCATE TABLE bronze.wiki_mtns;")
    conn.commit()
    print("Table truncated successfully.")
except Exception as e:
    conn.rollback()
    print("Error truncating table:", e)

# ---------------------------------
# Prepping data for execute_values
# ---------------------------------
rows = [tuple(row) for row in clean_mtns.to_numpy()]
columns = ",".join(clean_mtns.columns)

query = f"""
    INSERT INTO bronze.wiki_mtns ({columns})
    VALUES %s
"""

# --------------------
# Execute bulk insert
# --------------------
try:
    extras.execute_values(cur, query, rows)
    conn.commit()
    print(f"Hallelujah! {len(clean_mtns)} rows inserted into bronze.wiki_mtns.")
except Exception as e:
    conn.rollback()
    print("- Error inserting rows:", e)

# ---------
# Clean-up
# ---------
cur.close()
conn.close()
print("=======")
print(" Done. ")
print("=======")