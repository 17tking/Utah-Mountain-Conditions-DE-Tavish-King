/*

Script Purpose:
	Inserting bronze.openweather_alerts data into silver layer with constraints for idempotency.

*/

insert into silver.openweather_alerts (mtn_id, latitude, longitude, alert_sender_name, alert_event, alert_start, alert_end, alert_description, alert_tags)
select
  mtn_id,
  latitude,
  longitude,
  alert -> 'alert' ->> 'sender_name' as alert_sender_name,
  alert -> 'alert' ->> 'event' as alert_event,
  to_timestamp((alert -> 'alert' ->> 'start')::bigint) as alert_start,
  to_timestamp((alert -> 'alert' ->> 'end')::bigint) as alert_end,
  alert -> 'alert' ->> 'description' as alert_description,
  alert -> 'alert' -> 'tags' as alert_tags
from bronze.openweather_alerts
where alert ? 'alert'
on conflict (mtn_id, alert_event, alert_start) do update
set
  alert_end = excluded.alert_end,
  alert_description = excluded.alert_description,
  alert_tags = excluded.alert_tags;
