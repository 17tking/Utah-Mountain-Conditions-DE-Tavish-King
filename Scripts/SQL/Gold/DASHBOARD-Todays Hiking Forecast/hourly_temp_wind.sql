-- Hourly temperature and wind speeds throughout the current day
--
select to_char(omh.hrly_time, 'HH12 AM') AS hour_time,
	   round((omh.hrly_temperature_2m_celsius * 1.8) + 32, 0) as hrly_temp_f,
	   round((omh.hrly_apparent_temperature_celsius *1.8) + 32, 0) as hrly_feelslike_f,
       round(omh.hrly_wind_speed_10m_kmh * 0.62137119223733, 0) as hrly_wind_mph,
       round(omh.hrly_wind_gusts_10m_kmh * 0.62137119223733, 0) as hrly_gusts_mph
from silver.openmeteo_hourly omh
left join silver.wiki_mtns on wiki_mtns.mtn_id = omh.mtn_id
where date(omh.hrly_time) = current_date
and {{Mountain}}
order by omh.mtn_id;