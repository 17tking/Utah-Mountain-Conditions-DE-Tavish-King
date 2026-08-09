/*

Script Purpose:
	Inserting bronze.mountains_stg data into silver layer with constraints for idempotency.

*/

insert into silver.mountains (mountain_id, mountain_name, mountain_range, elevation_ft, elevation_m, prominence_ft, prominence_m, isolation_mi, isolation_km, mountain_latitude, mountain_longitude, mountain_timezone, create_date)
select mountain_id, 
	   mountain_name, 
	   mountain_range, 
	   elevation_ft, 
	   elevation_m, 
	   prominence_ft, 
	   prominence_m, 
	   isolation_mi, 
	   isolation_km, 
	   mountain_latitude, 
	   mountain_longitude,
	   mountain_timezone,
	   create_date
from bronze.mountains_stg
where mountain_latitude between -90 and 90
	and mountain_longitude between -180 and 180
	and elevation_ft > 0
	and elevation_m > 0
on conflict (mountain_id) 
do update set
	mountain_name      = excluded.mountain_name, 
	mountain_range     = excluded.mountain_range, 
	elevation_ft       = excluded.elevation_ft, 
    elevation_m        = excluded.elevation_m, 
	prominence_ft      = excluded.prominence_ft, 
    prominence_m       = excluded.prominence_m, 
	isolation_mi       = excluded.isolation_mi, 
	isolation_km       = excluded.isolation_km, 
	mountain_latitude  = excluded.mountain_latitude, 
	mountain_longitude = excluded.mountain_longitude,
	mountain_timezone  = excluded.mountain_timezone,
	create_date        = excluded.create_date;