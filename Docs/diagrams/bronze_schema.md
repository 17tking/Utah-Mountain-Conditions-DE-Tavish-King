# Bronze Layer Schema Documentation

## Overview

The Bronze layer stores raw, unmodified data as ingested from external APIs. Tables are append-only and serve as the source of truth for all downstream Silver transformations. No cleaning, normalization, or business logic is applied at this layer.

**Design principles:**
- Raw JSON responses are stored in JSONB columns for flexibility
- Unique indexes prevent duplicate ingestion runs
- All tables retain `latitude`, `longitude`, and location metadata at the row level (denormalized by design)
- `wiki_mtns` and `weathercodes` must be populated before loading any forecast tables

> **Warning:** Re-running the DDL script will drop and recreate all tables. Ensure backups are in place before running.

---

## Tables

### `bronze.wiki_mtns`
Raw mountain summit reference data scraped from Wikipedia. Serves as the base dimension table for all bronze fact tables.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `mtn_id` | INT | PRIMARY KEY | Unique mountain identifier |
| `mtn_name` | VARCHAR(100) | | Mountain name |
| `mtn_range` | VARCHAR(100) | | Mountain range name |
| `elev_ft` | INT | | Summit elevation in feet |
| `elev_m` | INT | | Summit elevation in meters |
| `prom_ft` | INT | | Topographic prominence in feet |
| `prom_m` | INT | | Topographic prominence in meters |
| `isol_mi` | DECIMAL(6,2) | | Isolation in miles |
| `isol_km` | DECIMAL(6,2) | | Isolation in kilometers |
| `latitude` | DECIMAL(9,6) | | Summit latitude |
| `longitude` | DECIMAL(9,6) | | Summit longitude |
| `timezone` | VARCHAR(50) | | Local timezone string |
| `load_timestamp` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | Row insertion timestamp |

---

### `bronze.openweather_alerts`
Raw weather alert data per mountain from the OpenWeather API. Each row stores a full alert JSON payload.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | SERIAL | PRIMARY KEY | Auto-incrementing row ID |
| `mtn_id` | INT | FK → wiki_mtns | Mountain identifier |
| `latitude` | FLOAT | NOT NULL | Request latitude |
| `longitude` | FLOAT | NOT NULL | Request longitude |
| `pulled_at` | TIMESTAMPTZ | NOT NULL | Ingestion timestamp (MT) |
| `alert` | JSONB | NOT NULL | Raw alert payload from API |

**Unique Index:** `(mtn_id, alert->>'event', alert->>'start', alert->>'end')` — prevents duplicate alerts on reingestion.

---

### `bronze.openmeteo_daily`
Raw daily forecast JSON responses per mountain from the Open-Meteo API. One row per mountain per pipeline run.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `mtn_id` | INT | FK → wiki_mtns | Mountain identifier |
| `latitude` | FLOAT | NOT NULL | Request latitude |
| `longitude` | FLOAT | NOT NULL | Request longitude |
| `measured_at_m` | INT | | API-returned elevation in meters |
| `timezone` | VARCHAR(100) | | Timezone string from API response |
| `timezone_abbreviation` | VARCHAR(5) | | Timezone abbreviation (e.g. MDT) |
| `MT_offset_seconds` | INT | | MT offset in seconds |
| `pulled_at` | TIMESTAMPTZ | NOT NULL | Ingestion timestamp (MT) |
| `daily_forecast` | JSONB | NOT NULL | Raw daily forecast payload from API |

**Unique Index:** `(mtn_id, pulled_at)` — prevents duplicate ingestion runs.

---

### `bronze.openmeteo_hourly`
Raw hourly forecast JSON responses per mountain from the Open-Meteo API. One row per mountain per pipeline run.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `mtn_id` | INT | FK → wiki_mtns | Mountain identifier |
| `latitude` | FLOAT | NOT NULL | Request latitude |
| `longitude` | FLOAT | NOT NULL | Request longitude |
| `measured_at_m` | INT | | API-returned elevation in meters |
| `timezone` | VARCHAR(100) | | Timezone string from API response |
| `timezone_abbreviation` | VARCHAR(5) | | Timezone abbreviation (e.g. MDT) |
| `MT_offset_seconds` | INT | | MT offset in seconds |
| `pulled_at` | TIMESTAMPTZ | NOT NULL | Ingestion timestamp (MT) |
| `hourly_forecast` | JSONB | NOT NULL | Raw hourly forecast payload from API |

**Unique Index:** `(mtn_id, pulled_at)` — prevents duplicate ingestion runs.

---

### `bronze.openmeteo_lightning`
Raw 15-minute interval lightning potential (LPI) forecast JSON responses per mountain from the Open-Meteo API. One row per mountain per pipeline run. Aggregated to hourly granularity in the Silver layer.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `mtn_id` | INT | FK → wiki_mtns | Mountain identifier |
| `latitude` | FLOAT | NOT NULL | Request latitude |
| `longitude` | FLOAT | NOT NULL | Request longitude |
| `measured_at_m` | INT | | API-returned elevation in meters |
| `timezone` | VARCHAR(100) | | Timezone string from API response |
| `timezone_abbreviation` | VARCHAR(5) | | Timezone abbreviation (e.g. MDT) |
| `MT_offset_seconds` | INT | | MT offset in seconds |
| `pulled_at` | TIMESTAMPTZ | NOT NULL | Ingestion timestamp (MT) |
| `lightning_forecast` | JSONB | NOT NULL | Raw 15-min lightning potential payload from API |

**Unique Index:** `(mtn_id, pulled_at)` — prevents duplicate ingestion runs.

---

### `bronze.api_call_log`
Audit log tracking every outbound API call made by ingestion scripts. Used for monitoring call volume, latency, and failure rates.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | SERIAL | PRIMARY KEY | Auto-incrementing row ID |
| `called_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Timestamp of the API call (MT) |
| `api_source` | VARCHAR(50) | NOT NULL | API name (e.g. 'openmeteo', 'openweather') |
| `endpoint` | VARCHAR(200) | NOT NULL | Full API endpoint URL |
| `mtn_id` | INT | | Mountain identifier (NULL for non-summit calls) |
| `status_code` | INT | | HTTP status code (NULL if request threw an exception) |
| `response_ms` | INT | | Round-trip response time in milliseconds |
| `success` | BOOLEAN | NOT NULL | True if status 200, False otherwise |
| `error_message` | TEXT | | Error details (NULL on success) |

---

## Relationships

```
bronze.wiki_mtns (mtn_id)
    ├── bronze.openweather_alerts (mtn_id)
    ├── bronze.openmeteo_daily (mtn_id)
    ├── bronze.openmeteo_hourly (mtn_id)
    └── bronze.openmeteo_lightning (mtn_id)

bronze.api_call_log — no FK, standalone audit table
```
