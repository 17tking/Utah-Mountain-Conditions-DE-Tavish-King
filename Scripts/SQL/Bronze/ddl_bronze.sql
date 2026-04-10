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
	Ensure that wiki_mtns and weathercodes are populated first before loading!!

Warning: 
	Running this script will erase data and tables. Ensure
	there are backups in place.
=============================================================
*/


-- -------------------------
-- bronze.wiki_mtns
-- -------------------------
drop table if exists bronze.wiki_mtns cascade;

create table bronze.wiki_mtns (
    mtn_id          INT             PRIMARY KEY,
    mtn_name        VARCHAR(100),
    mtn_range       VARCHAR(100),
    elev_ft         INT,
    elev_m          INT,
    prom_ft         INT,
    prom_m          INT,
    isol_mi         DECIMAL(6,2),
    isol_km         DECIMAL(6,2),
    latitude        DECIMAL(9,6),
    longitude       DECIMAL(9,6),
	timezone        VARCHAR(50),
    load_timestamp  TIMESTAMP       DEFAULT CURRENT_TIMESTAMP
);


-- -------------------------
-- bronze.openweather_alerts
-- -------------------------
drop table if exists bronze.openweather_alerts cascade;

create table bronze.openweather_alerts (
    id          SERIAL          PRIMARY KEY,
    mtn_id      INT             REFERENCES bronze.wiki_mtns(mtn_id),
    latitude    FLOAT           NOT NULL,
    longitude   FLOAT           NOT NULL,
    pulled_at   TIMESTAMPTZ     NOT NULL,
    alert       JSONB           NOT NULL
);

-- Unique index to prevent duplicate alerts
create unique index if not exists bronze_alerts_unique_idx
on bronze.openweather_alerts (
    mtn_id,
    (alert->>'event'),
    (alert->>'start'),
    (alert->>'end')
);


-- -------------------------
-- bronze.openmeteo_daily
-- -------------------------
drop table if exists bronze.openmeteo_daily cascade;

create table bronze.openmeteo_daily (
    mtn_id                  INT             REFERENCES bronze.wiki_mtns(mtn_id),
    latitude                FLOAT           NOT NULL,
    longitude               FLOAT           NOT NULL,
    measured_at_m           INT,
    timezone                VARCHAR(100),
    timezone_abbreviation   VARCHAR(5),
    utc_offset_seconds      INT,
    pulled_at               TIMESTAMPTZ     NOT NULL,
    daily_forecast          JSONB           NOT NULL
);

-- Unique index to prevent duplicate ingestion runs
create unique index if not exists bronze_openmeteo_daily_unique_idx
on bronze.openmeteo_daily (mtn_id, pulled_at);


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