-- Creating table for raw json alert data from openweather api in bronze schema
create table if not exists bronze.alerts (
    id SERIAL PRIMARY KEY,
    mtn_id VARCHAR(3),
    latitude FLOAT NOT NULL,
    longitude FLOAT NOT NULL,
    pulled_at TIMESTAMPTZ NOT NULL,
    alert JSONB NOT NULL
);

-- Unique index on JSONB fields
CREATE UNIQUE INDEX IF NOT EXISTS bronze_alerts_unique_idx
ON bronze.alerts (
    mtn_id,
    ((alert->>'event')),
    ((alert->>'start')),
    ((alert->>'end'))
);