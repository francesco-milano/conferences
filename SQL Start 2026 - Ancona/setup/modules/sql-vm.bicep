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
    identityType: 'None'
    extensionName: ''
    extensionScriptUri: ''
    extensionCommand: ''
    runCommandScript: installDatabase
      ? replace(
          replace(
            loadTextContent('../scripts/install-sample-database.ps1'),
            '__BACKUP_URL__',
            backupUrl
          ),
          '__SQL_PORT__',
          string(sqlPort)
        )
      : ''
    runCommandParameters: []
  }
}

output privateIp string = base.outputs.privateIp
output publicIp string = base.outputs.publicIp
