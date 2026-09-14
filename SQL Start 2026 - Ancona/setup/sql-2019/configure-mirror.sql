/*
    Preparazione del login usato da Fabric Mirroring su SQL Server 2019.

    Eseguire questo script da SSMS con Windows Authentication e con un account
    sysadmin, prima di creare il mirrored database in Fabric.

    La password non viene salvata nel repository: valorizzare la variabile
    @FabricLoginPassword solo nella sessione locale prima di eseguire lo script.
*/

USE [master];
GO

DECLARE @FabricLogin sysname = N'sqldemo';
DECLARE @FabricLoginPassword nvarchar(128) = N'';
DECLARE @Sql nvarchar(max);

IF @FabricLoginPassword = N''
   AND NOT EXISTS
   (
       SELECT 1
       FROM sys.server_principals
       WHERE name = @FabricLogin
   )
BEGIN
    THROW 50000, 'Impostare @FabricLoginPassword prima di eseguire lo script.', 1;
END;

IF NOT EXISTS
(
    SELECT 1
    FROM sys.server_principals
    WHERE name = @FabricLogin
)
BEGIN
    SET @Sql = N'CREATE LOGIN ' + QUOTENAME(@FabricLogin)
        + N' WITH PASSWORD = ' + QUOTENAME(@FabricLoginPassword, '''') + N';';
    EXEC sys.sp_executesql @Sql;
END;

GRANT CONNECT SQL TO [sqldemo];

/*
    SQL Server 2019 usa CDC per il mirroring. Fabric deve poter abilitare e
    gestire CDC durante la configurazione iniziale, perciò il login è
    temporaneamente sysadmin. Rimuovere questo ruolo dopo l'attivazione del
    mirroring usando la sezione di cleanup in fondo al file.
*/
IF NOT EXISTS
(
    SELECT 1
    FROM sys.server_role_members AS srm
    INNER JOIN sys.server_principals AS role_principal
        ON role_principal.principal_id = srm.role_principal_id
    INNER JOIN sys.server_principals AS login_principal
        ON login_principal.principal_id = srm.member_principal_id
    WHERE role_principal.name = N'sysadmin'
      AND login_principal.name = @FabricLogin
)
BEGIN
    ALTER SERVER ROLE [sysadmin] ADD MEMBER [sqldemo];
END;
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

/*
    db_owner è richiesto dal tutorial per la gestione di CDC su SQL Server
    2016-2022. Il ruolo sysadmin resta comunque necessario per abilitarlo.
*/
ALTER ROLE [db_owner] ADD MEMBER [sqldemo];
GO

/*
    CLEANUP (eseguire solo dopo che CDC è stato abilitato e il mirrored
    database è attivo):

    USE [master];
    ALTER SERVER ROLE [sysadmin] DROP MEMBER [sqldemo];
    GO

    USE [AdventureWorks];
    ALTER ROLE [db_owner] DROP MEMBER [sqldemo];
    -- CONNECT e SELECT restano le permission necessarie per la replica.
    GO
*/