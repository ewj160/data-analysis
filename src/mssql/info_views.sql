/*
# View Information

Usage:
1. Adjust @SchemaName and @@ViewName for specific view to get information, or set to null for all (bulk analysis).
2. Set @IncludeShippedViews to 1 to include shipped views, or leave 0 (default) to exclude shipped views.
*/

set nocount on;
BEGIN
    declare @SchemaName SYSNAME = null; -- schema name to filter, or null for any.
    declare @ViewName SYSNAME = null; -- view name to filter, or null for any.
    declare @IncludeShippedViews bit = 0; -- 1 to include shipped views, 0 to exclude.

    -- views
    select views.object_id
    , schemas.name as [Schema Name]
    , views.name as [View Name]
    , sql_modules.definition as [View Definition]
    , views.create_date as [Created On]
    , views.modify_date as [Modified On]
    , case when sql_modules.is_schema_bound = 1 then 'Yes' else 'No' end as [Is Schema Bound]
    , case when sql_modules.is_recompiled = 1 then 'Yes' else 'No' end as [Is Recompiled]
    , case when sql_modules.uses_native_compilation = 1 then 'Yes' else 'No' end as [Use Native Compliation]
    , cmt.Value as [View Description]
    from sys.all_views views
        left join sys.all_sql_modules sql_modules on (views.object_id = sql_modules.object_id)
        inner join sys.schemas on (views.schema_id = schemas.schema_id)
        left join sys.extended_properties cmt on (
            views.object_id = cmt.major_id
            and cmt.class = 1
            and cmt.minor_id = 0
            and cmt.name = 'MS_Description'
        )
    where (@SchemaName is null or @SchemaName = schemas.name)
        and (@ViewName is null or @ViewName = views.name)
        and views.is_ms_shipped in (@IncludeShippedViews, 0)
    order by [Schema Name], [View Name];

    -- extended attributes
    if exists (
        select 1
            from sys.extended_properties ep
            inner join sys.all_views views on (ep.major_id = views.object_id)
            inner join sys.schemas on (views.schema_id = schemas.schema_id)
        where ep.name <> 'MS_Description'
            and (@SchemaName is null or @SchemaName = schemas.name)
            and (@ViewName is null or @ViewName = views.name)
            and views.is_ms_shipped in (@IncludeShippedViews, 0)
    ) BEGIN
        select schemas.name as [Schema Name]
        , views.name as [View Name]
        , ep.name as [Attribute]
        , ep.value as [Value]
        from sys.extended_properties ep
            inner join sys.all_views views on (ep.major_id = views.object_id)
            inner join sys.schemas on (views.schema_id = schemas.schema_id)
        where ep.name <> 'MS_Description'
            and (@SchemaName is null or @SchemaName = schemas.name)
            and (@ViewName is null or @ViewName = views.name)
            and views.is_ms_shipped in (@IncludeShippedViews, 0)
        order by [Schema Name], [View Name], [Attribute];
    end;

    -- fields
    select schemas.name as [Schema Name]
    , views.name as [View Name]
    , columns.name as [Column Name]
    , ts.name as [Field Type]
    , case when columns.max_length != -1 and ts.name in ('nchar','nvarchar') then columns.max_length / 2 else columns.max_length end as [Max Length]
    , columns.precision as Precision
    , columns.scale as Scale
    , case when columns.is_nullable = 1 then 'Yes' else 'No' end as [Is Nullable]
    , case when columns.is_identity = 1 then 'Yes' else 'No' end as [Is Identity]
    , ic.seed_value as [SEED Value]
    , ic.increment_value as [Increment Value]
    , ic.last_value as [Last Value]
    , case when columns.is_sparse = 1 then 'Yes' else 'No' end as [Is Sparse]
    , case when columns.is_computed = 1 then 'Yes' else 'No' end as [Is Computed]
    , dc.name as [Default Value Name]
    , dc.definition as [Default Value]
    , case when dc.is_system_named = 1 then 'Yes' else 'No' end as [Is Default Value Name Generated]
    , cc.definition as [Computed Column Definition]
    , case when cc.is_persisted = 1 then 'Yes' else 'No' end as [Computed Is Persisted]
    , case when SERVERPROPERTY('collation') = columns.collation_name then null else columns.collation_name end as [Collation Name]
    , case when columns.generated_always_type_desc <> 'NOT_APPLICABLE' then columns.generated_always_type_desc else null end as [Generated Always Type]
    , case when columns.is_hidden = 1 then 'Yes' else 'No' end as [Is Hidden]
    , mc.masking_function as [Masking Function]
    , columns.encryption_type_desc as [Encrypted Type]
    , cek.name as [Column Encyption Key]
    , columns.encryption_algorithm_name as [Encyption Algorithm Name]
    , columns.graph_type_desc as [Graph Type]
    , column_comment.[value] as [Column Description]
    , sc.label as [Sensitivity Label]
    , sc.information_type as [Information Type]
    , sc.rank_desc as [Sensitivity Rank]
    from sys.all_views views
        inner join sys.schemas on (views.schema_id = schemas.schema_id)
        inner join sys.all_columns columns on (views.object_id = columns.object_id)
        left join sys.identity_columns ic on (columns.object_id = ic.object_id and columns.column_id = ic.column_id)
        left join sys.default_constraints dc on (columns.object_id = dc.parent_object_id and columns.column_id = dc.parent_column_id)
        left join sys.computed_columns cc on (columns.object_id = cc.object_id and columns.column_id = cc.column_id)
        left join sys.masked_columns mc on (columns.object_id = mc.object_id and columns.column_id = mc.column_id)
        left join sys.column_encryption_keys cek on (columns.column_encryption_key_id = cek.column_encryption_key_id)
        left join sys.types ts on (columns.user_type_id = ts.user_type_id)
        left join sys.extended_properties column_comment on (
            column_comment.class = 1 
            and column_comment.major_id = views.object_id 
            and column_comment.minor_id = columns.column_id 
            and column_comment.name = N'MS_Description'
        )
        left join sys.sensitivity_classifications sc on (
            sc.class = 1
            and sc.major_id = views.object_id 
            and sc.minor_id = columns.column_id
        )
    where (@SchemaName is null or @SchemaName = schemas.name)
        and (@ViewName is null or @ViewName = views.name)
        and views.is_ms_shipped in (@IncludeShippedViews, 0)
    order by [Schema Name], [View Name], columns.column_id;

    -- indexes
    if exists (
        select 1
        from sys.indexes
            inner join sys.all_views views on (indexes.object_id = views.object_id)
            inner join sys.schemas on (views.schema_id = schemas.schema_id)
        where indexes.index_id <> 0 -- zero is internal heap index
            and (@SchemaName is null or @SchemaName = schemas.name)
            and (@ViewName is null or @ViewName = views.name)
            and views.is_ms_shipped in (@IncludeShippedViews, 0)
    ) begin
        select schemas.name as [Schema Name]
        , views.name as [View Name]
    	, STRING_AGG(cast(columns.name as nvarchar(max)), ', ') WITHIN GROUP (ORDER BY index_columns.key_ordinal ASC) as [Column Names]
        , indexes.name as [Index Name]
        , case when indexes.is_unique = 1 then 'Yes' else 'No' end as [Is Unique]
        , case when indexes.is_disabled = 1 then 'Yes' else 'No' end as [Is Disabled]
        , case when indexes.is_primary_key = 1 then 'Yes' else 'No' end as [Is Primary Key]
        , case when indexes.is_unique_constraint = 1 then 'Yes' else 'No' end as [Is Unique Constraint]
        , indexes.type_desc as [Type]
        , indexes.fill_factor as [Fill Factor]
        , indexes.filter_definition as [Filter Definition]
        from sys.indexes
            inner join sys.all_views views on (indexes.object_id = views.object_id)
            inner join sys.schemas on (views.schema_id = schemas.schema_id)
            left join sys.index_columns on (indexes.object_id = index_columns.object_id and indexes.index_id = index_columns.index_id)
            left join sys.all_columns columns on (views.object_id = columns.object_id and index_columns.column_id = columns.column_id)
        where indexes.index_id <> 0 -- zero is internal heap index
            and (@SchemaName is null or @SchemaName = schemas.name)
            and (@ViewName is null or @ViewName = views.name)
            and views.is_ms_shipped in (@IncludeShippedViews, 0)
        group by schemas.name
        , views.type_desc
        , views.name
        , indexes.name
        , indexes.is_unique
        , indexes.is_disabled
        , indexes.is_primary_key
        , indexes.is_unique_constraint
        , indexes.type_desc
        , indexes.fill_factor
        , indexes.filter_definition
        order by [Schema Name], [View Name], [Index Name];

        select schemas.name as [Schema Name]
        , views.name as [View Name]
        , indexes.name as [Index Name]
        , columns.name as [Column Name]
        , case when ik.is_descending_key = 1 then 'Yes' else 'No' end as [Is Descending Key]
        , case when ik.is_included_column = 1 then 'Yes' else 'No' end as [In Included Column]
        from sys.indexes
            inner join sys.index_columns ik on (indexes.object_id = ik.object_id and indexes.index_id = ik.index_id)
            inner join sys.all_views views on (indexes.object_id = views.object_id)
            inner join sys.all_columns columns on (views.object_id = columns.object_id and ik.column_id = columns.column_id)
            inner join sys.schemas on (views.schema_id = schemas.schema_id)
        where indexes.index_id <> 0 -- zero is internal heap index
            and (@SchemaName is null or @SchemaName = schemas.name)
            and (@ViewName is null or @ViewName = views.name)
            and views.is_ms_shipped in (@IncludeShippedViews, 0)
        order by [Schema Name], [View Name], [Index Name], ik.key_ordinal;

        -- Index status: requires 'VIEW SERVER STATE' permission
        select schemas.name as [Schema Name]
        , views.name as [View Name]
        , indexes.name as [Index Name]
        , ius.user_seeks as [User Seeks]
        , ius.user_scans as [User Scans]
        , ius.user_lookups as [User Lookups]
        , ius.user_updates as [User Updates]
        , ius.last_user_seek as [Last User Seek]
        , ius.last_user_scan as [Last User Scan]
        , ius.last_user_lookup as [Last User Lookup]
        , last_user_update as [Last User Update]
        , ius.system_seeks as [System Seeks]
        , ius.system_scans as [System Scans]
        , ius.system_lookups as [System Lookups]
        , ius.system_updates as [System Updates]
        , ius.last_system_seek as [Last System Seek]
        , ius.last_system_scan as [Last System Scan]
        , ius.last_system_lookup as [Last System Lookup]
        , ius.last_system_update as [Last System Update]
        from sys.dm_db_index_usage_stats ius
            inner join sys.indexes on (ius.object_id = indexes.object_id and ius.index_id = indexes.index_id)
            inner join sys.all_views views on (indexes.object_id = views.object_id)
            inner join sys.schemas on (views.schema_id = schemas.schema_id)
        where ius.database_id=db_id()
            and (@SchemaName is null or @SchemaName = schemas.name)
            and (@ViewName is null or @ViewName = views.name)
            and views.is_ms_shipped in (@IncludeShippedViews, 0)
        order by [Schema Name], [View Name], [Index Name]
        ;

        -- Table non-index generated stats
        select schemas.name as [Schema Name]
        , views.name as [View Name]
        , stats.name as [Stats Name]
        , stats.stats_id as [Stats Id]
        , case when stats.user_created = 1 then 'Yes' else 'No' end as [User Created]
        , case when stats.no_recompute = 1 then 'Yes' else 'No' end as [No Recompute]
        , case when stats.has_filter = 1 then 'Yes' else 'No' end as [Has Filter]
        , stats.filter_definition as [Filter Definition]
        , stc.stats_column_id as [Stats Column Id]
        , stc.column_id as [Column Id]
        , columns.name as [Column Name]
        from sys.stats
            inner join sys.all_views views on (stats.object_id = views.object_id)
            inner join sys.schemas on (views.schema_id = schemas.schema_id)
            inner join sys.stats_columns stc on (stats.object_id = stc.object_id and stats.stats_id = stc.stats_id)
            inner join sys.all_columns columns on (views.object_id = columns.object_id and stc.column_id = columns.column_id)
            left join sys.indexes on (stats.stats_id = indexes.index_id and stats.object_id = indexes.object_id)
        where indexes.index_id is null -- generated from index
            and (@SchemaName is null or @SchemaName = schemas.name)
            and (@ViewName is null or @ViewName = views.name)
            and views.is_ms_shipped in (@IncludeShippedViews, 0)
        order by [Schema Name], [View Name], [Stats Name], stc.stats_column_id;
    end;

    -- triggers
    if exists (
        select 1
        from sys.triggers
            inner join sys.all_views views on (triggers.parent_id = views.object_id) 
            inner join sys.schemas on (views.schema_id = schemas.schema_id) 
        where (@SchemaName is null or @SchemaName = schemas.name)
            and (@ViewName is null or @ViewName = views.name)
            and views.is_ms_shipped in (@IncludeShippedViews, 0)
    ) BEGIN
        select schemas.name as [Schema Name]
        , views.name as [View Name]
        , triggers.name as [Trigger Name]
        , sql_modules.Definition 
        from sys.triggers
            inner join sys.all_sql_modules sql_modules on (triggers.object_id = sql_modules.object_id) 
            inner join sys.all_views views on (triggers.parent_id = views.object_id) 
            inner join sys.schemas on (views.schema_id = schemas.schema_id) 
        where (@SchemaName is null or @SchemaName = schemas.name)
            and (@ViewName is null or @ViewName = views.name)
            and views.is_ms_shipped in (@IncludeShippedViews, 0)
        order by [Schema Name], [View Name], [Trigger Name];
    end;
end;