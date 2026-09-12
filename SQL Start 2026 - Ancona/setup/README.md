# Azure SQL Server environment for Fabric Mirroring

Questo template Bicep prepara l'ambiente del tutorial [Fabric Mirroring da SQL Server](https://learn.microsoft.com/fabric/mirroring/sql-server-tutorial).

## Risorse

- `sql-demo-2019`: immagine marketplace SQL Server 2019 e script opzionale per AdventureWorks.
- `sql-demo-2025`: immagine marketplace SQL Server 2025 con identità gestita assegnata.
- `sql-demo-gw`: Windows VM destinata all'installazione dell'On-premises data gateway.
- VNet/subnet privata condivisa, subnet `AzureBastionSubnet` `/26` e Azure Bastion con public IP dedicato.
- Le VM non hanno IP pubblici; RDP è consentito solo dal subnet Bastion e non è esposto direttamente a Internet.

Le immagini SQL con licenza inclusa possono costare più del solo compute. Verificare SKU e disponibilità nella regione scelta.

## Prerequisiti

1. Azure CLI con estensione Bicep aggiornata: `az bicep upgrade`.
2. Permessi per creare resource group, rete, VM, marketplace images e VM extensions.
3. Accettazione dei termini marketplace per le immagini SQL, se richiesta dalla sottoscrizione.
4. Considerare il costo orario di Azure Bastion e del public IP Standard. Il Bastion consente l'accesso RDP dal portale senza autorizzare un CIDR amministrativo nel template.

## Validazione e deployment

```powershell
az bicep build --file .\main.bicep
az deployment sub what-if `
  --location westeurope `
  --template-file .\main.bicep `
  --parameters .\main.bicepparam.example adminPassword='<NON SALVARE QUESTA PASSWORD>'
```

Per il deployment usare una password fornita da prompt o da un secret store:

```powershell
az deployment sub create `
  --location westeurope `
  --template-file .\main.bicep `
  --parameters .\main.bicepparam.example adminPassword='<PASSWORD SICURA>'
```

Il file `main.bicepparam.example` è solo un esempio: non committare password o altri parametri con segreti.

## Passaggi manuali dopo il deployment

1. Verificare gli IP privati e l'output `bastionPublicIp`.
2. Aprire Azure Portal > Bastion > `bas-sql-demo` e usare Connect per raggiungere le VM via RDP. Nessun IP pubblico viene assegnato alle VM.
3. Sul gateway, installare/registrare manualmente l'On-premises data gateway in Fabric. La registrazione richiede account Entra e recovery key e non può essere completata da Bicep.
4. Per `sql-demo-2025`, verificare la system-assigned managed identity e completare l'onboarding Azure Arc/SQL extension con un operatore autorizzato. Lo script `scripts/arc-sql2025-prereqs.ps1` esegue solo controlli locali.
5. Il deployment esegue `scripts/install-sample-database.ps1` tramite una VM run command incorporata nel template e attende il completamento del ripristino di AdventureWorks. Verificare quindi il database e configurare CDC/login secondo la documentazione Fabric.
6. Testare dal gateway la connettività TCP verso gli IP privati SQL sulla porta configurata.

## Cleanup

```powershell
az group delete --name rg-sql-demo --yes --no-wait
```

Non eseguire i dataflow Fabric da questo repository: il template prepara solo l'infrastruttura Azure.
