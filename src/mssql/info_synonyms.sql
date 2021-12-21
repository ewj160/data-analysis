/*
# Synonyms
*/

select schemas.name as [Schema Name]
, synonyms.name as [Synonym Name]
, synonyms.base_object_name as [Base Object]
, create_date as [Created On]
, modify_date as [Modified On]
from sys.synonyms
    inner join sys.schemas on (synonyms.schema_id = schemas.schema_id)
order by [Schema Name], [Synonym Name]