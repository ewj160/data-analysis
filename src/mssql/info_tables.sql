/*
# Table Information

Usage:
1. Adjust @SchemaName and @TableName for specific table to view information, or set to null for all (bulk analysis).
2. Set @IncludeInternalTables to 1 to include internal tables, or leave 0 (default) to exclude internal tables.
3. Set @IncludeSystemTables to 1 to include system tables, or leave 0 (default) to exclude system tables.
*/

set nocount on;
begin
    -- setup
    declare @SchemaName SYSNAME = null; -- schema name to filter, or null for any.
    declare @TableName SYSNAME = null; -- table name to filter, or null for any.
    declare @IncludeInternalTables bit = 0; -- 1 to include internal tables, 0 to exclude.
    declare @IncludeSystemTables bit = 0; -- 1 to include system tables, 0 to exclude.

    -- Run
    declare @TableTypes table (Type char(2) Collate Latin1_General_CI_AS_KS_WS not null primary key);

    insert into @TableTypes(Type) values('U'), ('ET');
    if (@IncludeInternalTables = 1) 
        insert into @TableTypes(Type) values('IT');
    if (@IncludeSystemTables = 1) 
        insert into @TableTypes(Type) values('S');

    -- General table attributes
    select all_tables.object_id
    , schemas.name as [Schema Name]
    , all_tables.name as [Table Name]
    , all_tables.create_date as [Created On]
    , all_tables.modify_date as [Modified On]
    , all_tables.type_desc as [Table Type]
    -- user tables
    , case when user_tables.is_tracked_by_cdc = 1 then 'Yes' else 'No' end as [Is Tracked by CDC]
    , case when change_tracking_tables.is_track_columns_updated_on = 1 then 'Yes' else 'No' end as [Is Track Columns Updated On]
    , change_tracking_tables.min_valid_version as [CTT Min Valid Version]
    , change_tracking_tables.begin_version as [CTT Begin Version]
    , change_tracking_tables.cleanup_version as [CTT Cleanup Version]
    , case when objectproperty(all_tables.object_id, N'TableHasVarDecimalStorageFormat') = 1 then 'Yes' else 'No' end as [Is Vardecimal Enabled]
    , case when user_tables.is_memory_optimized = 1 then 'Yes' else 'No' end as [Is Memory Optimized]
    , user_tables.durability_desc as [Durability] 
    , case when user_tables.is_external = 1 then 'Yes' else 'No' end as [Is External]
    , p.data_compression_desc as [Data Compression]
    -- temporial
    , case when user_tables.temporal_type_desc<>'' then user_tables.temporal_type_desc else null end as [Temporal Type] 
    , history_start_period.Column_Name as [History Start Period]
    , history_end_period.Column_Name as [History End Period]
    , case when history_table.name is not null then history_schema.name + '.' + history_table.name else null end as [History Table] 
    , case when user_tables.temporal_type = 2 and user_tables.history_retention_period_unit <> -1 then user_tables.history_retention_period else null end as [History Retention Period] 
    , case when user_tables.temporal_type = 2 and user_tables.history_retention_period_unit <> -1 then user_tables.history_retention_period_unit_desc else null end as [History Retention Period Unit]
    -- graphs
    , case when user_tables.is_node = 1 then 'Yes' else 'No' end as [Is Node]
    , case when user_tables.is_edge = 1 then 'Yes' else 'No' end as [Is Edge]
    -- ledger
    --, user_tables.ledger_type
    , user_tables.ledger_type_desc as [Ledger Type]
    , case when ledger_view_table.name is not null then ledger_view_schema.name + '.' + ledger_view_table.name else null end as [Ledger View]
    , case when user_tables.is_dropped_ledger_table = 1 then 'Yes' else 'No' end as [Is Dropped Ledger Table]
    -- internal tables
    , internal_tables.internal_type_desc as [Internal Type]
    , table_comment.VALUE as [Table Description]
    from sys.all_objects all_tables
        inner join @TableTypes table_types on (all_tables.type = table_types.Type)
        inner join sys.schemas on (all_tables.schema_id = schemas.schema_id)
        left join sys.tables user_tables on (all_tables.object_id = user_tables.object_id)
        left join sys.internal_tables on (all_tables.object_id = internal_tables.object_id)
        left join sys.change_tracking_tables on (all_tables.object_id = change_tracking_tables.object_id) 
        left join sys.tables history_table on (user_tables.history_table_id = history_table.object_id) 
        left join sys.schemas history_schema on (history_table.schema_id = history_schema.schema_id)
        left join (
            select periods.object_id, columns.name as Column_Name
            from sys.periods
                inner join sys.all_columns columns on (periods.object_id = columns.object_id and periods.start_column_id = columns.column_id)
            where periods.period_type = 1 -- system-time period
        ) history_start_period on (all_tables.object_id = history_start_period.object_id)
        left join (
            select periods.object_id, columns.name as Column_Name
            from sys.periods
                inner join sys.all_columns columns on (periods.object_id = columns.object_id and periods.end_column_id = columns.column_id)
            where periods.period_type = 1 -- system-time period
        ) history_end_period on (all_tables.object_id = history_end_period.object_id)
        outer apply (
            select max(p.data_compression_desc) as data_compression_desc
            from sys.partitions p
            where user_tables.object_id = p.object_id
        ) p
        left join sys.extended_properties table_comment on (table_comment.class = 1 and table_comment.major_id = all_tables.object_id and table_comment.minor_id = 0 and table_comment.name = N'MS_Description')
        -- ledger
        left join sys.all_objects ledger_view_table on (user_tables.ledger_view_id = ledger_view_table.object_id)
        left join sys.schemas ledger_view_schema on (ledger_view_table.schema_id = ledger_view_schema.schema_id)
    where (@SchemaName is null or @SchemaName = schemas.name)
        and (@TableName is null or @TableName = all_tables.name)
    order by [Schema Name], [Table Name]

    -- table attributes
    if exists (
        select 1
        from sys.extended_properties ep
            inner join sys.all_objects all_tables on (ep.major_id = all_tables.object_id)
            inner join @TableTypes table_types on (all_tables.type = table_types.Type)
            inner join sys.schemas on (all_tables.schema_id = schemas.schema_id)
        where (@SchemaName is null or @SchemaName = schemas.name)
            and (@TableName is null or @TableName = all_tables.name)
            and ep.class = 1
            and ep.minor_id = 0
            and ep.name <> N'MS_Description' -- table description
    ) begin
        select schemas.name as [Schema Name]
        , all_tables.name as [Table Name]
        , ep.name as [Attribute Name]
        , ep.value as [Attribute Value]
        from sys.extended_properties ep
            inner join sys.all_objects all_tables on (ep.major_id = all_tables.object_id)
            inner join @TableTypes table_types on (all_tables.type = table_types.Type)
            inner join sys.schemas on (all_tables.schema_id = schemas.schema_id)
        where (@SchemaName is null or @SchemaName = schemas.name)
            and (@TableName is null or @TableName = all_tables.name)
            and ep.class = 1
            and ep.minor_id = 0
            and ep.name <> N'MS_Description' -- table description
        order by [Schema Name], [Table Name], [Attribute Name];
    end;

    -- Fields
    select schemas.name as [Schema Name]
    , all_tables.name as [Table Name]
    , columns.name as [Column Name]
    , types.name as [Field Type]
    , case when columns.max_length != -1 and types.name in ('nchar','nvarchar') then columns.max_length / 2 else columns.max_length end as [Max Length]
    , columns.precision as Precision
    , columns.scale as Scale
    , case when columns.is_nullable = 1 then 'Yes' else 'No' end as [Is Nullable]
    , case when columns.is_identity = 1 then 'Yes' else 'No' end as [Is Identity]
    , identity_columns.seed_value as [SEED Value]
    , identity_columns.increment_value as [Increment Value]
    , identity_columns.last_value as [Last Value]
    , case when columns.is_sparse = 1 then 'Yes' else 'No' end as [Is Sparse]
    , case when columns.is_computed = 1 then 'Yes' else 'No' end as [Is Computed]
    , default_constraints.name as [Default Value Name]
    , default_constraints.definition as [Default Value]
    , case when default_constraints.is_system_named = 1 then 'Yes' else 'No' end as [Is Default Value Name Generated]
    , computed_columns.definition as [Computed Column Definition]
    , case when computed_columns.is_persisted = 1 then 'Yes' else 'No' end as [Computed Is Persisted]
    , case when SERVERPROPERTY('collation') = columns.collation_name then null else columns.collation_name end as [Collation Name]
    , case when columns.generated_always_type <> 0 then columns.generated_always_type_desc else null end as [Generated Always Type]
    , case when columns.is_hidden = 1 then 'Yes' else 'No' end as [Is Hidden]
    , case when masked_columns.is_masked = 1 then 'Yes' else 'No' end as [Is Masked]
    , masked_columns.masking_function as [Masking Function]
    , columns.encryption_type_desc as [Encrypted Type]
    , cek.name as [Column Encyption Key]
    , columns.encryption_algorithm_name as [Encyption Algorithm Name]
    , columns.graph_type_desc as [Graph Type]
    , column_comment.[value] as [Column Description]
    , sensitivity_classifications.label as [Sensitivity Label]
    , sensitivity_classifications.information_type as [Information Type]
    , sensitivity_classifications.rank_desc as [Sensitivity Rank]
    -- legder
    , columns.ledger_view_column_type_desc as [Ledger View Column]
    from sys.all_objects all_tables
        inner join @TableTypes table_types on (all_tables.type = table_types.Type)
        inner join sys.schemas on (all_tables.schema_id = schemas.schema_id)
        inner join sys.all_columns columns on (all_tables.object_id = columns.object_id)
        left join sys.identity_columns on (columns.object_id = identity_columns.object_id and columns.column_id = identity_columns.column_id)
        left join sys.default_constraints on (columns.object_id = default_constraints.parent_object_id and columns.column_id = default_constraints.parent_column_id)
        left join sys.computed_columns on (columns.object_id = computed_columns.object_id and columns.column_id = computed_columns.column_id)
        left join sys.masked_columns on (columns.object_id = masked_columns.object_id and columns.column_id = masked_columns.column_id)
        left join sys.column_encryption_keys cek on (columns.column_encryption_key_id = cek.column_encryption_key_id)
        left join sys.types on (columns.user_type_id = types.user_type_id)
        left join sys.extended_properties column_comment on (
            column_comment.class = 1 
            and column_comment.major_id = all_tables.object_id 
            and column_comment.minor_id = columns.column_id 
            and column_comment.name = N'MS_Description'
        )
        left join sys.sensitivity_classifications on (
            sensitivity_classifications.class = 1
            and sensitivity_classifications.major_id = all_tables.object_id 
            and sensitivity_classifications.minor_id = columns.column_id
        )
    where (@SchemaName is null or @SchemaName = schemas.name)
        and (@TableName is null or @TableName = all_tables.name)
    order by [Schema Name], [Table Name], columns.column_id;

    -- column attributes
    if exists (
        select 1
        from sys.extended_properties ep
            inner join sys.all_objects all_tables on (ep.major_id = all_tables.object_id)
            inner join @TableTypes table_types on (all_tables.type = table_types.Type)
            inner join sys.schemas on (all_tables.schema_id = schemas.schema_id)
            inner join sys.all_columns columns on (ep.major_id = columns.object_id and ep.minor_id = columns.column_id)
        where (@SchemaName is null or @SchemaName = schemas.name)
            and (@TableName is null or @TableName = all_tables.name)
            and ep.class = 1
            and ep.name <> N'MS_Description' -- column description
    ) begin
        select schemas.name as [Schema Name]
        , all_tables.name as [Table Name]
        , columns.name as [Column Name]
        , ep.name as [Attribute Name]
        , ep.value as [Attribute Value]
        from sys.extended_properties ep
            inner join sys.all_objects all_tables on (ep.major_id = all_tables.object_id)
            inner join @TableTypes table_types on (all_tables.type = table_types.Type)
            inner join sys.schemas on (all_tables.schema_id = schemas.schema_id)
            inner join sys.all_columns columns on (ep.major_id = columns.object_id and ep.minor_id = columns.column_id)
        where (@SchemaName is null or @SchemaName = schemas.name)
            and (@TableName is null or @TableName = all_tables.name)
            and ep.class = 1
            and ep.name <> N'MS_Description' -- column description
        order by [Schema Name], [Table Name], [Column Name], [Attribute Name];
    end;

    -- primary, unique contraints
    select schemas.name as [Schema Name]
    , all_tables.name as [Table Name]
    , key_constraints.name as [Constraint Name]
    , case when key_constraints.type = 'pk' then 'Primary' else 'Unique' end as [Constraint Type]
    , indexes.type_desc as [Index Type]
    , case when key_constraints.is_system_named = 1 then 'Yes' else 'No' end as [Is System Named]
    , columns.name as [Column Name]
    , index_columns.key_ordinal as [Ordinal Position]
    from sys.key_constraints
        inner join sys.all_objects all_tables on (key_constraints.parent_object_id = all_tables.object_id)
        inner join @TableTypes table_types on (all_tables.type = table_types.Type)
        inner join sys.schemas on (all_tables.schema_id = schemas.schema_id)
        left join sys.indexes on (key_constraints.unique_index_id = indexes.index_id and all_tables.object_id = indexes.object_id)
        left join sys.index_columns on(indexes.object_id = index_columns.object_id and indexes.index_id = index_columns.index_id)
        left join sys.all_columns columns on(all_tables.object_id = columns.object_id and index_columns.column_id = columns.column_id)
    where (@SchemaName is null or @SchemaName = schemas.name)
        and (@TableName is null or @TableName = all_tables.name)
    order by [Schema Name], [Table Name], [Constraint Name], index_columns.key_ordinal;

    -- Indexes
    if exists (
        select 1
        from sys.indexes
            inner join sys.all_objects all_tables on (indexes.object_id = all_tables.object_id)
            inner join @TableTypes table_types on (all_tables.type = table_types.Type)
            inner join sys.schemas on (all_tables.schema_id = schemas.schema_id)
        where indexes.index_id <> 0 -- zero is internal heap index
            and indexes.is_primary_key = 0
            and indexes.is_unique_constraint = 0
            and (@SchemaName is null or @SchemaName = schemas.name)
            and (@TableName is null or @TableName = all_tables.name)
    ) begin
        select schemas.name as [Schema Name]
        , all_tables.name as [Table Name]
    	, STRING_AGG(cast(columns.name as nvarchar(max)), ', ') WITHIN GROUP (ORDER BY index_columns.key_ordinal ASC) as [Column Names]
        , indexes.name as [Index Name]
        , case when indexes.is_unique = 1 then 'Yes' else 'No' end as [Is Unique]
        , case when indexes.is_disabled = 1 then 'Yes' else 'No' end as [Is Disabled]
        , indexes.type_desc as [Type]
        , indexes.fill_factor as [Fill Factor]
        , indexes.filter_definition as [Filter Definition]
        from sys.indexes
            inner join sys.all_objects all_tables on (indexes.object_id = all_tables.object_id)
            inner join @TableTypes table_types on (all_tables.type = table_types.Type)
            inner join sys.schemas on (all_tables.schema_id = schemas.schema_id)
            left join sys.index_columns on (indexes.object_id = index_columns.object_id and indexes.index_id = index_columns.index_id)
            left join sys.all_columns columns on (all_tables.object_id = columns.object_id and index_columns.column_id = columns.column_id)
        where indexes.index_id <> 0 -- zero is internal heap index
            and indexes.is_primary_key = 0
            and indexes.is_unique_constraint = 0
            and (@SchemaName is null or @SchemaName = schemas.name)
            and (@TableName is null or @TableName = all_tables.name)
        group by schemas.name
        , all_tables.type_desc
        , all_tables.name
        , indexes.name
        , indexes.is_unique
        , indexes.is_disabled
        , indexes.type_desc
        , indexes.fill_factor
        , indexes.filter_definition
        order by [Schema Name], [Table Name], [Index Name];

        select schemas.name as [Schema Name]
        , all_tables.name as [Table Name]
        , indexes.name as [Index Name]
        , columns.name as [Column Name]
        , case when index_columns.is_descending_key = 1 then 'Yes' else 'No' end as [Is Descending Key]
        , case when index_columns.is_included_column = 1 then 'Yes' else 'No' end as [In Included Column]
        from sys.indexes
            inner join sys.index_columns on (indexes.object_id = index_columns.object_id and indexes.index_id = index_columns.index_id)
            inner join sys.all_objects all_tables on (indexes.object_id = all_tables.object_id)
            inner join @TableTypes table_types on (all_tables.type = table_types.Type)
            inner join sys.all_columns columns on (all_tables.object_id = columns.object_id and index_columns.column_id = columns.column_id)
            inner join sys.schemas on (all_tables.schema_id = schemas.schema_id)
        where indexes.index_id <> 0 -- zero is internal heap index
            and indexes.is_primary_key = 0
            and indexes.is_unique_constraint = 0
            and (@SchemaName is null or @SchemaName = schemas.name)
            and (@TableName is null or @TableName = all_tables.name)
        order by [Schema Name], [Table Name], [Index Name], index_columns.key_ordinal;
    end;

    -- Index status: requires 'VIEW SERVER STATE' permission
    select schemas.name as [Schema Name]
    , all_tables.name as [Table Name]
    , indexes.name as [Index Name]
    , stats.user_seeks as [User Seeks]
    , stats.user_scans as [User Scans]
    , stats.user_lookups as [User Lookups]
    , stats.user_updates as [User Updates]
    , stats.last_user_seek as [Last User Seek]
    , stats.last_user_scan as [Last User Scan]
    , stats.last_user_lookup as [Last User Lookup]
    , last_user_update as [Last User Update]
    , stats.system_seeks as [System Seeks]
    , stats.system_scans as [System Scans]
    , stats.system_lookups as [System Lookups]
    , stats.system_updates as [System Updates]
    , stats.last_system_seek as [Last System Seek]
    , stats.last_system_scan as [Last System Scan]
    , stats.last_system_lookup as [Last System Lookup]
    , stats.last_system_update as [Last System Update]
    from sys.dm_db_index_usage_stats stats
        inner join sys.indexes on (stats.object_id = indexes.object_id and stats.index_id = indexes.index_id)
        inner join sys.all_objects all_tables on (indexes.object_id = all_tables.object_id)
        inner join @TableTypes table_types on (all_tables.type = table_types.Type)
        inner join sys.schemas on (all_tables.schema_id = schemas.schema_id)
    where stats.database_id = db_id()
        and (@SchemaName is null or @SchemaName = schemas.name)
        and (@TableName is null or @TableName = all_tables.name)
    order by [Schema Name], [Table Name], [Index Name]
    ;

    -- Table non-index generated stats
    select schemas.name as [Schema Name]
    , all_tables.name as [Table Name]
    , stats.name as [Stats Name]
    , stats.stats_id as [Stats Id]
    , case when stats.user_created = 1 then 'Yes' else 'No' end as [User Created]
    , case when stats.no_recompute = 1 then 'Yes' else 'No' end as [No Recompute]
    , case when stats.has_filter = 1 then 'Yes' else 'No' end as [Has Filter]
    , stats.filter_definition as [Filter Definition]
    , stats_columns.stats_column_id as [Stats Column Id]
    , stats_columns.column_id as [Column Id]
    , columns.name as [Column Name]
    from sys.stats
        inner join sys.all_objects all_tables on (stats.object_id = all_tables.object_id)
        inner join @TableTypes table_types on (all_tables.type = table_types.Type)
        inner join sys.schemas on (all_tables.schema_id = schemas.schema_id)
        inner join sys.stats_columns on (stats.object_id = stats_columns.object_id and stats.stats_id = stats_columns.stats_id)
        inner join sys.all_columns columns on (all_tables.object_id = columns.object_id and stats_columns.column_id = columns.column_id)
        left join sys.indexes on (stats.stats_id = indexes.index_id and stats.object_id = indexes.object_id)
    where indexes.index_id is null -- generated from index
        and (@SchemaName is null or @SchemaName = schemas.name)
        and (@TableName is null or @TableName = all_tables.name)
    order by [Schema Name], [Table Name], [Stats Name], stats_columns.stats_column_id;

    -- foreign key (to / from schema / table)
    select fk_schemas.name as [FK Schema]
    , fk_tables.Name as [FK Table]
    , fk.name as [FK Name]
    , fk.update_referential_action_desc as [Update Action]
    , fk.delete_referential_action_desc as [Delete Action]
    , case when fk.is_system_named = 1 then 'Yes' else 'No' end as [Is System Named]
    , case when fk.is_disabled = 1 then 'Yes' else 'No' end as [Is Disabled]
    , pk_schemas.name as [PK Schema]
    , pk_tables.Name as [PK Table]
    , pk.Name as [PK Name]
    , fk.create_date as [Created On]
    , fk.modify_date  as [Modified On]
    from sys.foreign_keys fk
        inner join sys.all_objects fk_tables on (fk.parent_object_id = fk_tables.object_id)
        inner join @TableTypes table_types on (fk_tables.type = table_types.Type)
        inner join sys.schemas fk_schemas on (fk_tables.schema_id = fk_schemas.schema_id)
        inner join sys.all_objects pk_tables on (fk.referenced_object_id = pk_tables.object_id)
        inner join sys.schemas pk_schemas on (pk_tables.schema_id = pk_schemas.schema_id)
        inner join sys.key_constraints pk on (fk.key_index_id = pk.unique_index_id and fk.referenced_object_id = pk.parent_object_id )
    where (@SchemaName is null or @SchemaName in (fk_schemas.name, pk_schemas.name))
        and (@TableName is null or @TableName in (fk_tables.name, pk_tables.name))
    order by [FK Schema], [FK Table], [FK Name];

    select fk_schemas.name as [FK Schema]
    , fk_tables.Name as [FK Table]
    , fk.name as [FK Name]
    , fk_columns.Name as [FK Field]
    , pk_schemas.name as [PK Schema]
    , pk_tables.Name as [PK Table]
    , pk.Name as [PK Name]
    , pk_columns.Name as [PK Field] 
    from sys.foreign_key_columns fkcs
        inner join sys.foreign_keys fk on (fkcs.constraint_object_id = fk.object_id) 
        inner join sys.all_objects fk_tables on (fk.parent_object_id = fk_tables.object_id)
        inner join @TableTypes table_types on (fk_tables.type = table_types.Type)
        inner join sys.schemas fk_schemas on (fk_tables.schema_id = fk_schemas.schema_id)
        inner join sys.all_objects pk_tables on (fk.referenced_object_id = pk_tables.object_id)
        inner join sys.schemas pk_schemas on (pk_tables.schema_id = pk_schemas.schema_id)
        inner join sys.key_constraints pk on (fk.key_index_id = pk.unique_index_id and fk.referenced_object_id = pk.parent_object_id )
        inner join sys.all_columns fk_columns on (fk.parent_object_id = fk_columns.object_id and fkcs.parent_column_id = fk_columns.column_id)
        inner join sys.all_columns pk_columns on (fk.referenced_object_id = pk_columns.object_id and fkcs.referenced_column_id = pk_columns.column_id)
    where (@SchemaName is null or @SchemaName in (fk_schemas.name, pk_schemas.name))
        and (@TableName is null or @TableName in (fk_tables.name, pk_tables.name))
    order by [FK Schema], [FK Table], [FK Name], fkcs.constraint_column_id;

    -- check constraints
    select schemas.name as [Schema Name]
    , all_tables.name as [Table Name]
    , check_constraints.name as [Check Constraint Name]
    , check_constraints.definition as [Constraint Definition]
    , case when check_constraints.is_disabled = 1 then 'Yes' else 'No' end as [Is Disabled]
    , case when check_constraints.is_system_named = 1 then 'Yes' else 'No' end as [Is System Named]
    , case when check_constraints.is_not_trusted = 1 then 'Yes' else 'No' end as [Is Not Trusted]
    , columns.name as [Column Name]
    from sys.check_constraints
        inner join sys.all_objects all_tables on (check_constraints.parent_object_id = all_tables.object_id)
        inner join @TableTypes table_types on (all_tables.type = table_types.Type)
        inner join sys.schemas on (all_tables.schema_id = schemas.schema_id)
        left join sys.all_columns columns on (all_tables.object_id = columns.object_id and check_constraints.parent_column_id = columns.column_id)
    where (@SchemaName is null or @SchemaName = schemas.name)
        and (@TableName is null or @TableName = all_tables.name)
    order by [Schema Name], [Table Name], [Check Constraint Name];

    -- triggers
    select schemas.name as [Schema Name]
    , all_tables.name as [Table Name]
    , triggers.name as [Trigger Name]
    , triggers.type_desc as [Trigger Type]
    , case when triggers.is_disabled = 1 then 'Yes' else 'No' end as [Is Disabled]
    , modules.definition as [Definition]
    , case when triggers.is_instead_of_trigger = 1 then 'INSTEAD OF' else 'AFTER' end as [Instead vs After]
    from sys.triggers
        inner join sys.all_sql_modules modules on (triggers.object_id = modules.object_id)
        inner join sys.all_objects all_tables on (triggers.parent_id = all_tables.object_id)
        inner join @TableTypes table_types on (all_tables.type = table_types.Type)
        inner join sys.schemas on (all_tables.schema_id = schemas.schema_id)
    where (@SchemaName is null or @SchemaName = schemas.name)
        and (@TableName is null or @TableName = all_tables.name)
        and triggers.is_ms_shipped = 0
    order by [Schema Name], [Table Name], [Trigger Name];
end;
go