
select sys_context( 'userenv', 'current_schema' ) as "Default Schema"
, user as "Current User"
from dual;
