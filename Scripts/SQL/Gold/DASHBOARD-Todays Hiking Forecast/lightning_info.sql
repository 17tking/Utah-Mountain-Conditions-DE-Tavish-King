-- Getting max lightning potential in jules per kg for today
--
select omd.mtn_id,
	   wiki_mtns.mtn_name,
	   wiki_mtns.mtn_range,
	   omd.pulled_at,
	   omd.dly_time,
	   ltng.max_ltng_potential_j_kg
from silver.openmeteo_daily as omd
left join silver.wiki_mtns on wiki_mtns.mtn_id = omd.mtn_id
-- getting average lightning potential for each mtn_id on current day 
left join 
(
	select mtn_id, 
	ltng_time::date, 
	round(max(coalesce(ltng_potential_j_kg_max, 0)),2) as max_ltng_potential_j_kg
	from silver.openmeteo_lightning
	where ltng_time::date = current_date
	group by mtn_id, ltng_time::date
) as ltng on ltng.mtn_id = omd.mtn_id
where omd.dly_time = current_date
and {{Mountain}}
order by omd.mtn_id
;