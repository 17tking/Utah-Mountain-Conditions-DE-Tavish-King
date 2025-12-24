/*

Script Purpose:
	Inserting bronze.openmeteo_lightning data into silver layer with constraints for idempotency.

Notes:

*/

insert into silver.openmeteo_lightning (mtn_id, latitude, longitude, elevation_m, timezone,
											pulled_at, ltng_time, ltng_potential_j_kg
)
select distinct on (mtn_id, (lightning_forecast -> 'minutely_15' -> 'time' ->> idx)::timestamp)
	mtn_id::int,
	latitude,
	longitude,
	elevation,
	timezone,
	pulled_at,
	--json cols
	(lightning_forecast -> 'minutely_15' -> 'time' ->> idx)::timestamp as ltng_time,
	(lightning_forecast -> 'minutely_15' -> 'lightning_potential' ->> idx)::numeric as ltng_potential_j_kg
from bronze.openmeteo_lightning
cross join lateral generate_series(
    0, 
    jsonb_array_length(lightning_forecast -> 'minutely_15' -> 'time') - 1
) as idx
where pulled_at::timestamp >= coalesce(
	(select max(pulled_at::timestamp) from silver.openmeteo_lightning),
	'1900-01-01'::timestamp
)
order by mtn_id, (lightning_forecast -> 'minutely_15' -> 'time' ->> idx)::timestamp, pulled_at desc
on conflict (mtn_id, ltng_time)
do update
set 
	pulled_at = excluded.pulled_at,
	latitude = excluded.latitude,
	longitude = excluded.longitude,
	elevation_m = excluded.elevation_m,
	timezone = excluded.timezone,
	ltng_time = excluded.ltng_time,
	ltng_potential_j_kg = excluded.ltng_potential_j_kg;