/*
# Server Information
*/
-- version information
select VERSION "Version"
from PRODUCT_COMPONENT_VERSION 
where PRODUCT like 'Oracle%';

select INSTANCE_NAME as "Instance Name"
, HOST_NAME as "Host Name"
, VERSION as "Version"
from V$INSTANCE;

select BANNER as "Banner"
from V$VERSION
order by 1;

select NAME as "Parameter Name"
, DISPLAY_VALUE as "Value"
, DESCRIPTION as "Description"
from V$PARAMETER
order by NAME;

SELECT GLOBAL_NAME as "Database"
FROM GLOBAL_NAME;
