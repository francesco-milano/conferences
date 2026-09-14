targetScope = 'subscription'

@description('Azure region for all resources.')
param location string = 'italynorth'

@description('Resource group name.')
param resourceGroupName string = 'rg-sql-demo'

@description('Local administrator user for all VMs.')
param adminUsername string = 'azureadmin'

@secure()
@description('Local administrator password. Supply it at deployment time or through a secure parameter file.')
param adminPassword string

@description('Virtual network address space.')
param vnetAddressPrefix string = '10.40.0.0/16'

@description('Subnet address space.')
param subnetAddressPrefix string = '10.40.0.0/24'

@description('Azure Bastion subnet address space. Must be at least /26 and named AzureBastionSubnet.')
param bastionSubnetAddressPrefix string = '10.40.1.0/26'

@description('Low-cost VM size. Confirm regional availability before deployment.')
param vmSize string = 'Standard_B2ms'

@description('SQL Server TCP port exposed inside the private subnet.')
param sqlPort int = 1433

@description('AdventureWorks 2019 backup URL used by the SQL VM post-deployment scripts.')
param adventureWorksBackupUrl string = 'https://github.com/Microsoft/sql-server-samples/releases/download/adventureworks/AdventureWorks2019.bak'

@description('Official standard on-premises data gateway installer URL.')
param gatewayInstallerUrl string = 'https://go.microsoft.com/fwlink/?LinkId=2116849&clcid=0x409'

resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: resourceGroupName
  location: location
}

module network 'modules/network.bicep' = {
  name: 'network'
  scope: rg
  params: {
    vnetName: 'vnet-sql-demo'
    vnetAddressPrefix: vnetAddressPrefix
    subnetAddressPrefix: subnetAddressPrefix
    sqlPort: sqlPort
    bastionSubnetAddressPrefix: bastionSubnetAddressPrefix
  }
}

module bastion 'modules/bastion.bicep' = {
  name: 'bastion'
  scope: rg
  params: {
    location: location
    vnetName: 'vnet-sql-demo'
  }
  dependsOn: [
    network
  ]
}

module sql2019 'modules/sql-vm.bicep' = {
  name: 'sql2019'
  scope: rg
  params: {
    vmName: 'sql-demo-2019'
    location: location
    subnetId: network.outputs.subnetId
    vmSize: vmSize
    adminUsername: adminUsername
    adminPassword: adminPassword
    enablePublicIp: false
    sqlPort: sqlPort
    sqlOffer: 'sql2019-ws2019'
    sqlSku: 'standard'
    backupUrl: adventureWorksBackupUrl
    installDatabase: true
  }
}

module gateway 'modules/gateway-vm.bicep' = {
  name: 'gateway'
  scope: rg
  params: {
    vmName: 'sql-demo-gw'
    location: location
    subnetId: network.outputs.subnetId
    vmSize: vmSize
    adminUsername: adminUsername
    adminPassword: adminPassword
    enablePublicIp: false
    gatewayInstallerUrl: gatewayInstallerUrl
  }
}

output resourceGroupName string = rg.name
output sql2019PrivateIp string = sql2019.outputs.privateIp
output gatewayPrivateIp string = gateway.outputs.privateIp
output bastionName string = bastion.outputs.bastionName
output bastionPublicIp string = bastion.outputs.publicIp
