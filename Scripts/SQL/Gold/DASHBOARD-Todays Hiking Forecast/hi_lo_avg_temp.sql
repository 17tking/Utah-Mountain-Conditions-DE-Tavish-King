-- Getting the average, hi, and lo temp in fahrenheit of the current date
--
select omd.mtn_id,
	   wiki_mtns.mtn_name,
	   wiki_mtns.mtn_range,
	   omd.pulled_at,
	   omd.dly_time,
	   omd.measured_at_m,
	   (omd.dly_temperature_2m_min_celsius * 1.8) + 32 as temp_min_f,
       (omd.dly_temperature_2m_mean_celsius * 1.8) + 32 as temp_mean_f,
	   (omd.dly_temperature_2m_max_celsius * 1.8) + 32 as temp_max_f
from silver.openmeteo_daily as omd
left join silver.wiki_mtns on wiki_mtns.mtn_id = omd.mtn_id
where dly_time = current_date
and {{Mountain}} --metabase filter parameter (mtn_name)
order by omd.mtn_id
;