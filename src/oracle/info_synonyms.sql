/*
# Synonyms
*/

select s.SYNONYM_NAME as "Name"
, s.TABLE_OWNER as "Target Schema"
, s.TABLE_NAME as "Target Name"
, s.DB_LINK as "Target Link"
, o.CREATED as "Created On"
, o.STATUS as "Status"
, o.LAST_DDL_TIME as "Modified On"
, case when o.TEMPORARY = 'Y' then 'Yes' else 'No' end as "Is Temporary"
from ALL_SYNONYMS s
	inner join ALL_OBJECTS o on (s.OBJECT_ID = s.OBJECT_ID)
order by SYNONYM_NAME;