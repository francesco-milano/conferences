$InstallerUrl = '__INSTALLER_URL__'
$ErrorActionPreference = 'Stop'
$installer = 'C:\Windows\Temp\OnPremisesDataGatewayInstaller.exe'

try {
    $client = [Net.WebClient]::new()
    try { $client.DownloadFile($InstallerUrl, $installer) } finally { $client.Dispose() }
    if ((Get-Item $installer).Length -eq 0) {
        throw 'The gateway installer is empty.'
    }

    $process = Start-Process -FilePath $installer `
        -ArgumentList @('/install', '/quiet', '/norestart') `
        -Wait `
        -PassThru
    if ($process.ExitCode -notin @(0, 3010)) {
        throw "Gateway installer exited with code $($process.ExitCode)"
    }

    $service = Get-Service -Name PBIEgwService -ErrorAction Stop
    if ($service.Status -ne 'Running') {
        Start-Service -Name PBIEgwService
    }
}
catch {
    Write-Error $_
    exit 1
}
