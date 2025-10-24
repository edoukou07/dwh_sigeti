-- Suppression de la base de données si elle existe
DROP DATABASE IF EXISTS sigeti_dwh;

-- Création de la base de données
CREATE DATABASE sigeti_dwh;

\c sigeti_dwh;

-- Création des schémas
CREATE SCHEMA staging;
CREATE SCHEMA dwh;

-- Dimension Temps
CREATE TABLE dwh.dim_temps (
    temps_id SERIAL PRIMARY KEY,
    date_complete DATE UNIQUE,
    annee INTEGER,
    trimestre INTEGER,
    mois INTEGER,
    jour INTEGER,
    jour_semaine INTEGER,
    nom_jour_semaine VARCHAR(10),
    nom_mois VARCHAR(10),
    est_weekend BOOLEAN
);

-- Dimension Zone Industrielle
CREATE TABLE dwh.dim_zone_industrielle (
    zone_id SERIAL PRIMARY KEY,
    zone_source_id INTEGER,
    zone_nom VARCHAR(100),
    zone_statut VARCHAR(20),
    superficie_totale DECIMAL(15,2),
    localisation VARCHAR(100),
    date_creation DATE,
    est_actif BOOLEAN,
    date_debut_validite TIMESTAMP,
    date_fin_validite TIMESTAMP
);

-- Dimension Lot
CREATE TABLE dwh.dim_lot (
    lot_id SERIAL PRIMARY KEY,
    lot_source_id INTEGER,
    zone_id INTEGER,
    superficie DECIMAL(15,2),
    prix_base DECIMAL(15,2),
    statut VARCHAR(20),
    est_viable BOOLEAN,
    priorite VARCHAR(20),
    date_debut_validite TIMESTAMP,
    date_fin_validite TIMESTAMP,
    FOREIGN KEY (zone_id) REFERENCES dwh.dim_zone_industrielle(zone_id)
);

-- Dimension Entreprise
CREATE TABLE dwh.dim_entreprise (
    entreprise_id SERIAL PRIMARY KEY,
    entreprise_source_id INTEGER,
    raison_sociale VARCHAR(200),
    domaine_activite VARCHAR(100),
    secteur VARCHAR(100),
    date_constitution DATE,
    nombre_employes_total INTEGER,
    nombre_employes_nationaux INTEGER,
    nombre_employes_expatries INTEGER,
    date_debut_validite TIMESTAMP,
    date_fin_validite TIMESTAMP
);

-- Table de Faits - Demandes
CREATE TABLE dwh.fait_demandes (
    demande_id SERIAL PRIMARY KEY,
    demande_source_id INTEGER,
    temps_id INTEGER,
    zone_id INTEGER,
    lot_id INTEGER,
    entreprise_id INTEGER,
    type_demande VARCHAR(50),
    statut VARCHAR(20),
    est_prioritaire BOOLEAN,
    duree_traitement INTEGER,
    date_creation TIMESTAMP,
    date_validation TIMESTAMP,
    date_rejet TIMESTAMP,
    FOREIGN KEY (temps_id) REFERENCES dwh.dim_temps(temps_id),
    FOREIGN KEY (zone_id) REFERENCES dwh.dim_zone_industrielle(zone_id),
    FOREIGN KEY (lot_id) REFERENCES dwh.dim_lot(lot_id),
    FOREIGN KEY (entreprise_id) REFERENCES dwh.dim_entreprise(entreprise_id)
);

-- Table de Faits - Paiements
CREATE TABLE dwh.fait_paiements (
    paiement_id SERIAL PRIMARY KEY,
    paiement_source_id INTEGER,
    temps_id INTEGER,
    entreprise_id INTEGER,
    montant DECIMAL(15,2),
    methode_paiement VARCHAR(50),
    statut_paiement VARCHAR(20),
    date_paiement TIMESTAMP,
    FOREIGN KEY (temps_id) REFERENCES dwh.dim_temps(temps_id),
    FOREIGN KEY (entreprise_id) REFERENCES dwh.dim_entreprise(entreprise_id)
);

-- Table de Faits - Occupation des Lots
CREATE TABLE dwh.fait_occupation_lots (
    occupation_id SERIAL PRIMARY KEY,
    temps_id INTEGER,
    lot_id INTEGER,
    zone_id INTEGER,
    entreprise_id INTEGER,
    statut_occupation VARCHAR(20),
    date_debut TIMESTAMP,
    date_fin TIMESTAMP,
    FOREIGN KEY (temps_id) REFERENCES dwh.dim_temps(temps_id),
    FOREIGN KEY (lot_id) REFERENCES dwh.dim_lot(lot_id),
    FOREIGN KEY (zone_id) REFERENCES dwh.dim_zone_industrielle(zone_id),
    FOREIGN KEY (entreprise_id) REFERENCES dwh.dim_entreprise(entreprise_id)
);

-- Tables de staging
CREATE TABLE staging.stg_zones_industrielles (
    id INTEGER,
    nom VARCHAR(100),
    statut VARCHAR(20),
    superficie_totale DECIMAL(15,2),
    localisation VARCHAR(100),
    date_creation DATE,
    est_actif BOOLEAN,
    date_modification TIMESTAMP
);

CREATE TABLE staging.stg_lots (
    id INTEGER,
    zone_id INTEGER,
    superficie DECIMAL(15,2),
    prix_base DECIMAL(15,2),
    statut VARCHAR(20),
    est_viable BOOLEAN,
    priorite VARCHAR(20),
    date_modification TIMESTAMP
);

CREATE TABLE staging.stg_entreprises (
    id INTEGER,
    raison_sociale VARCHAR(200),
    domaine_activite VARCHAR(100),
    secteur VARCHAR(100),
    date_constitution DATE,
    nombre_employes_total INTEGER,
    nombre_employes_nationaux INTEGER,
    nombre_employes_expatries INTEGER,
    date_modification TIMESTAMP
);

CREATE TABLE staging.stg_demandes (
    id INTEGER,
    zone_id INTEGER,
    lot_id INTEGER,
    entreprise_id INTEGER,
    type_demande VARCHAR(50),
    statut VARCHAR(20),
    est_prioritaire BOOLEAN,
    date_creation TIMESTAMP,
    date_validation TIMESTAMP,
    date_rejet TIMESTAMP,
    date_modification TIMESTAMP
);

-- Création des index
CREATE INDEX idx_dim_temps_date ON dwh.dim_temps(date_complete);
CREATE INDEX idx_dim_zone_source ON dwh.dim_zone_industrielle(zone_source_id);
CREATE INDEX idx_dim_lot_source ON dwh.dim_lot(lot_source_id);
CREATE INDEX idx_dim_entreprise_source ON dwh.dim_entreprise(entreprise_source_id);