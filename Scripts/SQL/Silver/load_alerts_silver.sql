/*

Script Purpose:
	Inserting bronze.alerts_stg data into silver layer with constraints for idempotency.

Notes:
	This table contains an active and historical alert record.

    Alert times are stored in America/Denver timezone cause thats the timezone I'm in.
    And its my project so yah.

	Latitude and longitude are mountain-level attributes stored in silver.mountains
	and are not repeated here (3NF).

*/

insert into silver.alerts (alert_id, mountain_id, create_date, sender_name, event_name, start_time, end_time, description, alert_tags)
select
    alert_id,
    mountain_id,
	create_date													   				    as create_date,
    alert_json ->> 'sender_name'                                       				as sender_name,
    alert_json ->> 'event'                                             				as event_name,
    to_timestamp((alert_json ->> 'start')::bigint) at time zone 'America/Denver'	as start_time,
    to_timestamp((alert_json ->> 'end')::bigint) at time zone 'America/Denver' 	 	as end_time,
    alert_json ->> 'description'                                       				as description,
    alert_json -> 'tags'                                               				as alert_tags
from bronze.alerts_stg
where alert_json is not null
on conflict (mountain_id, event_name, start_time) do update set
    end_time       = excluded.end_time,
    description    = excluded.description,
    alert_tags     = excluded.alert_tags;