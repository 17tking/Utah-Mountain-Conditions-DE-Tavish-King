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
	Ensure that `mountains_stg` and `weathercodes` are populated first before loading!!

Warning: 
	Running this script will erase data and tables. Ensure
	there are backups in place.
=============================================================
*/


-- -------------------------
-- bronze.mountains_stg
-- -------------------------
drop table if exists bronze.mountains_stg cascade;

create table bronze.mountains_stg (
    mountain_id         INT            PRIMARY KEY,
    mountain_name       VARCHAR(100),
    mountain_range      VARCHAR(100),
    elevation_ft        INT,
    elevation_m         INT,
    prominence_ft       INT,
    prominence_m        INT,
    isolation_mi        DECIMAL(6,2),
    isolation_km        DECIMAL(6,2),
    mountain_latitude   DECIMAL(9,6),
    mountain_longitude  DECIMAL(9,6),
	mountain_timezone   VARCHAR(50),
    create_date         TIMESTAMP       DEFAULT CURRENT_TIMESTAMP
);


-- -------------------------
-- bronze.alerts_stg
-- -------------------------
drop table if exists bronze.alerts_stg cascade;

create table bronze.alerts_stg (
    alert_id         VARCHAR(24)   PRIMARY KEY,
    mountain_id      INT           REFERENCES bronze.mountains_stg(mountain_id),
    alert_latitude   FLOAT         NOT NULL,
    alert_longitude  FLOAT         NOT NULL,
    create_date      TIMESTAMP     NOT NULL,
    alert_json       JSONB         NOT NULL
);

-- Unique index to prevent duplicate alerts
create unique index if not exists bronze_alerts_unique_idx
on bronze.alerts_stg (
    mountain_id,
    (alert_json->>'event'),
    (alert_json->>'start'),
    (alert_json->>'end')
);


-- -------------------------
-- bronze.daily_stg
-- -------------------------
drop table if exists bronze.daily_stg cascade;

create table bronze.daily_stg (
    daily_id                VARCHAR(24)     PRIMARY KEY,
    mountain_id             INT             REFERENCES bronze.mountains_stg(mountain_id),
    daily_latitude          FLOAT           NOT NULL,
    daily_longitude         FLOAT           NOT NULL,
    measured_at             INT,
    create_date             TIMESTAMP       DEFAULT CURRENT_TIMESTAMP,
    daily_json              JSONB           NOT NULL
);

-- Unique index to prevent duplicate ingestion runs
create unique index if not exists bronze_openmeteo_daily_unique_idx
on bronze.daily_stg (mountain_id, create_date);


-- -------------------------
-- bronze.openmeteo_hourly
-- -------------------------
drop table if exists bronze.openmeteo_hourly cascade;

create table bronze.openmeteo_hourly (
    mtn_id                  INT             REFERENCES bronze.wiki_mtns(mtn_id),
    latitude                FLOAT           NOT NULL,
    longitude               FLOAT           NOT NULL,
    measured_at_m           INT,
    timezone                VARCHAR(100),
    timezone_abbreviation   VARCHAR(5),
    utc_offset_seconds      INT,
    pulled_at               TIMESTAMPTZ     NOT NULL,
    hourly_forecast         JSONB           NOT NULL
);

-- Unique index to prevent duplicate ingestion runs
create unique index if not exists bronze_openmeteo_hourly_unique_idx
on bronze.openmeteo_hourly (mtn_id, pulled_at);


-- ----------------------------
-- bronze.openmeteo_lightning
-- ----------------------------
drop table if exists bronze.openmeteo_lightning cascade;

create table bronze.openmeteo_lightning (
    mtn_id                  INT             REFERENCES bronze.wiki_mtns(mtn_id),
    latitude                FLOAT           NOT NULL,
    longitude               FLOAT           NOT NULL,
    measured_at_m           INT,
    timezone                VARCHAR(100),
    timezone_abbreviation   VARCHAR(5),
    utc_offset_seconds      INT,
    pulled_at               TIMESTAMPTZ     NOT NULL,
    lightning_forecast      JSONB           NOT NULL
);

-- Unique index to prevent duplicate ingestion runs
create unique index if not exists bronze_openmeteo_lightning_unique_idx
on bronze.openmeteo_lightning (mtn_id, pulled_at);