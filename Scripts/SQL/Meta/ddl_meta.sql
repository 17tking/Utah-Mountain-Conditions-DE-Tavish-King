/*
=============================================================
DDL Script: Create Meta Tables
=============================================================
Script Purpose:
	This script creates all tables in the 'meta' schema,
	dropping existing tables if they already exist.

	Run this script to re-define the DDL structure of 'meta'
	tables.
	
Notes:
	Redefining 'meta.task_instances' or adding new fields will also require
	changes to load_task_instances.py.

	'meta.api_call_log' inserts data automatically with each load from each 
	openmeteo source (daily, hourly, lightning).

Warning: 
	Running this script will erase data and tables. Ensure
	there are backups in place.
=============================================================
*/

-- -------------------------
-- meta.task_instances
-- -------------------------
drop table if exists meta.task_instances cascade;

create table meta.task_instances (
    task_instance_id VARCHAR(24),
    task_id          VARCHAR(50),
    dag_id           VARCHAR(50),
    dag_run_id       VARCHAR(200),
    state            VARCHAR(20),
    start_date       TIMESTAMP,
    end_date         TIMESTAMP,
    duration         NUMERIC(10,6),
    retry_attempts   INT,
    operator_name    VARCHAR(200),
    create_date      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (task_instance_id)

    CONSTRAINT uq_task_instances_airflow
        UNIQUE (dag_id, dag_run_id, task_id)
);

-- -------------------------
-- meta.api_call_log
-- -------------------------
drop table if exists meta.api_call_log;
 
create table meta.api_call_log (
    call_id         SERIAL          PRIMARY KEY,
    create_date     TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    source          VARCHAR(50)     NOT NULL,   -- e.g. 'openmeteo', 'openweather'
    endpoint        VARCHAR(200)    NOT NULL,
    mountain_id     INT,                        -- null for non-summit calls (e.g. timezone enrichment)
    status_code     INT,                        -- null if request threw an exception
    response_time   INT,                        -- round-trip time in milliseconds
    success         BOOLEAN         NOT NULL,
    error_message   TEXT                        -- null on success
);

