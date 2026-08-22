-- Getting the # of alerts for a given mtn. Concatenation of alert types + Min Start Date and Max End Date
--
select d.mountain_id,
	   m.mountain_name,
	   m.mountain_range,
	   d.forecast_date,
	   a.alert_count,
	   a.event_name,
	   a.start at time zone 'America/Denver' as start,
	   a.end at time zone 'America/Denver' as end
from silver.daily d
left join silver.mountains m on m.mountain_id = d.mountain_id
left join 
(
	select mountain_id,
	count(*) as alert_count,
	min(start_time) as start,
    max(end_time) as end,
	string_agg(event_name, ' | ') as event_name
	from silver.alerts
	where start_time <= now() and end_time >= now()
	group by mountain_id
) as a on a.mountain_id = d.mountain_id
where forecast_date = current_date
and {{Mountain}}
order by mountain_id
;