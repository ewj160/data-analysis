
select obj.OWNER as "Schema Name"
, obj.OBJECT_NAME as "Procedure Name"
, obj.CREATED as "Created On"
, obj.LAST_DDL_TIME as "Modified On"
, obj.TIMESTAMP as "Timestamp for the specification of the object"
, obj.STATUS as "Status"
, case when obj.TEMPORARY = 'Y' then 'Yes' else 'No' end as "Is Temporary"
, case when obj.GENERATED = 'Y' then 'Yes' else 'No' end as "Is Generated"
, case when procs.AGGREGATE = 'YES' then 'Yes' else 'No' end as "Is Aggregate"
, case when procs.DETERMINISTIC = 'YES' then 'Yes' else 'No' end as "Is Deterministic"
from ALL_OBJECTS obj
	inner join ALL_PROCEDURES procs on (obj.OBJECT_ID = procs.OBJECT_ID)
where obj.OBJECT_TYPE = 'PROCEDURE'
order by obj.OWNER, obj.OBJECT_NAME;

-- split across multiple lines
select OWNER as "Schema Name"
, NAME as "Procedure Name"
, TEXT as "Definition"
from ALL_SOURCE
where TYPE = 'PROCEDURE'
order by OWNER, NAME, LINE;

select args.OWNER as "Schema Name"
, args.OBJECT_NAME as "Procedure Name"
, args.ARGUMENT_NAME AS "Argument Name"
, case when args.POSITION = 0 /* return */ then null else args.POSITION end as "Parameter Position"
, args.IN_OUT as "In/Out" -- "IN", "OUT", "IN/OUT"
, args.DATA_TYPE as "Data Type"
, case when args.DATA_PRECISION is null then args.DATA_LENGTH else args.DATA_PRECISION end AS "Precision"
, args.DATA_SCALE AS "Scale"
, args.SEQUENCE as "Sequence"
, args.DEFAULT_VALUE as "Default Value"
from ALL_ARGUMENTS args
	inner join ALL_OBJECTS obj on (args.OBJECT_ID = obj.OBJECT_ID)
where args.PACKAGE_NAME is null
	and obj.OBJECT_TYPE = 'PROCEDURE'
order by args.OWNER, args.PACKAGE_NAME, args.OBJECT_NAME, args.SEQUENCE;

/*
# Errors
*/
select OWNER as "Schema Name"
, NAME as "Procedure Name"
, SEQUENCE as "Sequence"
, LINE as "Line"
, POSITION as "Position"
, TEXT as "Error"
from ALL_ERRORS
where TYPE = 'PROCEDURE'
order by OWNER, NAME, SEQUENCE, LINE, POSITION;
