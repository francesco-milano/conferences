using './main.bicep'

param location = 'italynorth'
param resourceGroupName = 'rg-sql-demo'
param adminUsername = 'azureadmin'
param adminPassword = 'REPLACE_AT_RUNTIME'
param vnetAddressPrefix = '10.40.0.0/16'
param subnetAddressPrefix = '10.40.0.0/24'
param bastionSubnetAddressPrefix = '10.40.1.0/26'
param vmSize = 'Standard_B2ms'
param sqlPort = 1433
param adventureWorksBackupUrl = 'https://github.com/Microsoft/sql-server-samples/releases/download/adventureworks/AdventureWorks2019.bak'
param gatewayInstallerUrl = 'https://go.microsoft.com/fwlink/?LinkId=2116849&clcid=0x409'
