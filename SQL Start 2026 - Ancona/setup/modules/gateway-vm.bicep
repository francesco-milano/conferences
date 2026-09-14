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
    extensionName: ''
    extensionScriptUri: ''
    extensionCommand: ''
    runCommandScript: replace(loadTextContent('../scripts/install-data-gateway.ps1'), '__INSTALLER_URL__', gatewayInstallerUrl)
    runCommandParameters: []
  }
}

output privateIp string = base.outputs.privateIp
output publicIp string = base.outputs.publicIp
