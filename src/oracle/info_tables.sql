/*
# Table
*/
select t.OWNER as "Schema Name"
, t.OBJECT_NAME as "Table Name"
, tc.COMMENTS as "Table Description"
, t.CREATED as "Created On"
, t.LAST_DDL_TIME as "Modified On"
, t.TIMESTAMP as "Timestamp for the specification of the object"
, t.STATUS as "Status" -- VALID, INVALID, N/A
, case when t.TEMPORARY = 'Y' then 'Yes' else 'No' end as "Is Temporary"
, case when t.GENERATED = 'Y' then 'Yes' else 'No' end as "Is Generated"
-- basic row stats
, tables.NUM_ROWS as "Num Rows"
, tables.BLOCKS as "Num Blocks"
, tables.LAST_ANALYZED as "Last Analyzed"
from ALL_OBJECTS t
    left join ALL_TAB_COMMENTS tc on (t.OWNER = tc.OWNER and t.OBJECT_NAME = tc.TABLE_NAME)
    left join all_tables TABLES on (t.OWNER = tables.OWNER and t.OBJECT_NAME = tables.TABLE_NAME)
where t.OBJECT_TYPE='TABLE'
order by t.OWNER, t.OBJECT_NAME;

select tc.OWNER as "Schema Name"
, tc.TABLE_NAME as "Table Name"
, tc.COLUMN_NAME as "Column Name"
, tc.DATA_TYPE as "Data Type"
, tc.DATA_LENGTH as "Data Length"
, tc.char_length as "Char Length"
, tc.DATA_PRECISION as "Data Precision"
, tc.DATA_SCALE as "Data Scale"
, case when tc.DATA_TYPE like '%CHAR%' then tc.CHAR_LENGTH when tc.DATA_TYPE = 'NUMBER' then tc.DATA_PRECISION else null end as "Precision"
, case when tc.DATA_TYPE = 'NUMBER' then tc.DATA_SCALE else null end as "Scale"
, case tc.NULLABLE when 'Y' then 'Yes' when 'N' then 'No' else null end as "Is Nullable"
, tc.DATA_DEFAULT as "Default Value"
, cmts.COMMENTS as "Column Comments"
-- v12+ identity columns
, case when tic.TABLE_NAME is not null then 'Yes' else 'No' end as "Is Identity"
, tic.GENERATION_TYPE as "Increment Generation Type"
, tic.SEQUENCE_NAME as "Increment Sequence Name"
, tic.IDENTITY_OPTIONS as "Increment Options"
from ALL_TAB_COLUMNS tc
    left join ALL_COL_COMMENTS cmts on (tc.OWNER = cmts.OWNER and tc.TABLE_NAME = cmts.TABLE_NAME and tc.COLUMN_NAME = cmts.COLUMN_NAME)
    -- v12+
    left join all_TAB_IDENTITY_COLS tic on (tc.OWNER = tic.OWNER and tc.TABLE_NAME = tic.TABLE_NAME and tc.COLUMN_NAME = tic.COLUMN_NAME)
order by tc.OWNER, tc.TABLE_NAME, tc.COLUMN_ID;

select OWNER as "Schema Name"
, TABLE_NAME as "Table Name"
, CONSTRAINT_NAME as "Constraint Name"
, case when CONSTRAINT_TYPE = 'P' then 'Primary' else 'Unique' end as "Constraint Type"
, case when GENERATED = 'GENERATED NAME' or constraint_name like 'SYS_C%"' then 'Yes' else 'No' end as "Is Generated"
, case when status = 'ENABLED' then 'Yes' else 'No' end as "Is Enabled"
, case when VALIDATED = 'VALIDATED' then 'Yes' else 'No' end as "Is Validated"
from ALL_CONSTRAINTS
where CONSTRAINT_TYPE in ('P','U')
order by OWNER, TABLE_NAME, CONSTRAINT_NAME;

select OWNER as "Schema Name"
, TABLE_NAME as "Table Name"
, CONSTRAINT_NAME as "Constraint Name"
, case when GENERATED = 'GENERATED NAME' then 'Yes' else 'No' end as "Is Generated"
, case when STATUS = 'ENABLED' then 'Yes' else 'No' end as "Is Enabled"
, case when VALIDATED = 'VALIDATED' then 'Yes' else 'No' end as "Is Validated"
, SEARCH_CONDITION as "Search Condition"
from ALL_CONSTRAINTS
where CONSTRAINT_TYPE = 'C'
order by OWNER, TABLE_NAME, CONSTRAINT_NAME;

select OWNER as "Schema Name"
, TABLE_NAME as "Table Name"
, CONSTRAINT_NAME as "Index Name"
, COLUMN_NAME as "Column Name"
, POSITION as "Column Position"
from ALL_CONS_COLUMNS
order by OWNER, TABLE_NAME, CONSTRAINT_NAME, COLUMN_NAME;

