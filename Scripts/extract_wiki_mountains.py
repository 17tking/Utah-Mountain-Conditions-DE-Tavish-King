from bs4 import BeautifulSoup
import requests as r
import pandas as pd
import os
import re

# ==============================================================================
# This script goes to the wiki url provided to extract the table of the 
# 50 tallest mountains in Utah with its information. The table is made into a dataframe and 
# saved as a CSV in the Raw Data folder where it will be cleaned in another script.
# ==============================================================================

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
df_tallest50 = pd.DataFrame(data, columns=headers)

# Preview
print(df_tallest50.head())


def clean_wiki_text(text):
    # Remove [1], [a], etc.
    text = re.sub(r'\[\w+\]', '', text)
    # Replace non-breaking spaces with regular spaces
    text = text.replace('\xa0', ' ')
    return text.strip()

def extract_decimal_coords(text):
    # Match the pattern like 40.7763°N 110.3729°W
    match = re.search(r'(\d+\.\d+)°?N.*?(\d+\.\d+)°?W', text)
    if match:
        lat, lon = match.groups()
        return float(lat), -float(lon)
    return None, None

# execute cleaning functions + fix lat/long issues
cleaned_data = []
for row in data:
    cleaned_row = [clean_wiki_text(cell) for cell in row]
    cleaned_data.append(cleaned_row)

df_tallest50 = pd.DataFrame(cleaned_data, columns=headers)

df_tallest50['Latitude'], df_tallest50['Longitude'] = zip(*df_tallest50['Location'].apply(extract_decimal_coords))
df_tallest50 = df_tallest50.drop('Location', axis=1)


# Save to Raw Data folder in dir
file_path = os.path.join("Raw Data", "raw_utah_mountains.csv")
df_tallest50.to_csv(file_path, index=False, encoding='utf-8')
print(f"{file_path} saved!")