-- check ultime sessioni di scan
SELECT * FROM sys.dm_change_feed_log_scan_sessions order by start_time desc;

-- check errori di sync
SELECT * FROM sys.dm_change_feed_errors order by entry_time desc;

-- check target di replica
EXEC sp_help_change_feed;

-- check flag di replica attiva
SELECT
    d.[name] AS database_name,
    d.is_data_lake_replication_enabled
FROM sys.databases AS d
WHERE d.[name] = DB_NAME();

-- forza chiusura change feed
EXEC sys.sp_change_feed_disable_db; 