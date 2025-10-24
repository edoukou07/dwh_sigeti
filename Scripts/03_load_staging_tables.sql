-- Script pour charger les données depuis la base source vers le staging
BEGIN;

-- Configuration du search_path
SET search_path = staging, dwh, public;

-- Nettoyage du staging
TRUNCATE TABLE staging.stg_zones_industrielles CASCADE;
TRUNCATE TABLE staging.stg_lots CASCADE;
TRUNCATE TABLE staging.stg_entreprises CASCADE;
TRUNCATE TABLE staging.stg_demandes_attribution CASCADE;

-- Zones Industrielles
INSERT INTO staging.stg_zones_industrielles (
    id, code, libelle, description, superficie, 
    adresse, statut, lots_disponibles, created_at, updated_at
)
SELECT s.*
FROM dblink('host=localhost port=5432 dbname=sigeti_node_db user=postgres password=postgres',
    'SELECT id, code, libelle, description, superficie, 
            adresse, statut::text, lots_disponibles, created_at, updated_at
     FROM zones_industrielles')
AS s(id INTEGER, code VARCHAR, libelle VARCHAR, description TEXT, 
     superficie DOUBLE PRECISION, adresse TEXT, statut VARCHAR, 
     lots_disponibles INTEGER, created_at TIMESTAMPTZ, 
     updated_at TIMESTAMPTZ);

-- Lots
INSERT INTO staging.stg_lots (
    id, numero, ilot, superficie, unite_mesure, prix,
    statut, priorite, viabilite, description, coordonnees,
    zone_industrielle_id, entreprise_id, date_acquisition,
    date_reservation, delai_option, polygon, location,
    created_at, updated_at, operateur_id
)
SELECT s.*
FROM dblink('host=localhost port=5432 dbname=sigeti_node_db user=postgres password=postgres',
    'SELECT id, numero, ilot, superficie, unite_mesure, prix,
            statut::text, priorite, viabilite, description, coordonnees,
            zone_industrielle_id, entreprise_id, date_acquisition,
            date_reservation, delai_option, polygon, location,
            created_at, updated_at, operateur_id
     FROM lots')
AS s(id INTEGER, numero VARCHAR, ilot VARCHAR, superficie DOUBLE PRECISION,
     unite_mesure VARCHAR, prix NUMERIC, statut VARCHAR, priorite VARCHAR,
     viabilite BOOLEAN, description TEXT, coordonnees VARCHAR,
     zone_industrielle_id INTEGER, entreprise_id INTEGER, date_acquisition DATE,
     date_reservation TIMESTAMPTZ, delai_option INTEGER, polygon TEXT,
     location TEXT, created_at TIMESTAMPTZ, updated_at TIMESTAMPTZ,
     operateur_id INTEGER);

-- Entreprises
INSERT INTO staging.stg_entreprises (
    id, raison_sociale, telephone, email, registre_commerce,
    compte_contribuable, forme_juridique, adresse, date_constitution,
    domaine_activite_id, date_creation, date_modification, entreprise_id
)
SELECT s.*
FROM dblink('host=localhost port=5432 dbname=sigeti_node_db user=postgres password=postgres',
    'SELECT id, raison_sociale, telephone, email, registre_commerce,
            compte_contribuable, forme_juridique, adresse, date_constitution,
            domaine_activite_id, date_creation, date_modification, entreprise_id
     FROM entreprises')
AS s(id INTEGER, raison_sociale VARCHAR, telephone VARCHAR, email VARCHAR,
     registre_commerce VARCHAR, compte_contribuable VARCHAR, forme_juridique VARCHAR,
     adresse TEXT, date_constitution DATE, domaine_activite_id INTEGER,
     date_creation TIMESTAMPTZ, date_modification TIMESTAMPTZ, entreprise_id INTEGER);

-- Demandes d'Attribution
INSERT INTO staging.stg_demandes_attribution (
    id, reference, statut, etape_courante, type_demande,
    operateur_id, entreprise_id, lot_id, zone_id,
    informations_terrain, coordonnees_geospatiales,
    financement, emplois, priorite, decisions_commissions,
    historique_etapes, retours, metadata,
    created_at, updated_at
)
SELECT s.*
FROM dblink('host=localhost port=5432 dbname=sigeti_node_db user=postgres password=postgres',
    'SELECT id, reference, statut::text, etape_courante, type_demande::text,
            operateur_id, entreprise_id, lot_id, zone_id,
            informations_terrain, coordonnees_geospatiales,
            financement, emplois, priorite, decisions_commissions,
            historique_etapes, retours, metadata,
            created_at, updated_at
     FROM demandes_attribution')
AS s(id INTEGER, reference VARCHAR, statut VARCHAR, etape_courante INTEGER,
     type_demande VARCHAR, operateur_id INTEGER, entreprise_id INTEGER,
     lot_id INTEGER, zone_id INTEGER, informations_terrain JSONB,
     coordonnees_geospatiales JSONB, financement JSONB, emplois JSONB,
     priorite VARCHAR, decisions_commissions JSONB, historique_etapes JSONB,
     retours JSONB, metadata JSONB, created_at TIMESTAMPTZ, updated_at TIMESTAMPTZ);

COMMIT;