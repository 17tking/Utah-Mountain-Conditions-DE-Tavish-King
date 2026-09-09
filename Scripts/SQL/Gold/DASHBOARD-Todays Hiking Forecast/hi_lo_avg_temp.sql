-- Getting the average, hi, and lo temp in fahrenheit of the current date
--
select d.mountain_id,
	   m.mountain_name,
	   m.mountain_range,
	   d.create_date,
	   d.forecast_date,
	   d.measured_at,
	   (d.temperature_2m_min_celsius * 1.8) + 32 as temp_min_f,
       (d.temperature_2m_mean_celsius * 1.8) + 32 as temp_mean_f,
	   (d.temperature_2m_max_celsius * 1.8) + 32 as temp_max_f
from silver.daily as d
left join silver.mountains m on m.mountain_id = d.mountain_id
where forecast_date = current_date
and {{Mountain}} --metabase filter parameter (mtn_name)
order by d.mountain_id
;