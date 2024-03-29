/*
# Database

Related: server information script.
*/

select d.database_id
, d.name as [Database Name]
, d.create_date as [Create Date]
, d.compatibility_level as [Compatibility Level]
, d.collation_name as [Collation Name]
, d.user_access_desc as [User Access]
, case when d.is_read_only = 1 then 'Yes' else 'No' end as [Is Read Only]
, case when d.is_auto_close_on = 1 then 'Yes' else 'No' end as [Is Auto Close On]
, case when d.is_auto_shrink_on = 1 then 'Yes' else 'No' end as [Is Auto Shrink On]
, d.state_desc as [State]
, case when d.is_in_standby = 1 then 'Yes' else 'No' end as [Is In Standby]
, case when d.is_cleanly_shutdown = 1 then 'Yes' else 'No' end as [Is Cleanly Shutdown]
, d.recovery_model_desc as [Recovery Model]
, suser_sname(d.owner_sid) as [Owner]
, case when d.is_cdc_enabled = 1 then 'Yes' else 'No' end as [Is Change Data Capture Enabled]
, case when d.is_encrypted = 1 then 'Yes' else 'No' end as [Is Encypted]
, d.containment_desc as [Containment]
, case when ctcd.is_auto_cleanup_on = 1 then 'Yes' else 'No' end as [Is Change Tracking Auto Cleanup On]
, ctcd.retention_period as [CT Retension Period]
, ctcd.retention_period_units_desc as [CT Retention Period Units]
, case when d.is_temporal_history_retention_enabled = 1 then 'Yes' else 'No' end as [Is Temporital History Retension Enabled]
, case when DATABASEPROPERTYEX(d.name, 'IsXTPSupported') = 1 then 'Yes' else 'No' end as [Is In Memory Supported]
, DATABASEPROPERTYEX(d.name, 'Edition') as [Azure Service Tier]
, DATABASEPROPERTYEX(d.name, 'ServiceObjective') as [Azure Service Objective] 
, case when d.is_auto_create_stats_on = 1 then 'Yes' else 'No' end as [Is Auto Create Stats On]
, case when d.is_auto_update_stats_on = 1 then 'Yes' else 'No' end as [Is Auto Update Stats On]
, case when d.is_auto_update_stats_async_on = 1 then 'Yes' else 'No' end as [Is Auto Update Stats Async On]
, case when DATABASEPROPERTYEX('testdb', 'IsOptimizedLockingOn') = 1 then 'Yes' else 'No' end as [Is Optimized Locking Enabled]
, case when d.is_read_committed_snapshot_on = 1 then 'Yes' else 'No' end as [Read Committed Snapshot Isolation (RCSI)]
, case when d.is_accelerated_database_recovery_on = 1 then 'Yes' else 'No' end as [Accelerated Database Recovery (ADR)]
from sys.databases d 
	left join sys.change_tracking_databases ctcd on (d.database_id=ctcd.database_id)
where d.database_id = DB_ID();

select name as [Database Scoped Configuration]
, value as [Value]
, value_for_secondary as [Value for Secondary]
, case when is_value_default = 1 then 'Yes' else 'No' end as [Is Default Value]
from sys.database_scoped_configurations
order by name;

select desired_state_desc [Desired State]
, actual_state_desc as [Actual State]
, actual_state_additional_info as [Actual State Additional Info]
, current_storage_size_mb as [Current Storage Size (MB)]
, max_storage_size_mb as [Max Storage Size (MB)]
, flush_interval_seconds as [Flush Interval (s)]
, stale_query_threshold_days as [Stale Query Threshold (days)]
, max_plans_per_query as [Max Plans per Query]
, query_capture_mode_desc as [Query Capture Mode]
, capture_policy_execution_count
, capture_policy_total_compile_cpu_time_ms
, capture_policy_total_execution_cpu_time_ms
, capture_policy_stale_threshold_hours
, size_based_cleanup_mode_desc as [Size Based Cleanup Mode]
, wait_stats_capture_mode_desc as [Wait Stats Capture Mode]
from sys.database_query_store_options;
