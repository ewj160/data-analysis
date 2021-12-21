/*
# Database Links
*/

select servers.server_id as [Server Id]
, servers.Name
, servers.Product
, servers.Provider
, servers.data_source as [Data Source]
, servers.Location
, servers.provider_string as [Provider String]
, servers.modify_date as [Modified On]
from sys.servers 
where servers.is_linked = 1
order by servers.Name;