-- Rename Table
alter table old_name
rename to new_name


-- Rename Columns
alter table table_name
rename column old_col to new_col


-- Add or Drop Column
alter table table_name
add column new_col
-- or --
drop column existing_col


-- Add or Drop Primary Key Constraint
alter table table_name
drop constraint constraint_name
-- or -- 
add constraint constraint_name PRIMARY KEY (column_name) --must not be NULL


-- Change Data Type of Column
alter table table_name
alter column col_name TYPE new_data_type