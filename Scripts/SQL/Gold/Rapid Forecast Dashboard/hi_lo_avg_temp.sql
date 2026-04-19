-- Getting the average, hi, and lo temp of the current day
--
select omd.mtn_id,
	   wm.mtn_name,
	   wm.mtn_range,
	   omd.pulled_at,
	   omd.dly_time,
	   omd.measured_at_m,
	   omd.dly_temperature_2m_min_celsius,
       omd.dly_temperature_2m_mean_celsius,
	   omd.dly_temperature_2m_max_celsius
from silver.openmeteo_daily as omd
left join silver.wiki_mtns on wiki_mtns.mtn_id = omd.mtn_id
where dly_time = current_date
and {{mountain}} --metabase filter parameter (mtn_name)
order by mtn_id
;