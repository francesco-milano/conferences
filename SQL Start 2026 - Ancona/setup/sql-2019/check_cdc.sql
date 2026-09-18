/*
    Check CDC on AdventureWorks.

    The first result set indicates whether CDC is enabled at database level.
    The second lists the tables for which change capture is enabled.
    This query is read-only.
*/

USE [AdventureWorks];
GO

DECLARE @CdcEnabled bit;

SELECT
    @CdcEnabled = is_cdc_enabled
FROM sys.databases
WHERE name = DB_NAME();

IF @CdcEnabled IS NULL
BEGIN
    THROW 50000, 'The current database could not be found in sys.databases.', 1;
END;

SELECT
    DB_NAME() AS database_name,
    @CdcEnabled AS is_cdc_enabled,
    CASE @CdcEnabled
        WHEN 1 THEN N'CDC enabled'
        ELSE N'CDC not enabled'
    END AS cdc_status;

IF @CdcEnabled = 1
BEGIN
    SELECT
        s.name AS schema_name,
        t.name AS table_name,
        ct.capture_instance,
        ct.start_lsn,
        ct.supports_net_changes,
        ct.role_name,
        ct.index_name,
        ct.create_date
    FROM cdc.change_tables AS ct
    INNER JOIN sys.tables AS t
        ON t.object_id = ct.source_object_id
    INNER JOIN sys.schemas AS s
        ON s.schema_id = t.schema_id
    ORDER BY
        s.name,
        t.name,
        ct.capture_instance;
END
ELSE
BEGIN
    SELECT
        CONVERT(sysname, NULL) AS schema_name,
        CONVERT(sysname, NULL) AS table_name,
        CONVERT(sysname, NULL) AS capture_instance,
        CONVERT(binary(10), NULL) AS start_lsn,
        CONVERT(bit, NULL) AS supports_net_changes,
        CONVERT(sysname, NULL) AS role_name,
        CONVERT(sysname, NULL) AS index_name,
        CONVERT(datetime, NULL) AS create_date
    WHERE 1 = 0;
END;
GO