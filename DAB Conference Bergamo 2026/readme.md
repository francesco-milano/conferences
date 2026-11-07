# Materialized Lake Views in Microsoft Fabric

Materiale della sessione **“Materialized Lake Views in Microsoft Fabric: trasformazioni dichiarative per il Lakehouse”**, presentata durante la [Data & AI Builders Conference 2026](https://dataaibuildersconf.it/).

La sessione esplora le **Materialized Lake Views (MLV)** come approccio dichiarativo per implementare trasformazioni, dependencies, refresh e Data Quality all'interno di una Medallion architecture.

## Demo

### `jumpstart_install`

È il punto di partenza della demo e installa lo scenario **Fabric Jumpstart for Materialized Lake Views**, predisponendo un ambiente Bronze → Silver → Gold pronto per sperimentare MLV, lineage, Change Data Feed e refresh.

- [Fabric Jumpstart - Materialized Lake Views](https://jumpstart.fabric.microsoft.com/catalog/materialized-lake-views/)
- [Microsoft Learn - Materialized Lake Views](https://learn.microsoft.com/en-us/fabric/data-engineering/materialized-lake-views/overview-materialized-lake-view)

### `mlv_data_quality`

Estende lo scenario Jumpstart con una demo dedicata alla **Data Quality**, mostrando l'utilizzo di declarative constraints e il comportamento di `ON MISMATCH DROP` e `ON MISMATCH FAIL`.

- [Microsoft Learn - Data Quality in Materialized Lake Views](https://learn.microsoft.com/en-us/fabric/data-engineering/materialized-lake-views/data-quality)

## Demo flow

```text
jumpstart_install
        ↓
MLV Jumpstart environment
        ↓
mlv_data_quality