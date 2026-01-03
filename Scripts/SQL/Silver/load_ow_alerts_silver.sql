/*

Script Purpose:
	Inserting bronze.openweather_alerts data into silver layer with constraints for idempotency.

Notes:
	This table contains only active, live alerts and does not maintain a historical 
	record, as weather alerts are time-bound and will not require long-term analysis.

*/

insert into silver.openweather_alerts (mtn_id, latitude, longitude, alert_sender_name, alert_event, alert_start, alert_end, alert_description, alert_tags)
select
  mtn_id,
  latitude,
  longitude,
  alert ->> 'sender_name' as alert_sender_name,
  alert ->> 'event' as alert_event,
  to_timestamp((alert ->> 'start')::bigint) as alert_start,
  to_timestamp((alert ->> 'end')::bigint) as alert_end,
  alert ->> 'description' as alert_description,
  alert -> 'tags' as alert_tags
from bronze.openweather_alerts
where alert is not null
on conflict (mtn_id, alert_event, alert_start) do update
set
  alert_end = excluded.alert_end,
  alert_description = excluded.alert_description,
  alert_tags = excluded.alert_tags;
