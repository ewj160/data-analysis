/*
# User defined data type information
*/

set nocount on;

select schemas.name as [Schema Name]
, types.name as [Type Name]
, case when types.is_table_type = 1 then 'Yes' else 'No' end as [Is Table Type]
, case when types.is_assembly_type = 1 then 'Yes' else 'No' end as [Is Assembly Type]
, types.rule_object_id as [Rule Object Id]
, ts.name as [Data Type Name]
, types.max_length as [Max Length]
, types.precision as [Precision]
, types.scale as [Scale]
, types.collation_name as [Collation Name]
, case when types.is_nullable = 1 then 'Yes' else 'No' end as [Is Nullable]
from sys.types
    inner join sys.schemas on (types.schema_id = schemas.schema_id) 
	left join sys.types ts on (types.system_type_id = ts.user_type_id)
where types.is_user_defined = 1 
order by [Schema Name], [Type Name];

-- if applicable, sub fields on table types
if exists (
    select 1
    from sys.table_types types
        inner join sys.schemas s on (types.schema_id = s.schema_id)
        inner join sys.columns c on (types.type_table_object_id = c.object_id) 
    where types.is_user_defined = 1
) begin
    select s.name as [Schema Name]
    , types.name as [Type Name]
    , c.name as [Field Name]
    , ts.name as [Data Type Name]
    , c.max_length as [Max Length]
    , c.precision as [Precision]
    , c.scale as [Scale]
    , c.collation_name as [Collation Name]
    , c.is_nullable as [Is Nullable]
    , c.user_type_id as [User Type Id]
    from sys.table_types types
        inner join sys.schemas s on (types.schema_id = s.schema_id)
        inner join sys.columns c on (types.type_table_object_id = c.object_id) 
        left join sys.types ts on (c.user_type_id = ts.user_type_id) 
    where types.is_user_defined = 1
    order by s.name, types.name, c.column_id;
end;