-- Getting today's weather conditions + icon image
-- 
select d.mountain_id,
	   m.mountain_name,
	   wc.description,
	   wc.image_url
from silver.daily d
left join silver.mountains m on m.mountain_id = d.mountain_id
left join silver.weathercodes wc on wc.weather_code = d.weather_code
where forecast_date = current_date
and {{Mountain}} --metabase filter parameter (mountain_name)
order by d.mountain_id
;