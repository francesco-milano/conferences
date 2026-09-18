[CmdletBinding()]
param(
    [string] $TenantId = 'a71860fa-71bd-440a-bf10-e4ebb31b33ce',
    [string] $SubscriptionId = '60f5fd4e-b988-4a9c-abcc-786770a4c7e5',
    [string] $ParameterFile = (Join-Path $PSScriptRoot 'main.bicepparam'),
    [switch] $WhatIf,
    [switch] $SkipBuild
)

$ErrorActionPreference = 'Stop'

function Invoke-AzureCli {
    param(
        [Parameter(Mandatory = $true)]
        [string[]] $Arguments
    )

    & az @Arguments
    if ($LASTEXITCODE -ne 0) {
        $safeArguments = $Arguments | ForEach-Object {
            if ($_ -like 'adminPassword=*') {
                'adminPassword=<redacted>'
            }
            else {
                $_
            }
        }
        throw "Azure CLI command failed with exit code $LASTEXITCODE`: az $($safeArguments -join ' ')"
    }
}

if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    throw 'Azure CLI is required. Install it from https://learn.microsoft.com/cli/azure/install-azure-cli.'
}

if (-not (Test-Path -LiteralPath $ParameterFile -PathType Leaf)) {
    throw "Parameter file not found: $ParameterFile"
}

$templateFile = Join-Path $PSScriptRoot 'main.bicep'
$deploymentLocation = 'italynorth'
$plainPassword = $null
$passwordBstr = [IntPtr]::Zero

try {
    $accountJson = & az account show --output json 2>$null
    $account = if ($LASTEXITCODE -eq 0 -and $accountJson) {
        $accountJson | ConvertFrom-Json
    }

    if (-not $account -or $account.tenantId -ne $TenantId) {
        Write-Host "Signing in to tenant $TenantId..."
        Invoke-AzureCli -Arguments @('login', '--tenant', $TenantId)
    }

    Invoke-AzureCli -Arguments @('account', 'set', '--subscription', $SubscriptionId)

    if (-not $SkipBuild) {
        Invoke-AzureCli -Arguments @('bicep', 'build', '--file', $templateFile)
        Invoke-AzureCli -Arguments @('bicep', 'build-params', '--file', $ParameterFile)
    }

    $securePassword = Read-Host 'Password amministrativa delle VM' -AsSecureString
    $passwordBstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
    $plainPassword = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($passwordBstr)

    $deploymentName = "sql-demo-$((Get-Date).ToUniversalTime().ToString('yyyyMMddHHmmss'))"
    $deploymentArguments = @(
        'deployment', 'sub'
        if ($WhatIf) { 'what-if' } else { 'create' }
        '--name', $deploymentName
        '--location', $deploymentLocation
        '--subscription', $SubscriptionId
        '--template-file', $templateFile
        '--parameters', $ParameterFile
        "adminPassword=$plainPassword"
    )

    Invoke-AzureCli -Arguments $deploymentArguments
}
finally {
    if ($passwordBstr -ne [IntPtr]::Zero) {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($passwordBstr)
    }
    $plainPassword = $null
}
