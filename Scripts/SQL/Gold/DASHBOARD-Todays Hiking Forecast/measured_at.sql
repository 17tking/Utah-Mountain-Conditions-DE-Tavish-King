-- Getting where the weather data was measured at in feet for the current date
--
select omd.mtn_id,
	   wiki_mtns.mtn_name,
	   wiki_mtns.mtn_range,
	   omd.dly_time,
	   omd.measured_at_m * 3.28084 as measured_at_ft
from silver.openmeteo_daily as omd
left join silver.wiki_mtns on wiki_mtns.mtn_id = omd.mtn_id
where dly_time = current_date
and {{Mountain}} --metabase filter parameter (mtn_name)
order by omd.mtn_id