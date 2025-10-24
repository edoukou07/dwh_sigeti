# Data Warehouse SIGETI

Ce projet implémente un Data Warehouse pour le système SIGETI (Système Intégré de Gestion des Terrains Industriels).

## Structure du Projet

- `Scripts/` : Contient tous les scripts SQL pour la création et le chargement du DWH
  - `00_cleanup_database.sql` : Nettoyage de la base de données
  - `01_create_dwh_schema.sql` : Création du schéma du DWH
  - `02_create_dimension_temps.sql` : Génération de la dimension temps
  - `03_load_staging_tables.sql` : Chargement des données dans le staging
  - `04_load_dimensions_and_facts.sql` : Alimentation des dimensions et faits
  - `05_analyse_queries.sql` : Requêtes d'analyse

## Architecture du DWH

Le Data Warehouse utilise une architecture en étoile avec :

### Dimensions
- Zone Industrielle (SCD Type 2)
- Lot (SCD Type 2)
- Entreprise (SCD Type 2)
- Temps

### Faits
- Demandes d'Attribution

## Installation

1. Assurez-vous d'avoir PostgreSQL 13 ou supérieur installé
2. Créez une base de données nommée "sigeti_dwh"
3. Exécutez les scripts dans l'ordre numérique :
   ```bash
   psql -U postgres -d sigeti_dwh -f Scripts/01_create_dwh_schema.sql
   psql -U postgres -d sigeti_dwh -f Scripts/02_create_dimension_temps.sql
   psql -U postgres -d sigeti_dwh -f Scripts/03_load_staging_tables.sql
   psql -U postgres -d sigeti_dwh -f Scripts/04_load_dimensions_and_facts.sql
   ```

## Analyse des Données

Des requêtes d'exemple sont disponibles dans `05_analyse_queries.sql`, notamment :
- Analyse des demandes par zone et statut
- Taux d'occupation des lots
- Évolution mensuelle des demandes
- Analyse des entreprises
- Performance du traitement des demandes
- Analyse des surfaces