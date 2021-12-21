/*
# Sequences
*/

set nocount on;

select schemas.name as [Schema Name]
, sequences.name as [Sequence Name]
, sequences.create_date as [Created On]
, sequences.modify_date as [Modified On]
, case when sequences.is_ms_shipped = 1 then 'Yes' else 'No' end as [Is MS Shipped]
, sequences.current_value as [Current Value]
, sequences.start_value as [Start Value]
, sequences.increment as [Increment By]
, sequences.minimum_value as [Min Value]
, sequences.maximum_value as [Max Value]
, case when sequences.is_cycling = 1 then 'Yes' else 'No' end as [Is Cycling]
, case when sequences.is_cached = 1 then 'Yes' else 'No' end as [Is Cached]
, sequences.cache_size as [Cache Size]
, types.name as [Data Type]
, sequences.precision as [Type Precision]
, sequences.scale as [Type Scale]
, sequences.current_value as [Current Value]
, case when sequences.is_exhausted = 1 then 'Yes' else 'No' end as [Is Seq Exhaused]
, cmt.Value as [Sequence Description]
from sys.sequences
	inner join sys.schemas on (sequences.schema_id = schemas.schema_id)
	left join sys.types on (sequences.system_type_id = types.system_type_id)
    left join sys.extended_properties cmt on (
        sequences.object_id = cmt.major_id
        and cmt.minor_id = 0
        and cmt.class = 1
        and cmt.name = 'MS_Description'
    )
order by [Schema Name], [Sequence Name];

if exists (
    select 1
    from sys.extended_properties ep
        inner join sys.sequences on (ep.major_id = sequences.object_id)
        inner join sys.schemas on (sequences.schema_id = schemas.schema_id)
    where ep.name <> 'MS_Description'
) begin
    select schemas.name as [Schema Name], sequences.name as [Sequence Name], ep.name as [Attribute], ep.value as [Value]
    from sys.extended_properties ep
        inner join sys.sequences on (ep.major_id = sequences.object_id)
        inner join sys.schemas on (sequences.schema_id = schemas.schema_id)
    where ep.name <> 'MS_Description'
    order by [Schema Name], [Sequence Name], [Attribute];
end;
