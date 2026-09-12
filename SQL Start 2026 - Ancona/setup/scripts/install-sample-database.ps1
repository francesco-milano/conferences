param(
    [Parameter(Mandatory = $true)]
    [string] $BackupUrl,
    [int] $SqlPort = 1433
)

$ErrorActionPreference = 'Stop'
$log = 'C:\Windows\Temp\fabric-mirroring-sample-db.log'
Start-Transcript -Path $log -Append
try {
    $backup = 'C:\Windows\Temp\AdventureWorks.bak'
    $dataDir = 'C:\Program Files\Microsoft SQL Server\MSSQL\Data'
    New-Item -ItemType Directory -Path $dataDir -Force | Out-Null

    if (-not (Test-Path $backup)) {
        Invoke-WebRequest -Uri $BackupUrl -OutFile $backup -UseBasicParsing
    }

    $sql = @"
IF DB_ID(N'AdventureWorks') IS NULL
BEGIN
  RESTORE DATABASE [AdventureWorks]
  FROM DISK = N'$backup'
  WITH MOVE N'AdventureWorks2022' TO N'$dataDir\AdventureWorks.mdf',
       MOVE N'AdventureWorks2022_log' TO N'$dataDir\AdventureWorks_log.ldf',
       RECOVERY, REPLACE;
END;
ALTER DATABASE [AdventureWorks] SET RECOVERY FULL;
"@

    $sqlcmd = Join-Path ${env:ProgramFiles} 'Microsoft SQL Server\Client SDK\ODBC\170\Tools\Binn\sqlcmd.exe'
    if (-not (Test-Path $sqlcmd)) {
        $sqlcmd = 'sqlcmd.exe'
    }
    & $sqlcmd -S "localhost,$SqlPort" -E -b -Q $sql
    if ($LASTEXITCODE -ne 0) {
        throw "sqlcmd exited with code $LASTEXITCODE"
    }
}
finally {
    Stop-Transcript
}
