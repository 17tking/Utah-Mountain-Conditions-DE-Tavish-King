-- Getting UV index info for the day
select floor(omd.dly_uv_index_max) as uv_index_max,
	   omd.mtn_id,
       wiki_mtns.mtn_name,
       omd.dly_time
from silver.openmeteo_daily omd
left join silver.wiki_mtns on wiki_mtns.mtn_id = omd.mtn_id
where dly_time = current_date
and {{Mountain}}
order by omd.mtn_id
;





