/*
# Version / Release
*/

select SERVERPROPERTY('productversion') as [Product Version]
, SERVERPROPERTY('ProductUpdateLevel') as [Product Update Level]
, SERVERPROPERTY('productlevel') as [Product Level]
, SERVERPROPERTY('edition') as Edition
, @@VERSION as [Full Version]

/*
# Server Settings
*/

SELECT @@SERVERNAME as [Server Name Param]
, SERVERPROPERTY('ComputerNamePhysicalNetBIOS') as [Computer Name Physical Net BIOS]
, SERVERPROPERTY('ServerName') as [Server Name]
, SERVERPROPERTY('MachineName') as [Machine Name]
, SERVERPROPERTY('InstanceName') as [Instance Name]
, SERVERPROPERTY('BuildClrVersion') as [CDR Version]
, SERVERPROPERTY('Collation') as Collation
, SERVERPROPERTY('IsIntegratedSecurityOnly') as [Is Integrated Security Only]
, SERVERPROPERTY('IsXTPSupported') as [In Memory Supported]
, SERVERPROPERTY('Edition') as Edition
;

/*
# Configuration
*/

select name as [Server Wide Configuration]
, value as [Value]
, minimum as [Min Value]
, maximum as [Max Value]
, [description] as [Description]
, case when is_dynamic = 1 then 'Yes' else 'No' end as [Is Dynamic]
, case when is_advanced = 1 then 'Yes' else 'No' end as [Is Advanced]
from sys.configurations
order by [Server Wide Configuration];

/*
# Permissions Available
*/

select permission_name FROM fn_my_permissions(NULL, 'SERVER')

/*
# Language - Date Formatting
*/

select name, alias, dateformat
, months as [Name of Months]
, shortmonths as [Abbr name of Months]
, [days] as [Name of Days of Week]
, datefirst as [First Day of Week]
from sys.syslanguages
order by alias

/*
# Time Zone
*/

select Name
, current_utc_offset as [Current UTC Offset]
, is_currently_dst as [Is Current DST]
from sys.time_zone_info
order by Name

/*
# Space Used
*/

exec sp_spaceused @updateusage=false