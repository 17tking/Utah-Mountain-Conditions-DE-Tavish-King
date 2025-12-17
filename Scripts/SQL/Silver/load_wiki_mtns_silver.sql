/*

Script Purpose:
	Inserting bronze.wiki_mtns data into silver layer with constraints for idempotency.

*/

insert into silver.wiki_mtns (mtn_id_pk, mtn_name, mtn_range, elev_ft, elev_m, prom_ft, prom_m, isol_mi, isol_km, latitude, longitude)
select mtn_id, 
	   mtn_name, 
	   mtn_range, 
	   elev_ft, 
	   elev_m, 
	   prom_ft, 
	   prom_m, 
	   isol_mi, 
	   isol_km, 
	   latitude, 
	   longitude
from bronze.wiki_mtns
where latitude between -90 and 90
	and longitude between -180 and 180
	and elev_ft > 0
	and elev_m > 0
on conflict (mtn_id_pk) do update 
set
	mtn_name = excluded.mtn_name, 
	mtn_range = excluded.mtn_range, 
	elev_ft = excluded.elev_ft, 
    elev_m = excluded.elev_m, 
	prom_ft = excluded.prom_ft, 
    prom_m = excluded.prom_m, 
	isol_mi = excluded.isol_mi, 
	isol_km = excluded.isol_km, 
	latitude = excluded.latitude, 
	longitude = excluded.longitude;