/*
# Dimensions
*/

select OWNER as "Schema Name"
, DIMENSION_NAME as "Dimension Name"
, case when INVALID = 'Y' then 'Yes' else 'No' end as "Is Invalid"
, REVISION as "Dimension revision level"
, COMPILE_STATE as "Compile Status"
from ALL_DIMENSIONS
order by OWNER, DIMENSION_NAME;
