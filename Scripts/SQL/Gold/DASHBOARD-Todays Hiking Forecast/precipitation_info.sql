-- Getting rain, showers, snow, probability info for today
--
select 
      omd.dly_precipitation_probability_mean_pct as mean_precipitation_prob,
      omd.dly_rain_sum_mm,
      omd.dly_showers_sum_mm,
      omd.dly_snowfall_sum_cm,
      omd.dly_precipitation_sum_mm,
      omd.dly_precipitation_hours
from silver.openmeteo_daily as omd
left join silver.wiki_mtns on wiki_mtns.mtn_id = omd.mtn_id
where dly_time = current_date
and {{Mountain}}
order by omd.mtn_id
;

-- Hourly Precipitation
--
select omh.mtn_id,
	   to_char(omh.hrly_time, 'HH12 AM') AS hour_time,
	   omh.hrly_precipitation_probability_pct
from silver.openmeteo_hourly as omh
left join silver.wiki_mtns on wiki_mtns.mtn_id = omh.mtn_id
where date(omh.hrly_time) = current_date
and {{Mountain}}
order by omh.mtn_id
;