/*
# Package
*/

select OWNER as "Schema Name"
, OBJECT_NAME as "Package Name"
, CREATED as "Created On"
, LAST_DDL_TIME as "Modified On"
, TIMESTAMP as "Timestamp for the specification of the object"
, STATUS as "Status"
, case when TEMPORARY = 'Y' then 'Yes' else 'No' end as "Is Temporary"
, case when GENERATED = 'Y' then 'Yes' else 'No' end as "Is Generated"
from ALL_OBJECTS
where OBJECT_TYPE = 'PACKAGE'
order by OWNER, OBJECT_NAME;

-- split across multiple lines
select OWNER as "Schema Name"
, NAME as "Package Name"
, TYPE as "Source Type"
, TEXT as "Definition"
from ALL_SOURCE
where TYPE in ('PACKAGE', 'PACKAGE BODY')
order by OWNER, NAME, TYPE, LINE;

select distinct OWNER as "Schema Name"
, PACKAGE_NAME as "Package Name"
, OBJECT_NAME as "Procedure Name"
from ALL_ARGUMENTS
where PACKAGE_NAME is not null
order by OWNER, PACKAGE_NAME, OBJECT_NAME;

select OWNER as "Schema Name"
, PACKAGE_NAME  as "Package Name"
, OBJECT_NAME as "Procedure Name"
, ARGUMENT_NAME AS "Argument Name"
, case when POSITION = 0 /* return */ then null else POSITION end as "Parameter Position"
, IN_OUT as "In/Out" -- "IN", "OUT", "IN/OUT"
, DATA_TYPE as "Data Type"
, case when args.DATA_PRECISION is null then args.DATA_LENGTH else args.DATA_PRECISION end AS "Precision"
, DATA_SCALE AS "Scale"
, SEQUENCE as "Sequence"
, DEFAULT_VALUE as "Default Value"
from ALL_ARGUMENTS
where PACKAGE_NAME is not null
order by OWNER, PACKAGE_NAME, OBJECT_NAME, SEQUENCE;

/*
# Package errors
*/
select OWNER as "Schema Name"
, NAME as "Package Name"
, TYPE as "Package Type"
, SEQUENCE as "Sequence"
, LINE as "Line"
, POSITION as "Position"
, TEXT as "Error"
from ALL_ERRORS
where TYPE in ('PACKAGE', 'PACKAGE BODY')
order by OWNER, NAME, TYPE, SEQUENCE, LINE, POSITION;
