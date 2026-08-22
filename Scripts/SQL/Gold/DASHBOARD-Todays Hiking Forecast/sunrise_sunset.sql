-- Getting Sunrise and Sunset times for current date (12-hour)
--
select d.mountain_id,
	   m.mountain_name,
	   m.mountain_range,
	   d.create_date,
	   d.forecast_date,
	   (d.sunrise at time zone 'America/Denver')::time as sunrise,
	   (d.sunset at time zone 'America/Denver')::time as sunset
from silver.daily as d
left join silver.mountains m on m.mountain_id = d.mountain_id
where forecast_date = current_date
and {{Mountain}} --metabase filter parameter (mtn_name)
order by d.mountain_id