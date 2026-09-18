# Ambiente SQL Server per Fabric Mirroring

Questo progetto crea in `ItalyNorth` le VM necessarie per il tutorial [Fabric Mirroring da SQL Server](https://learn.microsoft.com/fabric/mirroring/sql-server-tutorial):

- `sql-demo-2019`: SQL Server 2019 con AdventureWorks ripristinato durante il deployment.
- `sql-demo-gw`: VM con On-premises data gateway installato durante il deployment.
- VNet privata, NSG e Azure Bastion per collegarsi alle VM senza esporre RDP su Internet.

Le immagini SQL Server includono costi di licenza. Azure Bastion e il relativo public IP hanno un costo separato.

## Prerequisiti

1. Installare Azure CLI.
2. Eseguire PowerShell nella cartella `setup`.
3. Avere permessi per creare resource group, VNet, Bastion, VM e marketplace images.
4. Verificare che la subscription consenta le immagini SQL Server richieste.

## Configurazione persistente

Modificare [main.bicepparam](./main.bicepparam) per cambiare regione, nomi, SKU, rete e URL del backup. Il valore `REPLACE_AT_RUNTIME` della password è solo un placeholder e viene sovrascritto da `install.ps1`; non inserire password reali nel file.

Tenant e subscription sono parametri salvati all'inizio di [install.ps1](./install.ps1):

```powershell
[string] $TenantId = 'a71860fa-71bd-440a-bf10-e4ebb31b33ce'
[string] $SubscriptionId = '60f5fd4e-b988-4a9c-abcc-786770a4c7e5'
```

Modificarli se si usa un altro ambiente. In alternativa si possono sovrascrivere senza modificare il file:

```powershell
.\install.ps1 -TenantId '<TENANT_ID>' -SubscriptionId '<SUBSCRIPTION_ID>'
```

## Deployment

Lo script:

- verifica o esegue il login nel tenant configurato;
- imposta la subscription;
- compila il template e il file parametri;
- chiede la password VM senza salvarla su disco;
- esegue il deployment e attende il completamento delle risorse;
- ripristina AdventureWorks sulla VM SQL 2019;
- configura una regola Windows Firewall per consentire TCP sulla porta SQL
  configurata dalla VNet privata;

Per eseguire una simulazione:

```powershell
.\install.ps1 -WhatIf
```

Per creare le risorse:

```powershell
.\install.ps1
```

Se il template è già stato validato:

```powershell
.\install.ps1 -SkipBuild
```

## Dopo il deployment

1. Nel resource group `rg-sql-demo`, aprire Azure Bastion `bas-sql-demo`.
2. Collegarsi alle VM usando gli IP privati restituiti dal deployment e il nome utente locale `azureadmin`.
3. Registrare manualmente l'On-premises data gateway già installato in Fabric: servono account Entra e recovery key.
4. Preparare il login e le permission SQL eseguendo
   [configure-mirror.sql](./sql-2019/configure-mirror.sql) su `sql-demo-2019`
   con SSMS in Windows Authentication. Prima dell'esecuzione, impostare nella
   variabile `@FabricLoginPassword` una password temporanea e non committarla.
   Lo script crea il login `sqldemo`, lo abilita per la configurazione iniziale
   di CDC e assegna i permessi sul database `AdventureWorks`.
5. Creare il mirrored database in Fabric seguendo il tutorial. Quando CDC è
   stato abilitato e il mirroring è attivo, eseguire la sezione `CLEANUP` dello
   script per rimuovere `sysadmin` e `db_owner`; resteranno `CONNECT` e
   `SELECT`, necessari per la replica.

## Rimozione

Per eliminare tutte le risorse:

```powershell
az group delete --name rg-sql-demo --yes --no-wait
```

Non condividere o committare password, token o file di output contenenti segreti.
