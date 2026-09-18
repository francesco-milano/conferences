/*
    Complete cleanup of the sqldemo login and CDC on AdventureWorks.

    Run in SSMS using Windows Authentication with a sysadmin account.
    This script is destructive for the CDC configuration and does not modify
    application data, but removes change tables and capture instances.
*/

USE [master];
GO

IF IS_SRVROLEMEMBER(N'sysadmin') <> 1
BEGIN
    THROW 50000, 'This cleanup must be run by a sysadmin account.', 1;
END;
GO

/*
    Remove the database principal before dropping the instance login.
*/
USE [AdventureWorks];
GO

IF EXISTS
(
    SELECT 1
    FROM sys.database_principals
    WHERE name = N'sqldemo'
)
BEGIN
    DROP USER [sqldemo];
END;
GO

/*
    Disable every remaining capture instance.
    This removes the corresponding change tables and CDC functions.
*/
IF EXISTS
(
    SELECT 1
    FROM sys.schemas
    WHERE name = N'cdc'
)
AND OBJECT_ID(N'cdc.change_tables', N'V') IS NOT NULL
BEGIN
    DECLARE
        @SourceSchema sysname,
        @SourceTable sysname,
        @CaptureInstance sysname;

    DECLARE capture_instances CURSOR LOCAL FAST_FORWARD FOR
        SELECT
            source_schema.name,
            source_table.name,
            capture_instance
        FROM cdc.change_tables AS change_table
        INNER JOIN sys.tables AS source_table
            ON source_table.object_id = change_table.source_object_id
        INNER JOIN sys.schemas AS source_schema
            ON source_schema.schema_id = source_table.schema_id;

    OPEN capture_instances;

    FETCH NEXT FROM capture_instances
        INTO @SourceSchema, @SourceTable, @CaptureInstance;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        EXEC sys.sp_cdc_disable_table
            @source_schema = @SourceSchema,
            @source_name = @SourceTable,
            @capture_instance = @CaptureInstance;

        FETCH NEXT FROM capture_instances
            INTO @SourceSchema, @SourceTable, @CaptureInstance;
    END;

    CLOSE capture_instances;
    DEALLOCATE capture_instances;
END;
GO

/*
    Disable CDC at database level.
    The procedure also removes metadata, functions, the CDC schema, and any
    CDC jobs created for the database.
*/
IF EXISTS
(
    SELECT 1
    FROM sys.databases
    WHERE name = DB_NAME()
      AND is_cdc_enabled = 1
)
BEGIN
    EXEC sys.sp_cdc_disable_db;
END;
GO

/*
    Drop the instance login after removing its sysadmin membership.
*/
USE [master];
GO

IF EXISTS
(
    SELECT 1
    FROM sys.server_principals
    WHERE name = N'sqldemo'
)
BEGIN
    IF IS_SRVROLEMEMBER(N'sysadmin', N'sqldemo') = 1
    BEGIN
        ALTER SERVER ROLE [sysadmin] DROP MEMBER [sqldemo];
    END;

    DROP LOGIN [sqldemo];
END;
GO

/*
    Final verification: all queries should return zero rows, except for the
    database status, which should show that CDC is disabled.
*/
SELECT
    name AS database_name,
    is_cdc_enabled
FROM sys.databases
WHERE name = N'AdventureWorks';

SELECT
    name AS database_principal
FROM AdventureWorks.sys.database_principals
WHERE name = N'sqldemo';

SELECT
    name AS server_principal
FROM sys.server_principals
WHERE name = N'sqldemo';

USE [AdventureWorks];
GO

SELECT
    name AS remaining_cdc_schema
FROM sys.schemas
WHERE name = N'cdc';
GO