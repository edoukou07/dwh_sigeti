-- Configuration du DWH
DROP DATABASE IF EXISTS sigeti_dwh;
CREATE DATABASE sigeti_dwh;
\c sigeti_dwh

-- Créer les schémas
CREATE SCHEMA IF NOT EXISTS staging;
CREATE SCHEMA IF NOT EXISTS dwh;
CREATE SCHEMA IF NOT EXISTS cdc;

-- Configuration
SET search_path = dwh, staging, public;

-- Dimension temps
CREATE TABLE dim_temps (
    temps_id SERIAL PRIMARY KEY,
    date DATE NOT NULL,
    annee INTEGER,
    trimestre INTEGER,
    mois INTEGER,
    jour INTEGER,
    jour_semaine INTEGER,
    semaine INTEGER,
    est_weekend BOOLEAN,
    est_ferie BOOLEAN,
    UNIQUE (date)
);

-- Dimension zone industrielle
CREATE TABLE dim_zone_industrielle (
    zone_id SERIAL PRIMARY KEY,
    zone_source_id INTEGER NOT NULL,
    code VARCHAR(50) NOT NULL,
    libelle VARCHAR(100) NOT NULL,
    description TEXT,
    superficie NUMERIC(10,2),
    adresse TEXT,
    statut VARCHAR(20),
    lots_disponibles INTEGER,
    date_debut_validite TIMESTAMP NOT NULL,
    date_fin_validite TIMESTAMP NOT NULL,
    est_courant BOOLEAN NOT NULL DEFAULT true
);

-- Dimension lot
CREATE TABLE dim_lot (
    lot_id SERIAL PRIMARY KEY,
    lot_source_id INTEGER NOT NULL,
    zone_id INTEGER REFERENCES dim_zone_industrielle(zone_id),
    numero VARCHAR(50) NOT NULL,
    ilot VARCHAR(50),
    superficie NUMERIC(10,2),
    unite_mesure VARCHAR(20),
    prix NUMERIC(12,2),
    statut VARCHAR(20),
    description TEXT,
    date_debut_validite TIMESTAMP NOT NULL,
    date_fin_validite TIMESTAMP NOT NULL,
    est_courant BOOLEAN NOT NULL DEFAULT true
);

-- Dimension entreprise
CREATE TABLE dim_entreprise (
    entreprise_id SERIAL PRIMARY KEY,
    entreprise_source_id INTEGER NOT NULL,
    raison_sociale VARCHAR(200) NOT NULL,
    forme_juridique VARCHAR(50),
    registre_commerce VARCHAR(100),
    compte_contribuable VARCHAR(100),
    adresse TEXT,
    telephone VARCHAR(50),
    email VARCHAR(100),
    date_debut_validite TIMESTAMP NOT NULL,
    date_fin_validite TIMESTAMP NOT NULL,
    est_courant BOOLEAN NOT NULL DEFAULT true
);

-- Table des faits - Demandes d'attribution
CREATE TABLE fait_demandes_attribution (
    demande_id SERIAL PRIMARY KEY,
    demande_source_id INTEGER NOT NULL,
    temps_id INTEGER REFERENCES dim_temps(temps_id),
    zone_id INTEGER REFERENCES dim_zone_industrielle(zone_id),
    lot_id INTEGER REFERENCES dim_lot(lot_id),
    entreprise_id INTEGER REFERENCES dim_entreprise(entreprise_id),
    numero_demande VARCHAR(100),
    type_demande VARCHAR(50),
    statut VARCHAR(20),
    est_prioritaire BOOLEAN,
    duree_traitement INTEGER, -- en jours
    date_creation TIMESTAMP,
    date_validation TIMESTAMP,
    date_rejet TIMESTAMP,
    UNIQUE(demande_source_id)
);