select ind.TABLE_OWNER as "Schema Name"
, ind.TABLE_NAME as "Table Name"
, ind.INDEX_NAME as "Index Name"
, case when ind.UNIQUENESS = 'UNIQUE' then "Yes" else "No" end as "In Unique"
, case when ind.STATUS = 'VALID' then 'Yes' else 'No' end as "Is Validated"
, case when c.GENERATED = 'GENERATED NAME' or ind.INDEX_NAME like 'SYS_C%' then 'Yes' else 'No' end as "Is Generated"
, case when c.VALIDATED is null then null when c.VALIDATED = 'VALIDATED' then 'Yes' else 'No' end as "Is Validated"
, ind.INDEX_TYPE as "Index Type"
from ALL_INDEXES ind
    left join ALL_CONSTRAINTS c on (ind.TABLE_OWNER=c.OWNER and ind.TABLE_NAME=c.TABLE_NAME and ind.INDEX_NAME=c.CONSTRAINT_NAME)
where ind.INDEX_TYPE='NORMAL'
order by ind.TABLE_OWNER, ind.TABLE_NAME, ind.INDEX_NAME;

select OWNER as "Schema Name"
, TABLE_NAME as "Table Name"
, INDEX_NAME as "Index Name"
, COLUMN_NAME as "Column Name"
, COLUMN_POSITION as "Column Position"
from ALL_IND_COLUMNS
order by OWNER, TABLE_NAME, INDEX_NAME, COLUMN_POSITION;

select fkc.POSITION as "KEY_SEQ"
, fk.DELETE_RULE as "DELETE_RULE" -- ex CASCADE
, case when fk.GENERATED = 'GENERATED NAME' then 'Yes' else 'No' end as "Is Generated"
, fk.CONSTRAINT_NAME as "FK_NAME", fk.OWNER as "FKTABLE_SCHEM", fk.TABLE_NAME as "FKTABLE_NAME", fkc.COLUMN_NAME as "FKCOLUMN_NAME"
, pk.CONSTRAINT_NAME as "PK_NAME", pk.OWNER as "PKTABLE_SCHEM", pk.TABLE_NAME as "PKTABLE_NAME", pkc.COLUMN_NAME as "PKCOLUMN_NAME"
, case when fk.STATUS = 'ENABLED' then 'Yes' else 'No' end as "Is Enabled"
, case when fk.VALIDATED = 'VALIDATED' then 'Yes' else 'No' end as "Is Validated"
from ALL_CONSTRAINTS fk
	inner join ALL_CONSTRAINTS pk on (fk.R_CONSTRAINT_NAME=pk.CONSTRAINT_NAME and fk.R_OWNER=pk.OWNER)
	inner join ALL_CONS_COLUMNS fkc on (fk.TABLE_NAME=fkc.TABLE_NAME and fk.CONSTRAINT_NAME=fkc.CONSTRAINT_NAME and fk.OWNER=fkc.OWNER)
	inner join ALL_CONS_COLUMNS pkc on (pk.TABLE_NAME=pkc.TABLE_NAME and pk.CONSTRAINT_NAME=pkc.CONSTRAINT_NAME and fkc.POSITION=pkc.POSITION and pk.OWNER=pkc.OWNER)
where fk.CONSTRAINT_TYPE='R'
order by fk.OWNER, fk.TABLE_NAME, fk.CONSTRAINT_NAME, fkc.POSITION;

select OWNER as "Schema Name"
, TABLE_NAME as "Table Name"
, COLUMN_NAME as "Column Name"
, TRIGGER_NAME as "Trigger Name"
, TRIGGER_BODY as "Trigger Body"
, TRIGGER_TYPE as "Trigger Type"
, TRIGGERING_EVENT as "Triggering Event"
, REFERENCING_NAMES as "Referencing Names"
, WHEN_CLAUSE as "Where Clause"
, case when STATUS = 'ENABLED' then 'Yes' else 'No' end as "Is Enabled"
, DESCRIPTION as "Description"
, ACTION_TYPE as "Action Type" -- CALL || PL/SQL
from ALL_TRIGGERS
where BASE_OBJECT_TYPE = 'TABLE'
order by OWNER, TABLE_ANME, TRIGGER_NANE, COLUMN_NAME;

select OWNER as "Schema Name"
, TABLE_NAME as "Table Name"
, GRANTEE as "Grantee"
, GRANTOR as "Grantor"
, PRIVILEGE as "Privilege"
, case GRANTABLE when 'YES' then 'Yes' when 'NO' then 'No' else null end as "Is Grantable"
, HIERARCHY as "Hierarchy"
from ALL_TAB_PRIVS
order by OWNER, TABLE_NAME, GRANTEE, GRANTOR;
