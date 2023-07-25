-- https://learn.microsoft.com/en-us/sql/relational-databases/system-catalog-views/query-store-catalog-views-transact-sql?view=sql-server-ver16
-- https://learn.microsoft.com/en-us/sql/relational-databases/performance/monitoring-performance-by-using-the-query-store?view=sql-server-ver16

-- General

-- Current configured settings
select * from sys.database_query_store_options;
-- information about the settings for the query, including things like ANSI settings
select * from sys.query_context_settings;
-- execution plans and properties around them
select * from sys.query_store_plan;
-- properties around the query such as hash, count of compiles, last compile duration, object_id & more
select * from sys.query_store_query;
-- the T-SQL for the query itself
select * from sys.query_store_query_text;
-- the aggregated wait statistics for the query & plan in question
select * from sys.query_store_wait_stats;
-- the aggregated information like average execution time, standard deviation, reads, writes, etc.
select * from sys.query_store_runtime_stats;
--  the defined start & stop time of runtime data aggregations
select * from sys.query_store_runtime_stats_interval;

select * from sys.query_store_query_hints;
-- SS 2022+:
-- select * from sys.database_query_store_internal_state;

-- Sample queries

-- summarize queries
select qsq.query_id
, qsq.object_id
, qsqt.query_sql_text
, qsp.plan_id
, cast(qsp.query_plan as XML) as [Query Plan]
, qsp.last_execution_time
from sys.query_store_query qsq
	inner join sys.query_store_query_text qsqt on (qsq.query_text_id = qsqt.query_text_id)
	inner join sys.query_store_plan qsp on (qsq.query_id = qsp.query_id);

-- Query store stats for a plan.
begin
	declare @PlanId bigint = 5; -- set for desired plan
	declare @CompareTime datetime = DATEADD(minute, -10, SYSDATETIME());

	select cast(qsp.query_plan as XML) as [Query Plan]
	, qsp.plan_id
	, qsrs.count_executions as [Execution (cnt)]
	, qsrs.avg_duration as [Avg Duration]
	, qsrs.stdev_duration as [StdDev Duration]
	, qsws.wait_category_desc as [Wait Category]
	, qsws.avg_query_wait_time_ms as [Avg Query Wait Time (ms)]
	, qsws.stdev_query_wait_time_ms as [StdDev Query Wait Time (ms)]
	from sys.query_store_plan qsp
		inner join sys.query_store_runtime_stats qsrs on (qsp.plan_id = qsrs.plan_id)
		inner join sys.query_store_runtime_stats_interval qsrsi on (qsrs.runtime_stats_interval_id = qsrsi.runtime_stats_interval_id)
		left join sys.query_store_wait_stats qsws on (
			qsrs.plan_id = qsws.[plan_id]
			and qsws.execution_type = qsws.execution_type
			and qsws.runtime_stats_interval_id = qsws.runtime_stats_interval_id
		)
	where qsp.plan_id = @PlanId
		and @CompareTime between qsrsi.start_time and qsrsi.end_time
end;

-- Average of store intervals.
With QAggregate as (
	select qsrs.plan_id
	, sum(qsrs.count_executions) as CountExecution
	, avg(qsrs.avg_duration) as AvgDuration
	, qsws.wait_category_desc
	, avg(qsws.avg_query_wait_time_ms) as AvgQueryWaitTime
	, avg(qsws.stdev_query_wait_time_ms) as StDevQueryWaitTime
	from sys.query_store_runtime_stats qsrs
		left join sys.query_store_wait_stats qsws on (
			qsrs.plan_id = qsws.plan_id
			and qsrs.runtime_stats_interval_id = qsws.runtime_stats_interval_id
		)
	group by qsrs.plan_id, qsws.wait_category_desc
)
select cast(qsp.query_plan as XML) as [Query Plan]
, qsa.*
from sys.query_store_plan qsp
	inner join QAggregate qsa on (qsp.plan_id = qsa.plan_id)
where qsp.plan_id = 5;

-- Force plan: https://learn.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-query-store-force-plan-transact-sql?view=sql-server-ver16
-- exec sys.sp_query_store_force_plan 1, 1;
-- exec sys.sp_query_store_unforce_plan 1, 1;

-- Force hints: https://learn.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sys-sp-query-store-set-hints-transact-sql?view=sql-server-ver16
-- EXEC sys.sp_query_store_set_hints @query_id= 39, @query_hints = N'OPTION(RECOMPILE, MAXDOP 1, USE HINT(''QUERY_OPTIMIZER_COMPATIBILITY_LEVEL_110''))';
