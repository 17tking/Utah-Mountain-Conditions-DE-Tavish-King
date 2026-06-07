-- Getting today's weather conditions + icon image
-- 
select omd.mtn_id,
	   wiki_mtns.mtn_name,
	   wc.description,
	   wc.image_url
from silver.openmeteo_daily as omd
left join silver.wiki_mtns on wiki_mtns.mtn_id = omd.mtn_id
left join silver.weathercodes as wc on wc.weather_code = omd.dly_weather_code
where dly_time = current_date
and {{Mountain}} --metabase filter parameter (mtn_name)
order by omd.mtn_id
;