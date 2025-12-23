/*
============================
Create Database and Schemas
============================
PostgreSQL

Script Purpose:
    This script creates a new database named 'utahmountains'. 
    Additionally, the script sets up three schemas within the database: 'bronze', 'silver', and 'gold'.

Note:
	- This script only needs to be ran once. 
	- Before running the schema lines, manually change query tool connection to 'utahmountains' database.
*/

-- Create Database 'utahmountains'
create database utahmountains;

-- now manually connect to 'utahmountains' database. --

-- Create Schemas
create schema bronze;
create schema silver;
create schema gold;
create schema meta;