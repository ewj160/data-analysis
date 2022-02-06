/*
# Sequences
*/

select s.SEQUENCE_OWNER as "Schema Name"
, s.SEQUENCE_NAME as "Sequence Name"
, s.MIN_VALUE as "Min Value"
, s.MAX_VALUE as "Max Value"
, s.INCREMENT_BY as "Increment By"
, case when s.CYCLE_FLAG = 'Y' then 'Yes' else 'No' end as "Is Cycle"
, s.CACHE_SIZE as "Cache Size"
, s.LAST_NUMBER as "Last Number"
, obj.CREATED as "Created On"
, obj.STATUS as "Status"
, obj.LAST_DDL_TIME as "Modified On"
, case when obj.TEMPORARY = 'Y' then 'Yes' else 'No' end as "Is Temporary"
from ALL_SEQUENCES s
	inner join ALL_OBJECTS obj on (s.SEQUENCE_OWNER = obj.OWNER and s.SEQUENCE_NAME = obj.OBJECT_NAME and obj.OBJECT_TYPE = 'SEQUENCE')
order by s.SEQUENCE_OWNER, s.SEQUENCE_NAME;
