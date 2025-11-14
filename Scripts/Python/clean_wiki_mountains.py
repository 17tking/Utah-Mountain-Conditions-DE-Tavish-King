import pandas as pd
import re
import os
from dotenv import load_dotenv
import psycopg2

# ============================================================
# This script cleans raw_wiki_mountains entirely and loads it 
# into the PostgreSQL Bronze layer (schema = bronze).
#
# Why?
# - This data is very messy. It is easier to clean it in python.
#   Plus, it only has to be ingested & cleaned once.
# ==============================================================

# read in raw data
raw_mtns = pd.read_csv("Raw Wiki Data/raw_utah_mountains.csv")

# ---------------
# Cleaning Steps
# ---------------

# Standardizing column names
raw_mtns = raw_mtns.rename(columns = {'Rank':'rank', 'Mountain peak':'mtn_peak', 'Mountain range':'mtn_range'})

# Remove unnecessary chars from mountain_peak col
raw_mtns['mtn_peak'] = raw_mtns['mtn_peak'].str.replace(r'\[[^\]]*\]', '', regex=True).str.strip()

# Split elevation into ft and m
raw_mtns['elev_ft'] = raw_mtns['Elevation'].str.split(pat = 'ft').str[0].str.replace(',', '').str.strip()
raw_mtns['elev_m'] = raw_mtns['Elevation'].str.split(pat = 'ft').str[1].str.replace('m', '', regex=False).str.strip()


# Split prominence into ft and m
raw_mtns['prom_ft'] = raw_mtns['Prominence'].str.split(pat = 'ft').str[0].str.replace(',', '').str.strip()
raw_mtns['prom_m'] = raw_mtns['Prominence'].str.split(pat = 'ft').str[1].str.replace('m', '', regex=False).str.strip()


# Split isolation into mi and km
raw_mtns['isol_mi'] = raw_mtns['Isolation'].str.split(pat = 'mi').str[0].str.replace(',', '').str.strip()
raw_mtns['isol_km'] = raw_mtns['Isolation'].str.split(pat = 'mi').str[1].str.replace('km', '', regex=False).str.strip()

# Convert numeric columns to numbers
num_cols = ['elev_ft','elev_m','prom_ft','prom_m','isol_mi','isol_km']
raw_mtns[num_cols] = raw_mtns[num_cols].astype(float)

# Change location to decimal long and lat and split into 2 sep cols
coords = raw_mtns['Location'].str.extract(r'(?P<lat>\d+\.\d+)°?N.*?(?P<lon>\d+\.\d+)°?W')

raw_mtns['latitude'] = coords['lat'].astype(float)
raw_mtns['longitude'] = -coords['lon'].astype(float)

# Drop unused columns
clean_mtns = raw_mtns.drop(['Elevation', 'Prominence', 'Isolation', 'Location'], axis=1)

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
print("Connected to PostgreSQL!")
