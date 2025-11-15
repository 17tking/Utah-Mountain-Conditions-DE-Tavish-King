import pandas as pd
import psycopg2
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