/*
# Schemas
*/

select schemas.schema_id as [Schema Id]
, schemas.name as [Schema Name]
, principals.name as [Owner]
, principals.type_desc as [Owner Type]
, case when principals.is_fixed_role = 1 then 'Yes' else 'No' end as [Is Fixed Role]
, obj.[# Objects]
from sys.schemas
	inner join sys.database_principals principals on (schemas.principal_id = principals.principal_id)
	left join (
		select schema_id, count(*) as [# Objects]
		from sys.objects
		group by schema_id
	) obj on (schemas.schema_id = obj.schema_id)
order by [Schema Name]