-- Getting rain, showers, snow, probability info for today
--
select d.mountain_id,
       d.precipitation_probability_mean_pct as mean_precipitation_prob,
       ROUND(d.rain_sum_mm / 25.4, 2) as rain_inches,
       ROUND(d.showers_sum_mm / 25.4, 2) as showers_inches,
       ROUND(d.snowfall_sum_cm / 2.54, 2) as snowfall_inches,
       ROUND(d.precipitation_sum_mm / 25.4, 2) as precipitation_inches,
       d.precipitation_hours
from silver.daily as d
left join silver.mountains m on m.mountain_id = d.mountain_id
where forecast_date = current_date
and {{Mountain}}
order by d.mountain_id
;

-- Hourly Precipitation
--
select omh.mtn_id,
	   to_char(omh.hrly_time, 'HH12 AM') AS hour_time,
	   omh.hrly_precipitation_probability_pct
from silver.openmeteo_hourly as omh
left join silver.mountains m on m.mountain_id = omh.mtn_id
where date(omh.hrly_time) = current_date
and {{Mountain}}
order by omh.mtn_id
;