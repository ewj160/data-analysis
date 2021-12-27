/*
# Procedure and Function Information

Usage:
1. Adjust @SchemaName and @RoutineName for specific procedure or function to view information, or set to null for all (bulk analysis).
*/
set nocount on;

begin
    -- setup
    declare @SchemaName SYSNAME = null; -- schema name to filter, or null for any.
    declare @RoutineName SYSNAME = null; -- procedure or function routine name to filter, or null for any.

    select schemas.name as [Schema Name]
    , routines.Name as [Routine Name]
    , routines.type_desc as [Routine Type]
    , case when modules.is_schema_bound = 1 then 'Yes' else 'No' end as [Is Schema Bound]
    , case when modules.is_recompiled = 1 then 'Yes' else 'No' end as [Is Recompiled]
    , modules.definition as [Routine Definition]
    , case when modules.uses_native_compilation = 1 then 'Yes' else 'No' end as [Uses Native Complication]
    , case when modules.is_inlineable = 1 then 'Yes' else 'No' end as [Is Inlineable]
    , modules.inline_type as [Inline Type]
    , routines.create_date as [Created On]
    , routines.modify_date as [Modified On]
    , case when procedures.is_auto_executed = 1 then 'Yes' else 'No' end as [Is Auto Executed]
    -- assemby
    , assemblies.clr_name as [CLR Name]
    , assemblies.name as [Assembly Name]
    , assemblies.permission_set_desc as [Permission Set]
    , assembly_modules.assembly_class as [Assembly Class]
    , assembly_modules.assembly_method as [Assembly Method]
    , assemblies.create_date as [Assembly Create Date]
    , assemblies.modify_date as [Assembly Modify Date]
    , convert(varchar,ASSEMBLYPROPERTY(assemblies.name, 'VersionMajor')) + '.' + 
                convert(varchar,ASSEMBLYPROPERTY(assemblies.name, 'VersionMinor')) + '.' + 
                convert(varchar,ASSEMBLYPROPERTY(assemblies.name, 'VersionBuild')) + '.' +
                convert(varchar,ASSEMBLYPROPERTY(assemblies.name, 'VersionRevision')) as [Assembly Version]
    from sys.all_objects routines 
        inner join sys.schemas on (routines.schema_id = schemas.schema_id) 
        left join sys.assembly_modules on (routines.object_id = assembly_modules.object_id) 
        left join sys.assemblies on (assembly_modules.assembly_id = assemblies.assembly_id) 
        left join sys.all_sql_modules modules on (routines.object_id = modules.object_id) 
        left join sys.procedures on (routines.object_id = procedures.object_id)
    where routines.type in (
        -- functions
        'AF','FN','FS','FT','IF','TF',
        -- procedures
        'P','PC','RF','X'
    ) and (@SchemaName is null or @SchemaName = schemas.name)
        and (@RoutineName is null or @RoutineName = routines.name)
    order by [Schema Name], [Routine Name];

    select schemas.name as [Schema Name]
    , routines.name as [Routine Name]
    , parameters.name as [Column Name]
    , parameters.parameter_id as [Parameter Id]
    , types.name as [Type Name]
    , parameters.max_length as [Max Length]
    , parameters.precision as Precision
    , parameters.scale as Scale
    , case when parameters.is_output = 1 then 'Yes' else 'No' end as [Is Output]
    from sys.all_parameters parameters
        inner join sys.all_objects routines on (parameters.object_id = routines.object_id)
        inner join sys.schemas on (routines.schema_id = schemas.schema_id)
        left join sys.types on (parameters.user_type_id = types.user_type_id)
    where (@SchemaName is null or @SchemaName = schemas.name)
        and (@RoutineName is null or @RoutineName = routines.name)
    order by [Schema Name], [Routine Name], parameters.parameter_id;

    -- table value functions return tables
    select schemas.name as [Schema Name]
    , routines.name as [Routine Name]
    , columns.name as [Column Name]
    , types.name as [Field Type]
    , case when columns.max_length != -1 and types.name in ('nchar','nvarchar') then columns.max_length / 2 else columns.max_length end as [Max Length]
    , columns.precision as Precision
    , columns.scale as Scale
    , case when columns.is_nullable = 1 then 'Yes' else 'No' end as [Is Nullable]
    , case when SERVERPROPERTY('collation') = columns.collation_name then null else columns.collation_name end as [Collation Name]
    , columns.encryption_type_desc as [Encrypted Type]
    , cek.name as [Column Encyption Key]
    , columns.encryption_algorithm_name as [Encyption Algorithm Name]
    from sys.all_objects routines
        inner join sys.schemas on (routines.schema_id = schemas.schema_id)
        inner join sys.all_columns columns on (routines.object_id = columns.object_id)
        left join sys.column_encryption_keys cek on (columns.column_encryption_key_id = cek.column_encryption_key_id)
        left join sys.types on (columns.user_type_id = types.user_type_id)
    where routines.type in ('FT', 'IF', 'TF')
        and (@SchemaName is null or @SchemaName = schemas.name)
        and (@RoutineName is null or @RoutineName = routines.name)
    order by [Schema Name], [Routine Name], columns.column_id;

    -- dependencies
    select schemas.name as [Schema Name]
    , routines.name as [Routine Name]
    , sed.referenced_schema_name as [Referenced Schema Name]
    , sed.referenced_entity_name as [Referenced Entity Name]
    from sys.all_objects routines
        inner join sys.schemas on (routines.schema_id = schemas.schema_id)
        inner join sys.sql_expression_dependencies sed on (routines.object_id = sed.referencing_id)
    where routines.type in (
        -- functions
        'AF','FN','FS','FT','IF','TF',
        -- procedures
        'P','PC','RF','X'
    ) and (@SchemaName is null or @SchemaName = schemas.name)
        and (@RoutineName is null or @RoutineName = routines.name)
        and sed.referenced_minor_id = 0
    order by [Schema Name], [Routine Name], [Referenced Schema Name], [Referenced Entity Name];
end;
go