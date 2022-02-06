/*
# Abstract Types
*/

select OWNER as "Schema Name"
, TYPE_NAME as "Type Name"
, ATTRIBUTES as "# Attributes"
, METHODS as "$ Methods"
from all_types
order by OWNER, TYPE_NAME;

select OWNER as "Schema Name"
, TYPE_NAME as "Type Name"
, ATTR_NAME as "Attribute Name"
, ATTR_TYPE_NAME as "Attribute Type Name"
, LENGTH as "Length"
, PRECISION as "Precision"
, SCALE as "Scale"
from ALL_TYPE_ATTRS
order by OWNER, TYPE_NAME, ATTR_NO;