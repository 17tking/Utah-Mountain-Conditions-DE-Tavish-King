/*

Script Purpose:
	Inserting bronze.openweather_alerts data into silver layer with constraints for idempotency.

Notes:
	This table contains only active, live alerts and does not maintain a historical 
	record, as weather alerts are time-bound and will not require long-term analysis.

	Unix timestamps are cast to timestamptz explicitly in UTC to avoid timezone
	drift if the Postgres server timezone is ever changed.

	latitude and longitude are mountain-level attributes stored in silver.wiki_mtns
	and are not repeated here (3NF).

*/

insert into silver.openweather_alerts (mtn_id, alert_sender_name, alert_event, alert_start, alert_end, alert_description, alert_tags)
select
    mtn_id,
    alert ->> 'sender_name'                                       as alert_sender_name,
    alert ->> 'event'                                             as alert_event,
    to_timestamp((alert ->> 'start')::bigint) at time zone 'UTC'  as alert_start,
    to_timestamp((alert ->> 'end')::bigint) at time zone 'UTC'    as alert_end,
    alert ->> 'description'                                       as alert_description,
    alert -> 'tags'                                               as alert_tags
from bronze.openweather_alert
where alert is not null
on conflict (mtn_id, alert_event, alert_start) do update set
    alert_end         = excluded.alert_end,
    alert_description = excluded.alert_description,
    alert_tags        = excluded.alert_tags;