-- Getting mean surface pressure (hPa) for current date
--
select omd.dly_surface_pressure_mean_hpa
from silver.openmeteo_daily as omd
left join silver.wiki_mtns on wiki_mtns.mtn_id = omd.mtn_id
where dly_time = current_date
and {{Mountain}}
order by omd.mtn_id;