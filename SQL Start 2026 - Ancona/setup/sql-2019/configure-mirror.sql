/*
    Prepare the login used by Fabric Mirroring on SQL Server 2019.

    Run this script from SSMS using Windows Authentication and a sysadmin
    account, before creating the mirrored database in Fabric.

    The password is not stored in the repository: set the
    @FabricLoginPassword variable only in the local session before running
    the script.
*/

USE [master];
GO

DECLARE @FabricLoginPassword nvarchar(128) = N'';
DECLARE @Sql nvarchar(max);

IF @FabricLoginPassword = N''
   AND NOT EXISTS
   (
       SELECT 1
       FROM sys.server_principals
       WHERE name = N'sqldemo'
   )
BEGIN
    THROW 50000, 'Set @FabricLoginPassword before running the script.', 1;
END;

IF NOT EXISTS
(
    SELECT 1
    FROM sys.server_principals
    WHERE name = 'sqldemo'
)
BEGIN
    SET @Sql = N'CREATE LOGIN ' + QUOTENAME('sqldemo')
        + N' WITH PASSWORD = ' + QUOTENAME(@FabricLoginPassword, '''') + N';';
    EXEC sys.sp_executesql @Sql;
END;

GRANT CONNECT SQL TO [sqldemo];
GO

USE [AdventureWorks];
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.database_principals
    WHERE name = N'sqldemo'
)
BEGIN
    CREATE USER [sqldemo] FOR LOGIN [sqldemo];
END;

GRANT CONNECT TO [sqldemo];
GRANT SELECT TO [sqldemo];
GO

/*
    SQL Server 2019 uses CDC for mirroring. Fabric must be able to enable and
    manage CDC during the initial configuration, so the login is temporarily
    granted sysadmin. Remove this role after mirroring is activated by using
    the cleanup section at the end of this file.

USE [master];
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.server_role_members AS srm
    INNER JOIN sys.server_principals AS role_principal
        ON role_principal.principal_id = srm.role_principal_id
    INNER JOIN sys.server_principals AS login_principal
        ON login_principal.principal_id = srm.member_principal_id
    WHERE role_principal.name = N'sysadmin'
      AND login_principal.name = 'sqldemo'
)
BEGIN
    ALTER SERVER ROLE [sysadmin] ADD MEMBER [sqldemo];
END;
GO
*/

/*
    CLEANUP (run only after CDC has been enabled and the mirrored database is
    active):

    -- CONNECT and SELECT on AdventurWorks remain the permissions required for replication.

    USE [master];
    ALTER SERVER ROLE [sysadmin] DROP MEMBER [sqldemo];
    GO

*/