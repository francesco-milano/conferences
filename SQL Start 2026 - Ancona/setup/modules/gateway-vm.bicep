param vmName string
param location string
param subnetId string
param vmSize string
param adminUsername string
@secure()
param adminPassword string
param enablePublicIp bool
param gatewayInstallerUrl string

module base '../modules/windows-vm.bicep' = {
  name: '${vmName}-base'
  params: {
    vmName: vmName
    location: location
    subnetId: subnetId
    vmSize: vmSize
    adminUsername: adminUsername
    adminPassword: adminPassword
    enablePublicIp: enablePublicIp
    extensionName: !empty(gatewayInstallerUrl) ? 'install-data-gateway' : ''
    extensionScriptUri: 'https://raw.githubusercontent.com/francesco-milano/conferences/main/SQL%20Start%202026%20-%20Ancona/setup/scripts/install-data-gateway.ps1'
    extensionCommand: !empty(gatewayInstallerUrl) ? 'powershell.exe -ExecutionPolicy Bypass -File install-data-gateway.ps1 -InstallerUrl "${gatewayInstallerUrl}"' : ''
  }
}

output privateIp string = base.outputs.privateIp
output publicIp string = base.outputs.publicIp
