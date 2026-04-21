-- Putting together a table of max wind speed, gusts, and direction
--
select omd.mtn_id,
	   wiki_mtns.mtn_name,
	   wiki_mtns.mtn_range,
	   omd.dly_time,
	   CONCAT(
    	ROUND(omd.dly_wind_speed_10m_min_kmh * 0.62137119223733, 0), 
    	' - ', 
    	ROUND(omd.dly_wind_speed_10m_max_kmh * 0.62137119223733, 0), ' mph') AS "Wind Speeds",
	   omd.dly_wind_gusts_10m_max_kmh * 0.62137119223733 as "Max Gusts",
	   CONCAT(
    	omd.dly_wind_direction_10m_dominant,
    	'° ',
    	CASE 
        WHEN omd.dly_wind_direction_10m_dominant >= 337.5 OR omd.dly_wind_direction_10m_dominant < 22.5 THEN 'N'
        WHEN omd.dly_wind_direction_10m_dominant >= 22.5 AND omd.dly_wind_direction_10m_dominant < 67.5 THEN 'NE'
        WHEN omd.dly_wind_direction_10m_dominant >= 67.5 AND omd.dly_wind_direction_10m_dominant < 112.5 THEN 'E'
        WHEN omd.dly_wind_direction_10m_dominant >= 112.5 AND omd.dly_wind_direction_10m_dominant < 157.5 THEN 'SE'
        WHEN omd.dly_wind_direction_10m_dominant >= 157.5 AND omd.dly_wind_direction_10m_dominant < 202.5 THEN 'S'
        WHEN omd.dly_wind_direction_10m_dominant >= 202.5 AND omd.dly_wind_direction_10m_dominant < 247.5 THEN 'SW'
        WHEN omd.dly_wind_direction_10m_dominant >= 247.5 AND omd.dly_wind_direction_10m_dominant < 292.5 THEN 'W'
        WHEN omd.dly_wind_direction_10m_dominant >= 292.5 AND omd.dly_wind_direction_10m_dominant < 337.5 THEN 'NW'
    END
) AS "Direction"
from silver.openmeteo_daily as omd
left join silver.wiki_mtns on wiki_mtns.mtn_id = omd.mtn_id
where dly_time = current_date
and {{Mountain}}
order by mtn_id;