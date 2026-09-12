param(
    [Parameter(Mandatory = $true)]
    [string] $InstallerUrl
)

$ErrorActionPreference = 'Stop'
$installer = 'C:\Windows\Temp\OnPremisesDataGatewayInstaller.exe'
Invoke-WebRequest -Uri $InstallerUrl -OutFile $installer -UseBasicParsing
Start-Process -FilePath $installer -ArgumentList '/install /quiet /norestart' -Wait -PassThru | `
    ForEach-Object {
        if ($_.ExitCode -notin @(0, 3010)) {
            throw "Gateway installer exited with code $($_.ExitCode)"
        }
    }
Write-Output 'Gateway installed. Registration with Fabric remains a manual step requiring an Entra account and recovery key.'
