/*
# Database Links
*/

select OWNER as "Schema Name"
, DB_LINK as "Database Link Name"
, USERNAME as "User Name"
, HOST as "Host"
, CREATED as "Created On"
from ALL_DB_LINKS
order by OWNER, DB_LINK;