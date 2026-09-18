$BackupUrl = '__BACKUP_URL__'
$SqlPort = __SQL_PORT__
$ErrorActionPreference = 'Stop'

function Invoke-SqlCommand {
    param([string[]] $Arguments)

    $Arguments = @('-C') + $Arguments
    $outFile = 'C:\Windows\Temp\adventureworks-sqlcmd.out'
    $errFile = 'C:\Windows\Temp\adventureworks-sqlcmd.err'
    $process = Start-Process -FilePath $script:SqlCmd `
        -ArgumentList $Arguments `
        -RedirectStandardOutput $outFile `
        -RedirectStandardError $errFile `
        -Wait `
        -PassThru
    if ($process.ExitCode -ne 0) {
        Get-Content $outFile, $errFile -ErrorAction SilentlyContinue | Write-Output
        throw "sqlcmd exited with code $($process.ExitCode)"
    }
    Get-Content $outFile -ErrorAction SilentlyContinue
}

try {
    $firewallRuleName = "Allow-SQL-TCP-$SqlPort"
    $existingFirewallRule = Get-NetFirewallRule -DisplayName $firewallRuleName -ErrorAction SilentlyContinue
    if (-not $existingFirewallRule) {
        New-NetFirewallRule `
            -DisplayName $firewallRuleName `
            -Direction Inbound `
            -Action Allow `
            -Protocol TCP `
            -LocalPort $SqlPort `
            -Profile Domain,Private `
            -ErrorAction Stop | Out-Null
    }

    $deadline = (Get-Date).AddMinutes(20)
    do {
        $sqlService = Get-Service -Name 'MSSQL*' -ErrorAction SilentlyContinue |
            Where-Object DisplayName -like 'SQL Server (*' |
            Select-Object -First 1
        if ($sqlService -and $sqlService.Status -ne 'Running') {
            Start-Service -Name $sqlService.Name -ErrorAction SilentlyContinue
        }
        $script:SqlCmd = Get-ChildItem 'C:\Program Files\Microsoft SQL Server' -Recurse -Filter sqlcmd.exe -ErrorAction SilentlyContinue |
            Select-Object -First 1 -ExpandProperty FullName
        if ($sqlService -and $sqlService.Status -eq 'Running' -and $script:SqlCmd) {
            break
        }
        Start-Sleep -Seconds 10
    } while ((Get-Date) -lt $deadline)

    $backupDirectory = Get-ChildItem 'C:\Program Files\Microsoft SQL Server' -Directory -Recurse -ErrorAction SilentlyContinue |
        Where-Object FullName -like '*\MSSQL\Backup' |
        Select-Object -First 1 -ExpandProperty FullName
    $instanceRoot = Get-ChildItem 'C:\Program Files\Microsoft SQL Server' -Directory -ErrorAction SilentlyContinue |
        Where-Object Name -like 'MSSQL*' |
        Sort-Object Name -Descending |
        Select-Object -First 1 -ExpandProperty FullName
    $dataDirectory = Join-Path $instanceRoot 'MSSQL\Data'
    $logDirectory = Join-Path $instanceRoot 'MSSQL\Log'
    if (-not $script:SqlCmd -or -not $instanceRoot -or -not $backupDirectory -or -not (Test-Path $dataDirectory) -or -not (Test-Path $logDirectory)) {
        throw 'SQL Server or sqlcmd was not ready after 20 minutes.'
    }

    $backup = Join-Path $backupDirectory ([IO.Path]::GetFileName(([Uri]$BackupUrl).AbsolutePath))
    if (-not (Test-Path $backup) -or (Get-Item $backup).Length -eq 0) {
        $client = [Net.WebClient]::new()
        try { $client.DownloadFile($BackupUrl, $backup) } finally { $client.Dispose() }
    }
    if ((Get-Item $backup).Length -eq 0) {
        throw "AdventureWorks backup is empty: $backup"
    }

    $fileListSql = "RESTORE FILELISTONLY FROM DISK = N'$($backup.Replace('''', ''''''))'"
    $fileListFile = 'C:\Windows\Temp\adventureworks-filelist.sql'
    Set-Content -Path $fileListFile -Value $fileListSql -Encoding UTF8
    $fileRows = Invoke-SqlCommand @('-S', "localhost,$SqlPort", '-E', '-b', '-i', $fileListFile, '-s', '|', '-W', '-h', '-1', '-w', '65535')
    $files = $fileRows | ForEach-Object {
        $columns = $_ -split '\|'
        if ($columns.Count -ge 3 -and $columns[0].Trim()) {
            [PSCustomObject]@{ LogicalName = $columns[0].Trim(); Type = $columns[2].Trim() }
        }
    }
    if (-not $files) { throw 'No files were found in the AdventureWorks backup.' }

    $moves = for ($i = 0; $i -lt $files.Count; $i++) {
        $file = $files[$i]
        $folder = if ($file.Type -eq 'L') { $logDirectory } else { $dataDirectory }
        $extension = if ($file.Type -eq 'L') { 'ldf' } elseif ($i -eq 0) { 'mdf' } else { 'ndf' }
        $path = Join-Path $folder "AdventureWorks_$i.$extension"
        "MOVE N'$($file.LogicalName.Replace('''', ''''''))' TO N'$($path.Replace('''', ''''''))'"
    }

    $sqlFile = 'C:\Windows\Temp\adventureworks-restore.sql'
    $sql = "RESTORE DATABASE [AdventureWorks] FROM DISK = N'$($backup.Replace('''', ''''''))' WITH $($moves -join ', '), REPLACE, RECOVERY; ALTER DATABASE [AdventureWorks] SET RECOVERY FULL;"
    Set-Content -Path $sqlFile -Value $sql -Encoding UTF8
    Invoke-SqlCommand @('-S', "localhost,$SqlPort", '-E', '-b', '-i', $sqlFile) | Out-Null

    $verifyFile = 'C:\Windows\Temp\adventureworks-verify.sql'
    Set-Content -Path $verifyFile -Value "IF DB_ID(N'AdventureWorks') IS NULL THROW 50000, 'AdventureWorks restore did not create the database.', 1; SELECT N'AdventureWorks is ready.';" -Encoding UTF8
    Invoke-SqlCommand @('-S', "localhost,$SqlPort", '-E', '-b', '-i', $verifyFile) | Out-Null
}
catch {
    Write-Error $_
    exit 1
}
