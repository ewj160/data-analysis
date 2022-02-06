select OWNER as "Schema Name"
, MVIEW_NAME as "Materialized Name"
, LAST_REFRESH_DATE as "Last Refreshed On"
from ALL_MVIEWS
order by OWNER, MVIEW_NAME;