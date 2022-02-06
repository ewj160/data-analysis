/*
# Schema / User
*/

select USERNAME as "User / Schema"
, CREATED as "Created"
, EXPIRY_DATE as "Expiry Date"
, ACCOUNT_STATUS as "Account Status"
, EXTERNAL_NAME as "External Name"
, DEFAULT_TABLESPACE as "Default Tablespace"
, TEMPORARY_TABLESPACE as "Temporary Tablespace"
, PROFILE as "Profile" -- DBA_ view only
from ALL_USERS u
where exists (
		select 1
		from ALL_OBJECTS o
		where o.OWNER = u.USERNAME
	)
	and ACCOUNT_STATUS='OPEN'
	and ORACLE_MAINTAINED='N'
order by 1;
