-- =============================================================================
-- MIGRATION DWH SIGETI COMPLET DE sigeti_node_db VERS sigeti_dwh
-- =============================================================================

-- 1. Création des schémas
CREATE SCHEMA IF NOT EXISTS dwh;
CREATE SCHEMA IF NOT EXISTS cdc;
CREATE SCHEMA IF NOT EXISTS staging;
CREATE SCHEMA IF NOT EXISTS etl;
CREATE SCHEMA IF NOT EXISTS monitoring;

-- 2. TABLES DE DIMENSIONS
-- =====================

-- Dimension Temps
CREATE TABLE dwh.dim_temps (
    temps_key SERIAL PRIMARY KEY,
    date_complete DATE UNIQUE NOT NULL,
    annee INTEGER,
    mois INTEGER,
    jour INTEGER,
    trimestre INTEGER,
    nom_mois VARCHAR(20),
    nom_jour_semaine VARCHAR(20),
    numero_semaine INTEGER,
    est_week_end BOOLEAN DEFAULT FALSE,
    est_jour_ferie BOOLEAN DEFAULT FALSE,
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Dimension Statuts
CREATE TABLE dwh.dim_statuts (
    statut_key SERIAL PRIMARY KEY,
    statut_id INTEGER UNIQUE,
    nom_statut VARCHAR(100),
    description_statut TEXT,
    couleur_statut VARCHAR(10),
    ordre_affichage INTEGER,
    est_actif BOOLEAN DEFAULT TRUE,
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Dimension Zones Industrielles
CREATE TABLE dwh.dim_zones_industrielles (
    zone_key SERIAL PRIMARY KEY,
    zone_id INTEGER UNIQUE,
    nom_zone VARCHAR(200),
    localisation VARCHAR(200),
    superficie_totale DECIMAL(12,2),
    nb_lots_total INTEGER,
    statut_zone VARCHAR(50),
    date_creation_zone DATE,
    responsable_zone VARCHAR(100),
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Dimension Lots
CREATE TABLE dwh.dim_lots (
    lot_key SERIAL PRIMARY KEY,
    lot_id INTEGER UNIQUE,
    zone_key INTEGER REFERENCES dwh.dim_zones_industrielles(zone_key),
    numero_lot VARCHAR(50),
    superficie DECIMAL(10,2),
    prix_m2 DECIMAL(10,2),
    statut_lot VARCHAR(50),
    type_lot VARCHAR(50),
    coordonnees_gps VARCHAR(100),
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Dimension Entreprises
CREATE TABLE dwh.dim_entreprises (
    entreprise_key SERIAL PRIMARY KEY,
    entreprise_id INTEGER UNIQUE,
    nom_entreprise VARCHAR(200),
    forme_juridique VARCHAR(100),
    secteur_activite VARCHAR(100),
    taille_entreprise VARCHAR(50),
    chiffre_affaires DECIMAL(15,2),
    nb_employes INTEGER,
    pays VARCHAR(100),
    region VARCHAR(100),
    date_creation_entreprise DATE,
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Dimension Opérateurs
CREATE TABLE dwh.dim_operateurs (
    operateur_key SERIAL PRIMARY KEY,
    operateur_id INTEGER UNIQUE,
    nom_operateur VARCHAR(100),
    prenom_operateur VARCHAR(100),
    fonction VARCHAR(100),
    departement VARCHAR(100),
    niveau_acces VARCHAR(50),
    email VARCHAR(200),
    telephone VARCHAR(20),
    date_embauche DATE,
    est_actif BOOLEAN DEFAULT TRUE,
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. TABLES DE FAITS
-- ==================

-- Fait Demandes d'Attribution
CREATE TABLE dwh.fait_demandes_attribution (
    demande_key SERIAL PRIMARY KEY,
    temps_key INTEGER REFERENCES dwh.dim_temps(temps_key),
    lot_key INTEGER REFERENCES dwh.dim_lots(lot_key),
    entreprise_key INTEGER REFERENCES dwh.dim_entreprises(entreprise_key),
    statut_key INTEGER REFERENCES dwh.dim_statuts(statut_key),
    operateur_key INTEGER REFERENCES dwh.dim_operateurs(operateur_key),
    
    -- Métriques
    montant_demande DECIMAL(15,2),
    superficie_demandee DECIMAL(10,2),
    duree_traitement_jours INTEGER,
    nb_documents_fournis INTEGER,
    score_evaluation DECIMAL(5,2),
    
    -- Dates importantes
    date_demande DATE,
    date_traitement DATE,
    date_decision DATE,
    date_attribution DATE,
    
    -- Métadonnées
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Fait Occupation des Lots
CREATE TABLE dwh.fait_occupation_lots (
    occupation_key SERIAL PRIMARY KEY,
    temps_key INTEGER REFERENCES dwh.dim_temps(temps_key),
    lot_key INTEGER REFERENCES dwh.dim_lots(lot_key),
    entreprise_key INTEGER REFERENCES dwh.dim_entreprises(entreprise_key),
    
    -- Métriques d'occupation
    taux_occupation_pct DECIMAL(5,2),
    superficie_occupee DECIMAL(10,2),
    superficie_disponible DECIMAL(10,2),
    valeur_occupation DECIMAL(15,2),
    nb_emplois_crees INTEGER,
    investissement_realise DECIMAL(15,2),
    
    -- Dates
    date_debut_occupation DATE,
    date_fin_prevue DATE,
    
    -- Métadonnées
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Fait Factures et Paiements
CREATE TABLE dwh.fait_factures_paiements (
    facture_key SERIAL PRIMARY KEY,
    temps_key INTEGER REFERENCES dwh.dim_temps(temps_key),
    lot_key INTEGER REFERENCES dwh.dim_lots(lot_key),
    entreprise_key INTEGER REFERENCES dwh.dim_entreprises(entreprise_key),
    
    -- Métriques financières
    montant_facture DECIMAL(15,2),
    montant_paye DECIMAL(15,2),
    montant_restant DECIMAL(15,2),
    taux_paiement_pct DECIMAL(5,2),
    nb_jours_retard INTEGER DEFAULT 0,
    
    -- Types et statuts
    type_facture VARCHAR(50),
    statut_paiement VARCHAR(50),
    mode_paiement VARCHAR(50),
    
    -- Dates importantes
    date_facture DATE,
    date_echeance DATE,
    date_paiement DATE,
    
    -- Métadonnées
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 4. VUES INDICATEURS
-- ===================

-- Vue: Évolution des demandes par statut
CREATE OR REPLACE VIEW dwh.v_evolution_demandes AS
SELECT 
    dt.annee,
    dt.mois,
    ds.nom_statut,
    COUNT(*) as nb_demandes,
    AVG(fda.duree_traitement_jours) as duree_moyenne_jours,
    SUM(fda.montant_demande) as montant_total
FROM dwh.fait_demandes_attribution fda
JOIN dwh.dim_temps dt ON fda.temps_key = dt.temps_key
JOIN dwh.dim_statuts ds ON fda.statut_key = ds.statut_key
GROUP BY dt.annee, dt.mois, ds.nom_statut
ORDER BY dt.annee, dt.mois, ds.nom_statut;

-- Vue: Taux d'occupation des lots
CREATE OR REPLACE VIEW dwh.v_taux_occupation_lots AS
SELECT 
    dzi.nom_zone,
    dl.numero_lot,
    AVG(fol.taux_occupation_pct) as taux_occupation_moyen,
    SUM(fol.nb_emplois_crees) as emplois_total,
    SUM(fol.investissement_realise) as investissement_total,
    MAX(dt.date_complete) as derniere_maj
FROM dwh.fait_occupation_lots fol
JOIN dwh.dim_lots dl ON fol.lot_key = dl.lot_key
JOIN dwh.dim_zones_industrielles dzi ON dl.zone_key = dzi.zone_key
JOIN dwh.dim_temps dt ON fol.temps_key = dt.temps_key
GROUP BY dzi.nom_zone, dl.numero_lot
ORDER BY taux_occupation_moyen DESC;

-- Vue: Demandes par statut (synthèse)
CREATE OR REPLACE VIEW dwh.v_demandes_par_statut AS
SELECT 
    ds.nom_statut,
    COUNT(*) as nb_demandes,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as pourcentage,
    AVG(fda.duree_traitement_jours) as duree_moyenne,
    SUM(fda.montant_demande) as montant_total
FROM dwh.fait_demandes_attribution fda
JOIN dwh.dim_statuts ds ON fda.statut_key = ds.statut_key
GROUP BY ds.nom_statut, ds.ordre_affichage
ORDER BY ds.ordre_affichage;

-- 5. TABLES DE MONITORING
-- =======================

CREATE TABLE monitoring.dwh_status (
    id SERIAL PRIMARY KEY,
    nom_table VARCHAR(100),
    nb_lignes INTEGER,
    derniere_maj TIMESTAMP,
    statut VARCHAR(20),
    message TEXT,
    date_controle TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE monitoring.etl_logs (
    id SERIAL PRIMARY KEY,
    nom_processus VARCHAR(100),
    date_debut TIMESTAMP,
    date_fin TIMESTAMP,
    statut VARCHAR(20),
    nb_lignes_traitees INTEGER,
    nb_erreurs INTEGER,
    message_erreur TEXT,
    duree_secondes INTEGER
);

-- 6. TABLES CDC
-- =============

CREATE TABLE cdc.cdc_config (
    id SERIAL PRIMARY KEY,
    table_source VARCHAR(100),
    table_cible VARCHAR(100),
    derniere_sync TIMESTAMP,
    mode_sync VARCHAR(20) DEFAULT 'INCREMENTAL',
    est_actif BOOLEAN DEFAULT TRUE,
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE cdc.cdc_logs (
    id SERIAL PRIMARY KEY,
    config_id INTEGER REFERENCES cdc.cdc_config(id),
    date_sync TIMESTAMP,
    nb_lignes_sync INTEGER,
    statut VARCHAR(20),
    message TEXT
);

CREATE TABLE cdc.cdc_sync_status (
    id SERIAL PRIMARY KEY,
    table_name VARCHAR(100),
    last_sync_time TIMESTAMP,
    sync_status VARCHAR(20),
    error_message TEXT,
    rows_processed INTEGER DEFAULT 0,
    date_created TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Vue CDC de monitoring
CREATE OR REPLACE VIEW cdc.v_sync_monitoring AS
SELECT 
    cc.table_source,
    cc.table_cible,
    cc.derniere_sync,
    cc.mode_sync,
    cc.est_actif,
    COALESCE(cl.nb_lignes_sync, 0) as dernier_nb_lignes,
    cl.statut as dernier_statut,
    cl.date_sync as derniere_execution
FROM cdc.cdc_config cc
LEFT JOIN cdc.cdc_logs cl ON cc.id = cl.config_id
AND cl.date_sync = (
    SELECT MAX(date_sync) 
    FROM cdc.cdc_logs 
    WHERE config_id = cc.id
);

-- Message de fin
SELECT 'MIGRATION DWH SIGETI TERMINEE AVEC SUCCES' as status;