# Data Warehouse SIGETI

Ce projet implémente un Data Warehouse pour le système SIGETI (Système Intégré de Gestion des Terrains Industriels) avec une capture automatique des changements (CDC).

## Structure du Projet

- `Scripts/` : Contient tous les scripts SQL pour la création et le chargement du DWH
  - `00_cleanup_database.sql` : Nettoyage de la base de données
  - `01_create_dwh_schema.sql` : Création du schéma du DWH
  - `02_create_dimension_temps.sql` : Génération de la dimension temps
  - `03_load_staging_tables.sql` : Chargement des données dans le staging
  - `04_load_dimensions_and_facts.sql` : Alimentation des dimensions et faits
  - `05_analyse_queries.sql` : Requêtes d'analyse
- `Scripts/cdc/` : Scripts pour la capture et le traitement des changements
  - `01_setup_source_cdc.sql` : Configuration du CDC sur la base source
  - `02_apply_changes.sql` : Application des changements au DWH
  - `cdc_processor.py` : Script Python pour le traitement continu des changements

## Architecture du DWH

Le Data Warehouse utilise une architecture en étoile avec capture de données incrémentale (CDC) :

### Dimensions (avec SCD Type 2)
- Zone Industrielle
- Lot
- Entreprise
- Temps

### Faits
- Demandes d'Attribution

### Change Data Capture (CDC)
Le système utilise un mécanisme de CDC basé sur les triggers PostgreSQL pour :
- Capturer les modifications (INSERT, UPDATE, DELETE) dans la base source
- Propager automatiquement les changements vers le DWH
- Maintenir l'historique des modifications (SCD Type 2) pour les dimensions
- Mettre à jour les faits en temps quasi-réel

## Installation

1. Assurez-vous d'avoir PostgreSQL 13 ou supérieur installé
2. Créez les bases de données :
   ```bash
   createdb sigeti_node_db  # Base source
   createdb sigeti_dwh      # Data Warehouse
   ```

3. Configurez le CDC sur la base source :
   ```bash
   psql -U postgres -d sigeti_node_db -f Scripts/cdc/01_setup_source_cdc.sql
   ```

4. Créez et chargez le Data Warehouse :
   ```bash
   psql -U postgres -d sigeti_dwh -f Scripts/01_create_dwh_schema.sql
   psql -U postgres -d sigeti_dwh -f Scripts/02_create_dimension_temps.sql
   psql -U postgres -d sigeti_dwh -f Scripts/03_load_staging_tables.sql
   psql -U postgres -d sigeti_dwh -f Scripts/04_load_dimensions_and_facts.sql
   ```

5. Configurez le traitement CDC :
   ```bash
   psql -U postgres -d sigeti_dwh -f Scripts/cdc/02_apply_changes.sql
   ```

6. Démarrez le processeur CDC :
   ```bash
   python3 Scripts/cdc/cdc_processor.py
   ```

## Analyse des Données

Des requêtes d'exemple sont disponibles dans `05_analyse_queries.sql`, notamment :
- Analyse des demandes par zone et statut
- Taux d'occupation des lots
- Évolution mensuelle des demandes
- Analyse des entreprises
- Performance du traitement des demandes
- Analyse des surfaces

## Maintenance du CDC

Le processus CDC peut être :
- Surveillé via les logs dans `cdc_process.log`
- Arrêté avec Ctrl+C
- Configuré dans `Scripts/cdc/cdc_processor.py` (intervalle de synchronisation)