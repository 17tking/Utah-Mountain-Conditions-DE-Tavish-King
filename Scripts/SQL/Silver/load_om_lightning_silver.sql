/*
Script Purpose:
	Inserting bronze.openmeteo_lightning data into silver layer with constraints for idempotency.
Notes:
	Unpacks JSON arrays using CROSS JOIN LATERAL to create individual rows for 
	each 15-minute forecast interval, then aggregates to hourly granularity.
	Max and mean lightning potential are captured per hour -- max for peak risk,
	mean for overall hour risk level.
	NULL lightning potential values are preserved as NULL rather than coalesced
	to 0 — null means no data, 0 means confirmed no lightning potential.
	latitude, longitude, elevation_m, and timezone are mountain-level attributes
	stored in silver.wiki_mtns and are not repeated here (3NF).
*/

insert into silver.openmeteo_lightning (mtn_id, measured_at_m, pulled_at, ltng_time, ltng_potential_j_kg_max, ltng_potential_j_kg_mean)
select distinct on (mtn_id, date_trunc('hour', (lightning_forecast -> 'minutely_15' -> 'time' ->> idx)::timestamp))
    mtn_id::int,
    measured_at_m,
    pulled_at,
    date_trunc('hour', (lightning_forecast -> 'minutely_15' -> 'time' ->> idx)::timestamp) as ltng_time,
    max((lightning_forecast -> 'minutely_15' -> 'lightning_potential' ->> idx)::numeric)   as ltng_potential_j_kg_max,
    round(avg((lightning_forecast -> 'minutely_15' -> 'lightning_potential' ->> idx)::numeric), 2) as ltng_potential_j_kg_mean
from bronze.openmeteo_lightning
cross join lateral generate_series(
    0,
    jsonb_array_length(lightning_forecast -> 'minutely_15' -> 'time') - 1
) as idx
where pulled_at::timestamp > coalesce(
    (select max(pulled_at::timestamp) from silver.openmeteo_lightning),
    '1900-01-01'::timestamp
)
group by mtn_id, measured_at_m, pulled_at, date_trunc('hour', (lightning_forecast -> 'minutely_15' -> 'time' ->> idx)::timestamp)
order by mtn_id, date_trunc('hour', (lightning_forecast -> 'minutely_15' -> 'time' ->> idx)::timestamp), pulled_at desc
on conflict (mtn_id, ltng_time)
do update set
    measured_at_m           = excluded.measured_at_m,
    pulled_at               = excluded.pulled_at,
    ltng_potential_j_kg_max  = excluded.ltng_potential_j_kg_max,
    ltng_potential_j_kg_mean = excluded.ltng_potential_j_kg_mean;