-- Getting the # of alerts for a given mtn. Concatenation of alert types + Min Start Date and Max End Date
--
select omd.mtn_id,
	   wiki_mtns.mtn_name,
	   wiki_mtns.mtn_range,
	   omd.dly_time,
	   alerts.alert_count,
	   alerts.alert_events,
	   alerts.alert_start at time zone 'America/Denver' as alert_start,
	   alerts.alert_end at time zone 'America/Denver' as alert_end
from silver.openmeteo_daily omd
left join silver.wiki_mtns on wiki_mtns.mtn_id = omd.mtn_id
left join 
(
	select mtn_id,
	count(*) as alert_count,
	min(alert_start) as alert_start,
    max(alert_end) as alert_end,
	string_agg(alert_event, ' | ') as alert_events
	from silver.openweather_alerts
	where alert_start <= now() and alert_end >= now()
	group by mtn_id
) as alerts on alerts.mtn_id = omd.mtn_id
where dly_time = current_date
and {{Mountain}}
order by mtn_id
;