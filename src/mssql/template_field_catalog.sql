/*
# Field Catalog

*/

select schemas.name as [Schema Name]
, objects.name as [Object Name]
, objects.type_desc as [Object Type]
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
-- Future: legder
-- c.ledger_view_column_type_desc
from sys.all_objects objects
	inner join sys.schemas on (objects.schema_id = schemas.schema_id)
	inner join sys.all_columns columns on (objects.object_id = columns.object_id)
	left join sys.identity_columns on (columns.object_id = identity_columns.object_id and columns.column_id = identity_columns.column_id)
	left join sys.default_constraints on (columns.object_id = default_constraints.parent_object_id and columns.column_id = default_constraints.parent_column_id)
	left join sys.computed_columns on (columns.object_id = computed_columns.object_id and columns.column_id = computed_columns.column_id)
	left join sys.masked_columns on (columns.object_id = masked_columns.object_id and columns.column_id = masked_columns.column_id)
	left join sys.column_encryption_keys cek on (columns.column_encryption_key_id = cek.column_encryption_key_id)
	left join sys.types on (columns.user_type_id = types.user_type_id)
	left join sys.extended_properties column_comment on (
		column_comment.class = 1 
		and column_comment.major_id = objects.object_id 
		and column_comment.minor_id = columns.column_id 
		and column_comment.name = N'MS_Description'
	)
	left join sys.sensitivity_classifications on (
		sensitivity_classifications.class = 1
		and sensitivity_classifications.major_id = objects.object_id 
		and sensitivity_classifications.minor_id = columns.column_id
	)
where not exists (
	select 1
	from sys.tables
	where objects.object_id = tables.history_table_id
) and objects.is_ms_shipped = 0
order by [Schema Name], [Object Name], columns.column_id;