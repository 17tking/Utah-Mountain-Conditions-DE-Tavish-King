-- Basic Mountain info to include on dashboard
--
select mountain_name as "Mountain",
	   mountain_range as "Mountain Range", 
	   elevation_ft as "Elevation (ft)", 
	   prominence_ft as "Prominence (ft)",
	   mountain_latitude as "Latitude",
	   mountain_longitude as "Longitude"
from silver.mountains
where {{Mountain}}