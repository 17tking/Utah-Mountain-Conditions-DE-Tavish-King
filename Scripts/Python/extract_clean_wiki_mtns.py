import pandas as pd
from bs4 import BeautifulSoup
import requests
import time

# ============================================================
# This script extracts & cleans the "50 Tallest Mountain Peaks in Utah" 
# table from Wikipedia and saves it to master_mtns.csv.
# 
# The CSV will then be loaded into 
# `bronze.wiki_mtns` through a separate script/DAG.
#
# WARNING: 
#   This is a ONE-TIME extraction. Any future updates should be 
#   made manually in master_mtns.csv.
# ============================================================


# ------------------
# Extract
# ------------------
def extract_wiki_mtns():
    wiki_url = "https://en.wikipedia.org/wiki/List_of_mountain_peaks_of_Utah"
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
                      "AppleWebKit/537.36 (KHTML, like Gecko) "
                      "Chrome/118.0.0.0 Safari/537.36"
    }

    print("=" * 50)
    print(">> Extracting mountain data from Wikipedia...")
    print("=" * 50)

    response = requests.get(wiki_url, headers=headers, timeout=10)

    if response.status_code != 200:
        raise RuntimeError(f"Wikipedia request failed — status {response.status_code}")

    soup = BeautifulSoup(response.text, "html.parser")
    table = soup.find("table", {"class": "wikitable sortable"})

    if table is None:
        raise ValueError("Could not find the table. Check the class name or page structure.")

    rows = table.find_all("tr")
    col_headers = [th.get_text(strip=True) for th in rows[0].find_all("th")]

    data = []
    for row in rows[1:]:
        cols = [td.get_text(strip=True) for td in row.find_all("td")]
        if cols:
            data.append(cols)

    raw_mtns = pd.DataFrame(data, columns=col_headers)

    print(f"Extracted {len(raw_mtns)} rows from Wikipedia.")
    print(f"Saved to master_mtns.csv")

    return raw_mtns

# ----------------
# Clean
# ----------------
def clean_wiki_mtns(raw_mtns):
    print("=" * 50)
    print(">> Cleaning mountain data...")
    print("=" * 50)

    df = raw_mtns.copy()

    # Unique mountain ID (zero-padded)
    df["mtn_id"] = (df.index + 1).map(lambda x: f"{x:03}")
    cols = ["mtn_id"] + [c for c in df.columns if c != "mtn_id"]
    df = df[cols]

    # Standardize column names
    df = df.rename(columns={
        "Rank": "rank",
        "Mountain peak": "mtn_name",
        "Mountain range": "mtn_range"
    })

    # Remove Wikipedia citation brackets e.g. [1], [note 2]
    df["mtn_name"] = df["mtn_name"].str.replace(r"\[[^\]]*\]", "", regex=True).str.strip()

    # Split elevation into ft and m
    # Format in source: "13,528 ft(4,123 m)" — strip commas, parens, unit labels
    df["elev_ft"] = (
        df["Elevation"].str.split("ft").str[0]
        .str.replace(",", "").str.strip()
    )
    df["elev_m"] = (
        df["Elevation"].str.split("ft").str[1]
        .str.replace(r"[^\d.]", "", regex=True).str.strip()
    )

    # Split prominence into ft and m
    df["prom_ft"] = (
        df["Prominence"].str.split("ft").str[0]
        .str.replace(",", "").str.strip()
    )
    df["prom_m"] = (
        df["Prominence"].str.split("ft").str[1]
        .str.replace(r"[^\d.]", "", regex=True).str.strip()
    )

    # Split isolation into mi and km
    df["isol_mi"] = (
        df["Isolation"].str.split("mi").str[0]
        .str.replace(",", "").str.strip()
    )
    df["isol_km"] = (
        df["Isolation"].str.split("mi").str[1]
        .str.replace(r"[^\d.]", "", regex=True).str.strip()
    )

    # Convert numeric columns
    num_cols = ["elev_ft", "elev_m", "prom_ft", "prom_m", "isol_mi", "isol_km"]
    df[num_cols] = df[num_cols].apply(pd.to_numeric, errors="coerce")

    # Parse coordinates — source format: "37.7749°N 113.2994°W"
    coords = df["Location"].str.extract(r"(?P<lat>\d+\.\d+)°?N.*?(?P<lon>\d+\.\d+)°?W")
    df["latitude"] = coords["lat"].astype(float)
    df["longitude"] = -coords["lon"].astype(float)

    # Drop raw source columns
    clean_mtns = df.drop(["rank", "Elevation", "Prominence", "Isolation", "Location"], axis=1)

    print(f"Cleaned {len(clean_mtns)} rows.")
    return clean_mtns


# ----------------------------
# Step 2b: Add timezone
# ----------------------------
def enrich_with_timezone(clean_mtns):
    """
    Fetches timezone for each summit from the OpenMeteo API using coordinates.
    This is a free call with no API key required and handles summits outside
    Utah automatically, future-proofing against new additions.
    """
    print("=" * 50)
    print(">> Fetching timezone data from OpenMeteo...")
    print("=" * 50)
 
    meteo_url = "https://api.open-meteo.com/v1/forecast"
    timezones = []
    failed = []
 
    for _, row in clean_mtns.iterrows():
        params = {
            "latitude": row["latitude"],
            "longitude": row["longitude"],
            "timezone": "auto",
            "forecast_days": 1,
            "daily": "weather_code"  # minimal field — we only need the timezone metadata
        }
 
        try:
            r = requests.get(meteo_url, params=params, timeout=10)
            r.raise_for_status()
            tz = r.json().get("timezone")
            timezones.append(tz)
            time.sleep(0.3)
        except Exception as e:
            print(f"Timezone fetch failed for mtn_id={row['mtn_id']} ({row['mtn_name']}): {e}")
            # timezones.append(None)
            failed.append(row["mtn_id"])
 
    clean_mtns = clean_mtns.copy()
    clean_mtns["timezone"] = timezones
 
    if failed:
        print(f"Warning: timezone fetch failed for {len(failed)} summit(s): {failed}")
    else:
        print(f"Timezones fetched for all {len(clean_mtns)} summits.")
 

    # Save data to CSV
    clean_mtns.to_csv('master_mtns.csv', index=False)
    print(f"Data cleaned!")

    return clean_mtns


# MAIN
def main():
    raw_mtns = extract_wiki_mtns()
    clean_mtns = clean_wiki_mtns(raw_mtns)
    clean_mtns = enrich_with_timezone(clean_mtns)

    print("=" * 50)
    print(">> Done.")
    print("=" * 50)

if __name__ == "__main__":
    main()