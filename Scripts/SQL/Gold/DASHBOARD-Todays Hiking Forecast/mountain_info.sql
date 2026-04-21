-- Basic Mountain info to include on dashboard
--
select mtn_range as "Mountain Range", 
	   elev_ft as "Elevation (ft)", 
	   prom_ft as "Prominence (ft)",
	   latitude as "Latitude",
	   longitude as "Longitude"
from silver.wiki_mtns
where {{Mountain}}