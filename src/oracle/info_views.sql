/*
# View
*/
select views.OWNER as "Schema Name"
, views.VIEW_NAME as "View Name"
, views.TEXT as "Definition"
, objects.CREATED as "Created On"
, objects.LAST_DDL_TIME as "Modified On"
, objects.TIMESTAMP as "Timestamp for the specification of the object"
, objects.STATUS as "Status"
, case when objects.TEMPORARY = 'Y' then 'Yes' else 'No' end as "Is Temporary"
, case when objects.GENERATED = 'Y' then 'Yes' else 'No' end as "Is Generated"
from ALL_VIEWS views
	left join ALL_OBJECTS objects on (views.OWNER = objects.OWNER and views.VIEW_NAME = objects.OBJECT_NAME)
order by OWNER, VIEW_NAME;

select tc.OWNER as "Schema Name"
, tc.TABLE_NAME as "View Name"
, tc.COLUMN_NAME as "Column Name"
, tc.DATA_TYPE as "Data Type"
, tc.DATA_LENGTH as "Data Length"
, tc.char_length as "Char Length"
, tc.DATA_PRECISION as "Data Precision"
, tc.DATA_SCALE as "Data Scale"
, case tc.NULLABLE when 'Y' then 'Yes' when 'N' then 'No' else null end as "Is Nullable"
, tc.DATA_DEFAULT as "Default Value"
, cmts.COMMENTS as "Column Comments"
-- v12+ identity columns
, case when tic.TABLE_NAME is not null then 'Yes' else 'No' end as "Is Identity"
, tic.GENERATION_TYPE as "Increment Generation Type"
, tic.SEQUENCE_NAME as "Increment Sequence Name"
, tic.IDENTITY_OPTIONS as "Increment Options"
from ALL_TAB_COLUMNS tc
    inner join ALL_VIEWS on (tc.OWNER = all_views.OWNER and tc.TABLE_NAME = all_views.TABLE_NAME)
    left join ALL_COL_COMMENTS cmts on (tc.OWNER = cmts.OWNER and tc.TABLE_NAME = cmts.TABLE_NAME and tc.COLUMN_NAME = cmts.COLUMN_NAME)
    -- v12+
    left join ALL_TAB_IDENTITY_COLS tic on (tc.OWNER = tic.OWNER and tc.TABLE_NAME = tic.TABLE_NAME and tc.COLUMN_NAME = tic.COLUMN_NAME)
order by tc.OWNER, tc.TABLE_NAME, tc.COLUMN_ID;

select OWNER as "Schema Name"
, TABLE_NAME as "View Name"
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
where BASE_OBJECT_TYPE = 'VIEW'
order by OWNER, TABLE_NAME, TRIGGER_NANE, COLUMN_NAME;