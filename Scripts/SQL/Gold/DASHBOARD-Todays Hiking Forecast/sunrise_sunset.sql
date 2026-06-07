-- Getting Sunrise and Sunset times for current date (12-hour)
--
select omd.mtn_id,
	   wiki_mtns.mtn_name,
	   wiki_mtns.mtn_range,
	   omd.pulled_at,
	   omd.dly_time,
	   (omd.dly_sunrise at time zone 'America/Denver')::time as dly_sunrise,
	   (omd.dly_sunset at time zone 'America/Denver')::time as dly_sunset
from silver.openmeteo_daily as omd
left join silver.wiki_mtns on wiki_mtns.mtn_id = omd.mtn_id
where dly_time = current_date
and {{Mountain}} --metabase filter parameter (mtn_name)
order by omd.mtn_id