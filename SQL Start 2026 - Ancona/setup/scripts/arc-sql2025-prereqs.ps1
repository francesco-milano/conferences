$ErrorActionPreference = 'Stop'

Write-Output 'Checking prerequisites for Azure Arc-enabled SQL Server.'
$os = Get-CimInstance Win32_OperatingSystem
Write-Output "Operating system: $($os.Caption)"

$identityEndpoint = 'http://169.254.169.254/metadata/identity/info?api-version=2018-02-01'
try {
    $identity = Invoke-RestMethod -Headers @{ Metadata = 'true' } -Uri $identityEndpoint -Method Get
    Write-Output "Managed identity endpoint is available: $($identity.client_id)"
}
catch {
    Write-Warning 'Managed identity endpoint is not available yet. Verify the VM system-assigned identity after deployment.'
}

Write-Output 'Install/connect Azure Arc and the SQL extension from an operator workstation with the required subscription permissions.'
