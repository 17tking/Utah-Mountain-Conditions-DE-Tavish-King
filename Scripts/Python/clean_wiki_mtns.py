import pandas as pd
import re
import os

# ============================================================
# This script cleans raw_wiki_mountains entirely.
#
# Why?
# - This data is very messy. It is easier to clean it in python.
#   Plus, it only has to be ingested & cleaned once.
# ==============================================================

# read in raw data
raw_mtns = pd.read_csv("Wiki Data/raw_mtns.csv")

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

raw_mtns['lat'] = coords['lat'].astype(float)
raw_mtns['long'] = -coords['lon'].astype(float)

# Drop unused columns
clean_mtns = raw_mtns.drop(['Elevation', 'Prominence', 'Isolation', 'Location'], axis=1)

# Saving clean_mtns as clean_mtns.csv
clean_mtns.to_csv("Wiki Data/clean_mtns.csv", index=False, encoding='utf-8')

print("=================")
print("clean_mtns saved!")
print("=================")