param vmName string
param location string
param subnetId string
param vmSize string
param adminUsername string
@secure()
param adminPassword string
param enablePublicIp bool = true
param imagePublisher string = 'MicrosoftWindowsServer'
param imageOffer string = 'WindowsServer'
param imageSku string = '2022-datacenter-azure-edition'
param identityType string = 'None'
param extensionName string = ''
param extensionScriptUri string = ''
param extensionCommand string = ''
param runCommandScript string = ''
param runCommandParameters array = []

resource publicIp 'Microsoft.Network/publicIPAddresses@2023-09-01' = if (enablePublicIp) {
  name: '${vmName}-pip'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: toLower(vmName)
    }
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2023-09-01' = {
  name: '${vmName}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnetId
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: enablePublicIp ? {
            id: publicIp.id
          } : null
        }
      }
    ]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2024-03-01' = {
  name: vmName
  location: location
  identity: identityType == 'None' ? null : {
    type: identityType
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        provisionVMAgent: true
        enableAutomaticUpdates: true
      }
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: imageSku
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
          properties: {
            primary: true
          }
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
}

resource extension 'Microsoft.Compute/virtualMachines/extensions@2024-03-01' = if (!empty(extensionName)) {
  parent: vm
  name: extensionName
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        extensionScriptUri
      ]
      commandToExecute: extensionCommand
    }
  }
}

resource runCommand 'Microsoft.Compute/virtualMachines/runCommands@2024-03-01' = if (!empty(runCommandScript)) {
  parent: vm
  name: 'post-deployment-configuration'
  location: location
  properties: {
    source: {
      script: runCommandScript
    }
    parameters: runCommandParameters
    timeoutInSeconds: 3600
  }
}

output privateIp string = nic.properties.ipConfigurations[0].properties.privateIPAddress
output publicIp string = enablePublicIp ? publicIp!.properties.ipAddress : ''
output vmId string = vm.id
