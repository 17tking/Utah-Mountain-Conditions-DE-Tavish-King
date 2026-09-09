-- Getting the apparent temperature for the current date
--
select d.mountain_id,
	   m.mountain_name,
	   m.mountain_range,
	   d.create_date,
	   d.forecast_date,
	   d.measured_at,
	   (d.apparent_temperature_min_celsius * 1.8) + 32 as feelslike_min_f,
       (d.apparent_temperature_mean_celsius * 1.8) + 32 as feelslike_mean_f,
	   (d.apparent_temperature_max_celsius * 1.8) + 32 as feelslike_max_f
from silver.daily as d
left join silver.mountains m on m.mountain_id = d.mountain_id
where forecast_date = current_date
and {{Mountain}} --metabase filter parameter (mtn_name)
order by d.mountain_id
;