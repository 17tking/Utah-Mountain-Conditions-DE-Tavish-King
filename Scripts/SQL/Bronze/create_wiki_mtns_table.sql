-- Creating wiki_mtns table in bronze schema
create table if not exists bronze.wiki_mtns (
mtn_id VARCHAR(3),
rank INT,
mtn_peak VARCHAR(100),
mtn_range VARCHAR(100),
elev_ft INT,
elev_m INT,
prom_ft INT,
prom_m INT,
isol_mi DECIMAL(6,2),
isol_km DECIMAL(6,2),
latitude DECIMAL(9,6),
longitude DECIMAL(9,6),
load_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE bronze.wiki_mtns 
IS 'Cleaned Wikipedia mountain data (Bronze layer)';
