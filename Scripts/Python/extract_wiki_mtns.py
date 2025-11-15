from bs4 import BeautifulSoup
import requests as r
import pandas as pd
import os

# =======================================================================================
# This script extracts the "50 Tallest Mountains in Utah" table from Wikipedia.
# =======================================================================================

# sending GET request to wiki page
wiki_url = "https://en.wikipedia.org/wiki/List_of_mountain_peaks_of_Utah"
headers = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
                  "AppleWebKit/537.36 (KHTML, like Gecko) "
                  "Chrome/118.0.0.0 Safari/537.36"
}
response = r.get(wiki_url, headers=headers)
# error checking
print(response.status_code)

# bs object
soup = BeautifulSoup(response.text, "html.parser")
# table
tallest50_table = soup.find('table',{'class':'wikitable sortable'})
if tallest50_table is None:
    raise ValueError("Could not find the table. Check the class name or page structure.")

# fetching rows + headers
rows = tallest50_table.find_all('tr')
headers = [th.get_text(strip=True) for th in rows[0].find_all('th')]

# Extract table data
data = []
for row in rows[1:]:
    cols = [td.get_text(strip=True) for td in row.find_all('td')]
    if cols:  # avoid empty rows
        data.append(cols)

# Create DataFrame
raw_mtns = pd.DataFrame(data, columns=headers)

# Preview
print(raw_mtns.head())

# Save to Raw Data folder in dir
file_path = os.path.join("Wiki Data", "raw_mtns.csv")
raw_mtns.to_csv(file_path, index=False, encoding='utf-8')
print("===============")
print("raw_mtns saved!")
print("===============")