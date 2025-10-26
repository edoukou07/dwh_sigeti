-- =============================================================================
-- DWH SIGETI - DÉPLOIEMENT COMPLET CONSOLIDÉ
-- =============================================================================
-- Ce script unique contient toute la logique SQL nécessaire :
-- 1. Structure complète du DWH
-- 2. Migration des données réelles 
-- 3. Création des 18 vues d'indicateurs BI
-- =============================================================================

-- =====================================================================
-- PARTIE 1: STRUCTURE COMPLÈTE DU DWH
-- =====================================================================

-- 1. Création des schémas
CREATE SCHEMA IF NOT EXISTS dwh;
CREATE SCHEMA IF NOT EXISTS cdc;
CREATE SCHEMA IF NOT EXISTS staging;
CREATE SCHEMA IF NOT EXISTS etl;
CREATE SCHEMA IF NOT EXISTS monitoring;

-- 2. TABLES DE DIMENSIONS
-- =====================

-- Dimension Temps
CREATE TABLE IF NOT EXISTS dwh.dim_temps (
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

-- Dimension Zones Industrielles
CREATE TABLE IF NOT EXISTS dwh.dim_zones_industrielles (
    zone_key SERIAL PRIMARY KEY,
    zone_id INTEGER UNIQUE,
    nom_zone VARCHAR(255),
    localisation VARCHAR(255),
    superficie_totale NUMERIC(10,2),
    nb_lots_total INTEGER,
    statut_zone VARCHAR(50),
    date_creation_zone DATE,
    description_zone TEXT,
    coordonnees_gps VARCHAR(100),
    gestionnaire VARCHAR(100),
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Dimension Lots
CREATE TABLE IF NOT EXISTS dwh.dim_lots (
    lot_key SERIAL PRIMARY KEY,
    lot_id INTEGER UNIQUE,
    zone_key INTEGER REFERENCES dwh.dim_zones_industrielles(zone_key),
    numero_lot VARCHAR(50),
    superficie NUMERIC(10,2),
    prix_m2 NUMERIC(10,2),
    statut_lot VARCHAR(50),
    type_lot VARCHAR(50),
    coordonnees_gps VARCHAR(100),
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Dimension Entreprises
CREATE TABLE IF NOT EXISTS dwh.dim_entreprises (
    entreprise_key SERIAL PRIMARY KEY,
    entreprise_id INTEGER UNIQUE,
    nom_entreprise VARCHAR(255),
    secteur_activite VARCHAR(100),
    taille_entreprise VARCHAR(50),
    chiffre_affaires NUMERIC(15,2),
    nombre_employes INTEGER,
    adresse_siege TEXT,
    telephone VARCHAR(20),
    email VARCHAR(200),
    site_web VARCHAR(200),
    numero_registre_commerce VARCHAR(50),
    date_creation_entreprise DATE,
    statut_entreprise VARCHAR(50),
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Dimension Statuts
CREATE TABLE IF NOT EXISTS dwh.dim_statuts (
    statut_key SERIAL PRIMARY KEY,
    nom_statut VARCHAR(50) UNIQUE,
    description_statut TEXT,
    couleur_affichage VARCHAR(7),
    ordre_affichage INTEGER,
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Dimension Opérateurs
CREATE TABLE IF NOT EXISTS dwh.dim_operateurs (
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
-- =================

-- Fait Demandes Attribution
CREATE TABLE IF NOT EXISTS dwh.fait_demandes_attribution (
    demande_key SERIAL PRIMARY KEY,
    temps_key INTEGER REFERENCES dwh.dim_temps(temps_key),
    lot_key INTEGER REFERENCES dwh.dim_lots(lot_key),
    entreprise_key INTEGER REFERENCES dwh.dim_entreprises(entreprise_key),
    statut_key INTEGER REFERENCES dwh.dim_statuts(statut_key),
    operateur_key INTEGER REFERENCES dwh.dim_operateurs(operateur_key),
    montant_demande NUMERIC(15,2),
    superficie_demandee NUMERIC(10,2),
    duree_traitement_jours INTEGER,
    nb_documents_fournis INTEGER,
    score_evaluation NUMERIC(5,2),
    date_demande DATE,
    date_traitement DATE,
    date_decision DATE,
    date_attribution DATE,
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Fait Factures et Paiements
CREATE TABLE IF NOT EXISTS dwh.fait_factures_paiements (
    facture_key SERIAL PRIMARY KEY,
    temps_key INTEGER REFERENCES dwh.dim_temps(temps_key),
    lot_key INTEGER REFERENCES dwh.dim_lots(lot_key),
    entreprise_key INTEGER REFERENCES dwh.dim_entreprises(entreprise_key),
    montant_facture NUMERIC(15,2),
    montant_paye NUMERIC(15,2),
    date_facture DATE,
    date_paiement DATE,
    methode_paiement VARCHAR(50),
    statut_paiement VARCHAR(50),
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Fait Occupation Lots
CREATE TABLE IF NOT EXISTS dwh.fait_occupation_lots (
    occupation_key SERIAL PRIMARY KEY,
    temps_key INTEGER REFERENCES dwh.dim_temps(temps_key),
    lot_key INTEGER REFERENCES dwh.dim_lots(lot_key),
    entreprise_key INTEGER REFERENCES dwh.dim_entreprises(entreprise_key),
    date_debut_occupation DATE,
    date_fin_occupation DATE,
    taux_occupation NUMERIC(5,2),
    usage_reel VARCHAR(100),
    superficie_utilisee NUMERIC(10,2),
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 4. TABLES DE MONITORING ET ETL
-- ==============================

-- Table de monitoring du DWH
CREATE TABLE IF NOT EXISTS monitoring.dwh_status (
    id SERIAL PRIMARY KEY,
    nom_table VARCHAR(100),
    derniere_maj TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    nb_lignes INTEGER DEFAULT 0,
    statut VARCHAR(50) DEFAULT 'ACTIF',
    commentaires TEXT
);

-- Table de logs ETL
CREATE TABLE IF NOT EXISTS etl.logs_etl (
    id SERIAL PRIMARY KEY,
    process_name VARCHAR(100),
    start_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    end_time TIMESTAMP,
    status VARCHAR(50),
    rows_processed INTEGER DEFAULT 0,
    error_message TEXT
);

-- 5. INSERTION DES DONNÉES DE RÉFÉRENCE
-- ====================================

-- Statuts par défaut
INSERT INTO dwh.dim_statuts (nom_statut, description_statut, couleur_affichage, ordre_affichage) 
VALUES 
    ('EN_ATTENTE', 'Demande en attente de traitement', '#FFA500', 1),
    ('EN_COURS', 'Demande en cours de traitement', '#0066CC', 2),
    ('APPROUVEE', 'Demande approuvée', '#00AA00', 3),
    ('REJETEE', 'Demande rejetée', '#CC0000', 4),
    ('SUSPENDUE', 'Demande suspendue', '#800080', 5)
ON CONFLICT (nom_statut) DO NOTHING;

-- Génération de données de temps pour l'année courante et les 2 prochaines
INSERT INTO dwh.dim_temps (date_complete, annee, mois, jour, trimestre, nom_mois, nom_jour_semaine, numero_semaine, est_week_end, est_jour_ferie)
SELECT 
    d as date_complete,
    EXTRACT(YEAR FROM d) as annee,
    EXTRACT(MONTH FROM d) as mois,
    EXTRACT(DAY FROM d) as jour,
    EXTRACT(QUARTER FROM d) as trimestre,
    CASE EXTRACT(MONTH FROM d)
        WHEN 1 THEN 'Janvier' WHEN 2 THEN 'Février' WHEN 3 THEN 'Mars'
        WHEN 4 THEN 'Avril' WHEN 5 THEN 'Mai' WHEN 6 THEN 'Juin'
        WHEN 7 THEN 'Juillet' WHEN 8 THEN 'Août' WHEN 9 THEN 'Septembre'
        WHEN 10 THEN 'Octobre' WHEN 11 THEN 'Novembre' WHEN 12 THEN 'Décembre'
    END as nom_mois,
    CASE EXTRACT(DOW FROM d)
        WHEN 0 THEN 'Dimanche' WHEN 1 THEN 'Lundi' WHEN 2 THEN 'Mardi'
        WHEN 3 THEN 'Mercredi' WHEN 4 THEN 'Jeudi' WHEN 5 THEN 'Vendredi'
        WHEN 6 THEN 'Samedi'
    END as nom_jour_semaine,
    EXTRACT(WEEK FROM d) as numero_semaine,
    CASE WHEN EXTRACT(DOW FROM d) IN (0, 6) THEN TRUE ELSE FALSE END as est_week_end,
    FALSE as est_jour_ferie
FROM generate_series(
    DATE_TRUNC('year', CURRENT_DATE),
    DATE_TRUNC('year', CURRENT_DATE) + INTERVAL '3 years' - INTERVAL '1 day',
    '1 day'::interval
) as d
ON CONFLICT (date_complete) DO NOTHING;

-- =====================================================================
-- PARTIE 2: MIGRATION DES DONNÉES RÉELLES DEPUIS LA SOURCE
-- =====================================================================

-- Activation de dblink si pas déjà fait
CREATE EXTENSION IF NOT EXISTS dblink;

-- Migration Zones Industrielles depuis sigeti_node_db
INSERT INTO dwh.dim_zones_industrielles (
    zone_id, nom_zone, localisation, superficie_totale, nb_lots_total, 
    statut_zone, date_creation_zone, description_zone
)
SELECT DISTINCT * FROM dblink(
    'host=localhost port=5432 dbname=sigeti_node_db user=postgres password=postgres',
    'SELECT 
        id as zone_id,
        COALESCE(libelle, code) as nom_zone,
        COALESCE(adresse, ''Non spécifié'') as localisation,
        COALESCE(superficie, 0) as superficie_totale,
        COALESCE(lots_disponibles, 0) as nb_lots_total,
        COALESCE(statut::text, ''actif'') as statut_zone,
        COALESCE(created_at::date, CURRENT_DATE) as date_creation_zone,
        COALESCE(description, '''') as description_zone
    FROM zones_industrielles 
    WHERE id IS NOT NULL'
) AS source(
    zone_id INTEGER,
    nom_zone VARCHAR(255),
    localisation VARCHAR(255),
    superficie_totale NUMERIC(10,2),
    nb_lots_total INTEGER,
    statut_zone VARCHAR(50),
    date_creation_zone DATE,
    description_zone TEXT
)
ON CONFLICT (zone_id) DO UPDATE SET
    nom_zone = EXCLUDED.nom_zone,
    localisation = EXCLUDED.localisation,
    superficie_totale = EXCLUDED.superficie_totale,
    nb_lots_total = EXCLUDED.nb_lots_total,
    statut_zone = EXCLUDED.statut_zone,
    date_modification = CURRENT_TIMESTAMP;

-- Migration Entreprises depuis sigeti_node_db
INSERT INTO dwh.dim_entreprises (
    entreprise_id, nom_entreprise, secteur_activite, taille_entreprise,
    chiffre_affaires, nombre_employes, adresse_siege, telephone, email,
    numero_registre_commerce, date_creation_entreprise, statut_entreprise
)
SELECT DISTINCT * FROM dblink(
    'host=localhost port=5432 dbname=sigeti_node_db user=postgres password=postgres',
    'SELECT 
        id as entreprise_id,
        COALESCE(raison_sociale, ''Non spécifié'') as nom_entreprise,
        ''Non spécifié'' as secteur_activite,
        ''Non spécifié'' as taille_entreprise,
        0 as chiffre_affaires,
        0 as nombre_employes,
        COALESCE(adresse, ''Non spécifié'') as adresse_siege,
        telephone,
        email,
        COALESCE(registre_commerce, '''') as numero_registre_commerce,
        COALESCE(date_constitution, CURRENT_DATE) as date_creation,
        ''actif'' as statut_entreprise
    FROM entreprises 
    WHERE id IS NOT NULL'
) AS source(
    entreprise_id INTEGER,
    nom_entreprise VARCHAR(255),
    secteur_activite VARCHAR(100),
    taille_entreprise VARCHAR(50),
    chiffre_affaires NUMERIC(15,2),
    nombre_employes INTEGER,
    adresse_siege TEXT,
    telephone VARCHAR(20),
    email VARCHAR(200),
    numero_registre_commerce VARCHAR(50),
    date_creation_entreprise DATE,
    statut_entreprise VARCHAR(50)
)
ON CONFLICT (entreprise_id) DO UPDATE SET
    nom_entreprise = EXCLUDED.nom_entreprise,
    secteur_activite = EXCLUDED.secteur_activite,
    taille_entreprise = EXCLUDED.taille_entreprise,
    chiffre_affaires = EXCLUDED.chiffre_affaires,
    nombre_employes = EXCLUDED.nombre_employes,
    adresse_siege = EXCLUDED.adresse_siege,
    telephone = EXCLUDED.telephone,
    email = EXCLUDED.email,
    statut_entreprise = EXCLUDED.statut_entreprise,
    date_modification = CURRENT_TIMESTAMP;

-- =====================================================================
-- PARTIE 3: CRÉATION DES 18 VUES D'INDICATEURS BI
-- =====================================================================

-- Suppression des vues existantes si elles existent
DROP VIEW IF EXISTS dwh.v_demandes_par_statut CASCADE;
DROP VIEW IF EXISTS dwh.v_demandes_par_zone CASCADE;
DROP VIEW IF EXISTS dwh.v_demandes_par_entreprise CASCADE;
DROP VIEW IF EXISTS dwh.v_delais_traitement_demandes CASCADE;
DROP VIEW IF EXISTS dwh.v_taux_acceptation_demandes CASCADE;
DROP VIEW IF EXISTS dwh.v_evolution_demandes CASCADE;
DROP VIEW IF EXISTS dwh.v_taux_occupation_lots CASCADE;
DROP VIEW IF EXISTS dwh.v_superficie_par_zone CASCADE;
DROP VIEW IF EXISTS dwh.v_prix_lots_par_zone CASCADE;
DROP VIEW IF EXISTS dwh.v_revenus_par_periode CASCADE;
DROP VIEW IF EXISTS dwh.v_revenus_par_entreprise CASCADE;
DROP VIEW IF EXISTS dwh.v_entreprises_par_secteur CASCADE;
DROP VIEW IF EXISTS dwh.v_evolution_entreprises CASCADE;
DROP VIEW IF EXISTS dwh.v_operateurs_par_fonction CASCADE;
DROP VIEW IF EXISTS dwh.v_synthese_geographique CASCADE;
DROP VIEW IF EXISTS dwh.v_tendances_mensuelles CASCADE;
DROP VIEW IF EXISTS dwh.v_dashboard_principal CASCADE;
DROP VIEW IF EXISTS dwh.v_monitoring_systeme CASCADE;

-- A. INDICATEURS DE GESTION DES DEMANDES ET ATTRIBUTIONS

-- A.1 Nombre de demandes d'attribution par statut
CREATE VIEW dwh.v_demandes_par_statut AS
SELECT 
    ds.nom_statut,
    COUNT(*) as nb_demandes,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as pourcentage
FROM dwh.fait_demandes_attribution fda
JOIN dwh.dim_statuts ds ON fda.statut_key = ds.statut_key
GROUP BY ds.nom_statut, ds.statut_key
ORDER BY nb_demandes DESC;

-- A.2 Nombre de demandes par zone industrielle
CREATE VIEW dwh.v_demandes_par_zone AS
SELECT 
    dzi.nom_zone,
    dzi.zone_id,
    COUNT(*) as nb_demandes,
    SUM(fda.montant_demande) as montant_total_demandes
FROM dwh.fait_demandes_attribution fda
JOIN dwh.dim_lots dl ON fda.lot_key = dl.lot_key
JOIN dwh.dim_zones_industrielles dzi ON dl.zone_key = dzi.zone_key
GROUP BY dzi.zone_id, dzi.nom_zone
ORDER BY nb_demandes DESC;

-- A.3 Nombre de demandes par entreprise
CREATE VIEW dwh.v_demandes_par_entreprise AS
SELECT 
    de.nom_entreprise,
    de.entreprise_id,
    de.secteur_activite,
    COUNT(*) as nb_demandes,
    SUM(fda.montant_demande) as montant_total_demandes,
    AVG(fda.montant_demande) as montant_moyen_demande
FROM dwh.fait_demandes_attribution fda
JOIN dwh.dim_entreprises de ON fda.entreprise_key = de.entreprise_key
GROUP BY de.entreprise_id, de.nom_entreprise, de.secteur_activite
ORDER BY nb_demandes DESC;

-- A.4 Délai moyen de traitement des demandes
CREATE VIEW dwh.v_delais_traitement_demandes AS
SELECT 
    ds.nom_statut,
    COUNT(*) as nb_demandes,
    AVG(fda.duree_traitement_jours) as delai_moyen_jours,
    MIN(fda.duree_traitement_jours) as delai_min_jours,
    MAX(fda.duree_traitement_jours) as delai_max_jours
FROM dwh.fait_demandes_attribution fda
JOIN dwh.dim_statuts ds ON fda.statut_key = ds.statut_key
WHERE fda.date_traitement IS NOT NULL
GROUP BY ds.nom_statut, ds.statut_key
ORDER BY delai_moyen_jours;

-- A.5 Taux d'acceptation des demandes
CREATE VIEW dwh.v_taux_acceptation_demandes AS
SELECT 
    COUNT(*) as total_demandes,
    COUNT(CASE WHEN ds.nom_statut = 'APPROUVEE' THEN 1 END) as demandes_approuvees,
    COUNT(CASE WHEN ds.nom_statut = 'REJETEE' THEN 1 END) as demandes_rejetees,
    ROUND(COUNT(CASE WHEN ds.nom_statut = 'APPROUVEE' THEN 1 END) * 100.0 / COUNT(*), 2) as taux_acceptation_pct,
    ROUND(COUNT(CASE WHEN ds.nom_statut = 'REJETEE' THEN 1 END) * 100.0 / COUNT(*), 2) as taux_rejet_pct
FROM dwh.fait_demandes_attribution fda
JOIN dwh.dim_statuts ds ON fda.statut_key = ds.statut_key;

-- A.6 Évolution des demandes par période
CREATE VIEW dwh.v_evolution_demandes AS
SELECT 
    dt.annee,
    dt.mois,
    dt.nom_mois,
    COUNT(*) as nb_demandes,
    SUM(fda.montant_demande) as montant_total,
    AVG(fda.montant_demande) as montant_moyen
FROM dwh.fait_demandes_attribution fda
JOIN dwh.dim_temps dt ON fda.temps_key = dt.temps_key
GROUP BY dt.annee, dt.mois, dt.nom_mois
ORDER BY dt.annee DESC, dt.mois DESC;

-- B. INDICATEURS FONCIERS ET OCCUPATION

-- B.1 Taux d'occupation des lots
CREATE VIEW dwh.v_taux_occupation_lots AS
SELECT 
    dzi.nom_zone,
    dzi.zone_id,
    COUNT(*) as total_lots,
    COUNT(CASE WHEN dl.statut_lot = 'OCCUPE' THEN 1 END) as lots_occupes,
    COUNT(CASE WHEN dl.statut_lot = 'DISPONIBLE' THEN 1 END) as lots_disponibles,
    ROUND(COUNT(CASE WHEN dl.statut_lot = 'OCCUPE' THEN 1 END) * 100.0 / COUNT(*), 2) as taux_occupation_pct
FROM dwh.dim_lots dl
JOIN dwh.dim_zones_industrielles dzi ON dl.zone_key = dzi.zone_key
GROUP BY dzi.zone_id, dzi.nom_zone
ORDER BY taux_occupation_pct DESC;

-- B.2 Superficie par zone et statut
CREATE VIEW dwh.v_superficie_par_zone AS
SELECT 
    dzi.nom_zone,
    dzi.zone_id,
    dzi.superficie_totale as superficie_zone,
    SUM(dl.superficie) as superficie_lots_total,
    SUM(CASE WHEN dl.statut_lot = 'OCCUPE' THEN dl.superficie ELSE 0 END) as superficie_occupee,
    SUM(CASE WHEN dl.statut_lot = 'DISPONIBLE' THEN dl.superficie ELSE 0 END) as superficie_disponible,
    ROUND(SUM(CASE WHEN dl.statut_lot = 'OCCUPE' THEN dl.superficie ELSE 0 END) * 100.0 / 
          NULLIF(SUM(dl.superficie), 0), 2) as taux_occupation_superficie_pct
FROM dwh.dim_zones_industrielles dzi
LEFT JOIN dwh.dim_lots dl ON dzi.zone_key = dl.zone_key
GROUP BY dzi.zone_id, dzi.nom_zone, dzi.superficie_totale
ORDER BY dzi.nom_zone;

-- B.3 Prix moyen des lots par zone
CREATE VIEW dwh.v_prix_lots_par_zone AS
SELECT 
    dzi.nom_zone,
    dzi.zone_id,
    COUNT(dl.lot_id) as nb_lots,
    AVG(dl.prix_m2) as prix_moyen_m2,
    MIN(dl.prix_m2) as prix_min_m2,
    MAX(dl.prix_m2) as prix_max_m2,
    SUM(dl.prix_m2 * dl.superficie) as valeur_totale_zone
FROM dwh.dim_lots dl
JOIN dwh.dim_zones_industrielles dzi ON dl.zone_key = dzi.zone_key
WHERE dl.prix_m2 > 0
GROUP BY dzi.zone_id, dzi.nom_zone
ORDER BY prix_moyen_m2 DESC;

-- C. INDICATEURS FINANCIERS ET DE PAIEMENT

-- C.1 Revenus par période et zone
CREATE VIEW dwh.v_revenus_par_periode AS
SELECT 
    dt.annee,
    dt.mois,
    dt.nom_mois,
    dzi.nom_zone,
    COUNT(*) as nb_paiements,
    SUM(fda.montant_demande) as revenus_total,
    AVG(fda.montant_demande) as revenu_moyen
FROM dwh.fait_demandes_attribution fda
JOIN dwh.dim_temps dt ON fda.temps_key = dt.temps_key
JOIN dwh.dim_lots dl ON fda.lot_key = dl.lot_key
JOIN dwh.dim_zones_industrielles dzi ON dl.zone_key = dzi.zone_key
JOIN dwh.dim_statuts ds ON fda.statut_key = ds.statut_key
WHERE ds.nom_statut = 'APPROUVEE'
GROUP BY dt.annee, dt.mois, dt.nom_mois, dzi.nom_zone, dzi.zone_id
ORDER BY dt.annee DESC, dt.mois DESC, revenus_total DESC;

-- C.2 Revenus par entreprise
CREATE VIEW dwh.v_revenus_par_entreprise AS
SELECT 
    de.nom_entreprise,
    de.secteur_activite,
    COUNT(*) as nb_transactions,
    SUM(fda.montant_demande) as revenus_total,
    AVG(fda.montant_demande) as revenu_moyen_transaction
FROM dwh.fait_demandes_attribution fda
JOIN dwh.dim_entreprises de ON fda.entreprise_key = de.entreprise_key
JOIN dwh.dim_statuts ds ON fda.statut_key = ds.statut_key
WHERE ds.nom_statut = 'APPROUVEE'
GROUP BY de.entreprise_id, de.nom_entreprise, de.secteur_activite
ORDER BY revenus_total DESC;

-- D. INDICATEURS D'ENTREPRISES ET OPÉRATEURS

-- D.1 Entreprises actives par secteur
CREATE VIEW dwh.v_entreprises_par_secteur AS
SELECT 
    de.secteur_activite,
    COUNT(*) as nb_entreprises,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as pourcentage
FROM dwh.dim_entreprises de
GROUP BY de.secteur_activite
ORDER BY nb_entreprises DESC;

-- D.2 Évolution des entreprises par année de création
CREATE VIEW dwh.v_evolution_entreprises AS
SELECT 
    EXTRACT(YEAR FROM de.date_creation) as annee_creation,
    COUNT(*) as nb_entreprises_creees,
    de.secteur_activite,
    SUM(COUNT(*)) OVER (ORDER BY EXTRACT(YEAR FROM de.date_creation)) as cumul_entreprises
FROM dwh.dim_entreprises de
WHERE de.date_creation IS NOT NULL
GROUP BY EXTRACT(YEAR FROM de.date_creation), de.secteur_activite
ORDER BY annee_creation DESC;

-- D.3 Opérateurs par fonction
CREATE VIEW dwh.v_operateurs_par_fonction AS
SELECT 
    COUNT(DISTINCT opr.operateur_id) as total_operateurs,
    opr.fonction,
    COUNT(*) as nb_operateurs_fonction,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as pourcentage_fonction
FROM dwh.dim_operateurs opr
WHERE opr.est_actif = true
GROUP BY opr.fonction
ORDER BY nb_operateurs_fonction DESC;

-- E. INDICATEURS GÉOGRAPHIQUES ET SPATIAUX

-- E.1 Vue synthèse géographique des zones
CREATE VIEW dwh.v_synthese_geographique AS
SELECT 
    dzi.nom_zone,
    dzi.zone_id,
    dzi.superficie_totale,
    dzi.nb_lots_total,
    dzi.statut_zone,
    COUNT(dl.lot_id) as lots_references,
    COUNT(fda.demande_key) as nb_demandes,
    COALESCE(SUM(dl.superficie), 0) as superficie_lots_totale,
    ROUND(COALESCE(dzi.superficie_totale, 0) / NULLIF(dzi.nb_lots_total, 0), 2) as superficie_moyenne_lot
FROM dwh.dim_zones_industrielles dzi
LEFT JOIN dwh.dim_lots dl ON dzi.zone_key = dl.zone_key
LEFT JOIN dwh.fait_demandes_attribution fda ON dl.lot_key = fda.lot_key
GROUP BY dzi.zone_id, dzi.nom_zone, dzi.superficie_totale, dzi.nb_lots_total, dzi.statut_zone
ORDER BY dzi.superficie_totale DESC;

-- F. INDICATEURS TEMPORELS ET TENDANCES

-- F.1 Tendances mensuelles globales
CREATE VIEW dwh.v_tendances_mensuelles AS
SELECT 
    dt.annee,
    dt.mois,
    dt.nom_mois,
    COUNT(fda.demande_key) as nb_demandes_mois,
    SUM(fda.montant_demande) as montant_total_mois,
    AVG(fda.duree_traitement_jours) as delai_moyen_traitement,
    COUNT(CASE WHEN ds.nom_statut = 'APPROUVEE' THEN 1 END) as demandes_approuvees,
    LAG(COUNT(fda.demande_key)) OVER (ORDER BY dt.annee, dt.mois) as nb_demandes_mois_precedent,
    ROUND((COUNT(fda.demande_key) - LAG(COUNT(fda.demande_key)) OVER (ORDER BY dt.annee, dt.mois)) * 100.0 / 
          NULLIF(LAG(COUNT(fda.demande_key)) OVER (ORDER BY dt.annee, dt.mois), 0), 2) as evolution_pct
FROM dwh.fait_demandes_attribution fda
JOIN dwh.dim_temps dt ON fda.temps_key = dt.temps_key
JOIN dwh.dim_statuts ds ON fda.statut_key = ds.statut_key
GROUP BY dt.annee, dt.mois, dt.nom_mois
ORDER BY dt.annee DESC, dt.mois DESC;

-- G. VUE TABLEAU DE BORD PRINCIPAL

CREATE VIEW dwh.v_dashboard_principal AS
SELECT 
    'Zones industrielles' as indicateur,
    CAST(COUNT(DISTINCT dzi.zone_id) AS TEXT) as valeur,
    'zones' as unite
FROM dwh.dim_zones_industrielles dzi
WHERE dzi.statut_zone = 'actif'

UNION ALL

SELECT 
    'Entreprises enregistrées',
    CAST(COUNT(*) AS TEXT),
    'entreprises'
FROM dwh.dim_entreprises de

UNION ALL

SELECT 
    'Lots disponibles',
    CAST(COUNT(*) AS TEXT),
    'lots'
FROM dwh.dim_lots dl
WHERE dl.statut_lot = 'DISPONIBLE'

UNION ALL

SELECT 
    'Demandes en cours',
    CAST(COUNT(*) AS TEXT),
    'demandes'
FROM dwh.fait_demandes_attribution fda
JOIN dwh.dim_statuts ds ON fda.statut_key = ds.statut_key
WHERE ds.nom_statut = 'EN_ATTENTE'

UNION ALL

SELECT 
    'Taux occupation moyen',
    CAST(ROUND(AVG(CASE WHEN dl.statut_lot = 'OCCUPE' THEN 100.0 ELSE 0.0 END), 1) AS TEXT),
    '%'
FROM dwh.dim_lots dl

UNION ALL

SELECT 
    'Revenus totaux',
    COALESCE(CAST(SUM(fda.montant_demande) AS TEXT), '0'),
    'FCFA'
FROM dwh.fait_demandes_attribution fda
JOIN dwh.dim_statuts ds ON fda.statut_key = ds.statut_key
WHERE ds.nom_statut = 'APPROUVEE';

-- H. VUE MONITORING SYSTÈME

CREATE VIEW dwh.v_monitoring_systeme AS
SELECT 
    schemaname as schema_name,
    relname as table_name,
    n_tup_ins as insertions,
    n_tup_upd as modifications,
    n_tup_del as suppressions,
    n_tup_ins + n_tup_upd + n_tup_del as total_activite,
    last_vacuum,
    last_analyze
FROM pg_stat_user_tables
WHERE schemaname IN ('dwh', 'cdc', 'staging', 'etl', 'monitoring')
ORDER BY total_activite DESC;

-- =====================================================================
-- FINALISATION ET VÉRIFICATION
-- =====================================================================

-- Mise à jour du monitoring
INSERT INTO monitoring.dwh_status (nom_table, statut, commentaires)
VALUES 
    ('dwh.dim_zones_industrielles', 'ACTIF', 'Déploiement consolidé réussi'),
    ('dwh.dim_entreprises', 'ACTIF', 'Déploiement consolidé réussi'),
    ('dwh.dim_temps', 'ACTIF', 'Déploiement consolidé réussi')
ON CONFLICT (nom_table) DO UPDATE SET
    derniere_maj = CURRENT_TIMESTAMP,
    statut = EXCLUDED.statut,
    commentaires = EXCLUDED.commentaires;

-- Message de succès final
SELECT 'DÉPLOIEMENT CONSOLIDÉ DWH SIGETI TERMINÉ AVEC SUCCÈS' as status,
       COUNT(*) as nb_vues_creees 
FROM pg_views WHERE schemaname = 'dwh';