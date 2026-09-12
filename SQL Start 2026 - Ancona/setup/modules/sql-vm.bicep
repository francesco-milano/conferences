param vmName string
param location string
param subnetId string
param vmSize string
param adminUsername string
@secure()
param adminPassword string
param enablePublicIp bool
param sqlPort int
param sqlOffer string
param sqlSku string
param backupUrl string
param installDatabase bool
param enableSystemAssignedIdentity bool = false

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
    imagePublisher: 'MicrosoftSQLServer'
    imageOffer: sqlOffer
    imageSku: sqlSku
    identityType: enableSystemAssignedIdentity ? 'SystemAssigned' : 'None'
    extensionName: ''
    extensionScriptUri: ''
    extensionCommand: ''
    runCommandScript: installDatabase ? loadTextContent('../scripts/install-sample-database.ps1') : ''
    runCommandParameters: installDatabase ? [
      {
        name: 'BackupUrl'
        value: backupUrl
      }
      {
        name: 'SqlPort'
        value: string(sqlPort)
      }
    ] : []
  }
}

output privateIp string = base.outputs.privateIp
output publicIp string = base.outputs.publicIp
