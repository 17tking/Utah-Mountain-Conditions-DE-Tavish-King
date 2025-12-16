/*
=============================================================
DDL Script: Create Silver Tables
=============================================================
Script Purpose:
		The Silver layer stores cleaned, normalized, and validated 
		data extracted from the Bronze raw tables. All tables are 
		designed in 3rd Normal Form (3NF) to eliminate redundancy 
		and ensure data integrity.
Notes:
    - Each table includes specific constraints to enforce
    - Tables are designed for incremental loading
    - JSON fields from Bronze are transformed into relational columns
    - No business logic or aggregation is applied
=============================================================
*/

-- Creating dimension wiki_mtns in Silver schema
create table silver.dim_wiki_mtns (
mtn_id_pk VARCHAR(3) PRIMARY KEY,
mtn_name VARCHAR(100) NOT NULL,
mtn_range VARCHAR(100),
elev_ft INT CHECK (elev_ft > 0),
elev_m INT CHECK (elev_m > 0),
prom_ft INT,
prom_m INT,
isol_mi DECIMAL(6,2),
isol_km DECIMAL(6,2),
latitude DECIMAL(9,6) NOT NULL CHECK (latitude BETWEEN -90 AND 90),
longitude DECIMAL(9,6) NOT NULL CHECK (longitude BETWEEN -180 AND 180)
);

-- Creating OW Alerts table in Silver schema
create table silver.openweather_alerts (
alert_id_pk SERIAL PRIMARY KEY,
mtn_id VARCHAR(3) NOT NULL,
latitude DECIMAL(9,6) NOT NULL CHECK (latitude BETWEEN -90 AND 90),
longitude DECIMAL(9,6) NOT NULL CHECK (longitude BETWEEN -180 AND 180),
alert_sender_name TEXT,
alert_event TEXT NOT NULL,
alert_start TIMESTAMPTZ NOT NULL,
alert_end TIMESTAMPTZ NOT NULL CHECK (alert_end >= alert_start),
alert_description TEXT CHECK (length(alert_description) <= 5000),
alert_tags JSONB,
-- for upsert purposes
unique (mtn_id, alert_event, alert_start)
);


