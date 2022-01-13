/*
# Add temporial to existing table with primary key.

* Keep history tables in separate schema for permission isolation: 
	* Do not need to grant select permission to application users that only will need to use "live" data / no history.
	* Database managed insert to history table so user does not permission to populate main table with corresponding history entries.
* Enable retention policy that aligns with organization.
*/

-- Create isolated schema for history tables.
if not exists (select 1 from sys.schemas where name='dbo_history') begin
	exec sp_executesql N'create schema dbo_history';
end;
go

-- if needed, enable retention policy
if not exists (select 1 from sys.databases where DB_ID() = database_id and is_temporal_history_retention_enabled = 1) begin
	alter database CURRENT set TEMPORAL_HISTORY_RETENTION on;
end;
go

-- add periods with default value constraints to initialize
alter table dbo.AWBuildVersion add
    SysStartTime datetime2(7) generated always as row start hidden not null constraint DeleteMe_DV01 default sysutcdatetime(),
    SysEndTime datetime2(7) generated always as row end hidden not null constraint DeleteMe_DV02 default convert(datetime2(7), '9999-12-31 23:59:59.9999999'),
    period for system_time (SysStartTime, SysEndTime);

-- drop initializing default value constraints
alter table dbo.AWBuildVersion drop constraint DeleteMe_DV01;
alter table dbo.AWBuildVersion drop constraint DeleteMe_DV02;

-- enable history
alter table dbo.AWBuildVersion set (
	SYSTEM_VERSIONING = ON (
		HISTORY_TABLE = dbo_history.AWBuildVersion,
		DATA_CONSISTENCY_CHECK = on,
		HISTORY_RETENTION_PERIOD = 5 years -- adjust for retention policy
	)
);

GO