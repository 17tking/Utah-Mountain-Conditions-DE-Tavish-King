/*
=============================================================
DDL Script: Create Gold Tables
=============================================================
Script Purpose:
    The Gold layer stores analysis-ready, aggregated, and
    report data. Tables here are designed for KPIs,
    dashboards, time-series analysis, and statistical outputs.

    This layer is intentionally expansive -- new tables should
    be added as reporting needs evolve (e.g., rapid forecasts,
    anomaly flags, rolling aggregates. research questions, etc).

Notes:
    - All gold tables should derive from silver layer sources.
    - Grain and aggregation level should be documented
      per table in a table-level comment block 
	  		(ex: Grain - one row per mountain per calendar day 
			 OR Grain - one row per mountain all-time).
=============================================================
*/

