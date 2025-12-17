/*
=============================================================
DDL Script: Create Bronze Tables
=============================================================
Script Purpose:
	This script creates all raw tables in the 'bronze' schema,
	dropping existing tables if they already exist.

	Run this script to re-define the DDL structure of 'bronze'
	tables.

Note: 
	After running this script, you will need to run the
	python scripts that populate the data. 

Warning: 
	Running this script will erase data and tables. Ensure
	there are backups in place.
=============================================================
*/


-- Creating wiki_mtns table in bronze schema
drop table if exists bronze.wiki_mtns;

create table bronze.wiki_mtns (
mtn_id VARCHAR(3),
mtn_name VARCHAR(100),
mtn_range VARCHAR(100),
elev_ft INT,
elev_m INT,
prom_ft INT,
prom_m INT,
isol_mi DECIMAL(6,2),
isol_km DECIMAL(6,2),
latitude DECIMAL(9,6),
longitude DECIMAL(9,6),
load_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
);

-- Creating table for alert data from openweather in Bronze schema
drop table if exists bronze.openweather_alerts;

create table bronze.openweather_alerts (
    id SERIAL PRIMARY KEY,
    mtn_id VARCHAR(3),
    latitude FLOAT NOT NULL,
    longitude FLOAT NOT NULL,
    pulled_at TIMESTAMPTZ NOT NULL,
    alert JSONB NOT NULL
);
-- Unique index on JSONB fields
CREATE UNIQUE INDEX IF NOT EXISTS bronze_alerts_unique_idx
ON bronze.openweather_alerts (
    mtn_id,
    ((alert->>'event')),
    ((alert->>'start')),
    ((alert->>'end'))
);

-- Creating Daily forecasts table from OpenMeteo in Bronze schema
drop table if exists bronze.openmeteo_daily;

create table bronze.openmeteo_daily (
	mtn_id VARCHAR(3),
	latitude FLOAT NOT NULL,
	longitude FLOAT NOT NULL,
	elevation INT,
	timezone VARCHAR(100),
	timezone_abbreviation VARCHAR(5),
	utc_offset_seconds INT,
	pulled_at TIMESTAMPTZ NOT NULL,
	daily_forecast JSONB NOT NULL
);


-- Creating hourly forecasts from OpenMeteo in Bronze schema
drop table if exists bronze.openmeteo_hourly;

create table bronze.openmeteo_hourly (
	mtn_id VARCHAR(3),
	latitude FLOAT NOT NULL,
	longitude FLOAT NOT NULL,
	elevation INT,
	timezone VARCHAR(100),
	timezone_abbreviation VARCHAR(5),
	utc_offset_seconds INT,
	pulled_at TIMESTAMPTZ NOT NULL,
	hourly_forecast JSONB NOT NULL
);


-- Creating lightining index table from OpenMeteo in Bronze schema
drop table if exists bronze.openmeteo_lightning;

create table bronze.openmeteo_lightning (
	mtn_id VARCHAR(3),
	latitude FLOAT NOT NULL,
	longitude FLOAT NOT NULL,
	elevation INT,
	timezone VARCHAR(100),
	timezone_abbreviation VARCHAR(5),
	utc_offset_seconds INT,
	pulled_at TIMESTAMPTZ NOT NULL,
	lightning_forecast JSONB NOT NULL
);