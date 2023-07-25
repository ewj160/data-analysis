-- Database is not in multi-user mode.
if exists (select 1 from sys.databases where user_access_desc <> 'MULTI_USER') begin
	select d.name as [Not Multi-User Database]
	from sys.databases d 
	where d.user_access_desc <> 'MULTI_USER';
end;

-- TODO not using best compatibility level
BEGIN
	declare @TargetCompatibilityLevel tinyint;
	declare @ProductVersion nvarchar(128) = cast(SERVERPROPERTY('productversion') as nvarchar(128));

	if @ProductVersion like '16[.]%' set @TargetCompatibilityLevel = 160; -- 2022
	else if @ProductVersion like '15[.]%' set @TargetCompatibilityLevel = 150; -- 2019
	else if @ProductVersion like '14[.]%' set @TargetCompatibilityLevel = 140; -- 2017
	else if @ProductVersion like '13[.]%' set @TargetCompatibilityLevel = 130; -- 2016
	else if @ProductVersion like '12[.]%' set @TargetCompatibilityLevel = 120; -- 2014
	else if @ProductVersion like '11[.]%' set @TargetCompatibilityLevel = 110; -- 2012
	else set @TargetCompatibilityLevel = 0;

	if exists (select 1 from sys.databases where compatibility_level <> @TargetCompatibilityLevel) begin
		select d.name as [Database Name]
		, d.compatibility_level as [Current Compatibility Level]
		, @TargetCompatibilityLevel as [Target Compatibility Level]
		from sys.databases d 
		where d.compatibility_level <> @TargetCompatibilityLevel;
	end
END

-- *************** single database ***************
-- Field is not using default collation.  Note: always encrypted uses *_BIN, except 2022+ randomize with secure enclaves also supports *_UTF8.
BEGIN
	declare @DatabaseCollation nvarchar(128) = cast(DATABASEPROPERTYEX(DB_NAME(), 'collation') as nvarchar(128));

	if exists (
		select 1
		from sys.all_objects all_tables
			inner join sys.schemas on (all_tables.schema_id = schemas.schema_id)
			inner join sys.all_columns columns on (all_tables.object_id = columns.object_id)
			inner join sys.types on (columns.user_type_id = types.user_type_id)
		where types.name in ('char','nchar','varchar','nvarchar')
			and all_tables.is_ms_shipped = 0
			and @DatabaseCollation <> columns.collation_name 
	) begin
		-- Fields
		select schemas.name as [Schema Name]
		, all_tables.name as [Table Name]
		, columns.name as [Column Name]
		, types.name as [Field Type]
		, @DatabaseCollation as [Default Collation]
		, columns.collation_name as [Column Collation]
		, columns.encryption_type_desc as [Encrypted Type]
		from sys.all_objects all_tables
			inner join sys.schemas on (all_tables.schema_id = schemas.schema_id)
			inner join sys.all_columns columns on (all_tables.object_id = columns.object_id)
			inner join sys.types on (columns.user_type_id = types.user_type_id)
		where types.name in ('char','nchar','varchar','nvarchar')
			and all_tables.is_ms_shipped = 0
			and @DatabaseCollation <> columns.collation_name 
		order by [Schema Name], [Table Name], columns.column_id;
	end
end;

-- Query store not in desired state.  Ex: Q.S. read only since maxed out storage.
if exists (select 1 from sys.database_query_store_options where actual_state <> desired_state) begin
	SELECT desired_state_desc, actual_state_desc
	FROM sys.database_query_store_options;
end;

-- Nearing max capacity.
if exists (SELECT 1 FROM sys.database_query_store_options where cast(current_storage_size_mb as decimal) / max_storage_size_mb > 0.75) begin
	SELECT current_storage_size_mb, max_storage_size_mb
	FROM sys.database_query_store_options;
end;
