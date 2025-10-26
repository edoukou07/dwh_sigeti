-- ==================================================================
-- SCRIPT DE MIGRATION DES DONNÉES RÉELLES
-- Base source: sigeti_node_db -> Base cible: sigeti_dwh
-- ==================================================================

-- Activation extension dblink
CREATE EXTENSION IF NOT EXISTS dblink;

-- 1. MIGRATION DIMENSION ZONES INDUSTRIELLES
-- ------------------------------------------------------------------
INSERT INTO dwh.dim_zones_industrielles (
    zone_id, nom_zone, localisation, superficie_totale, nb_lots_total, 
    statut_zone, date_creation, date_modification
)
SELECT 
    z.id,
    COALESCE(z.libelle, 'Zone sans nom'),
    COALESCE(z.adresse, 'Non spécifiée'),
    COALESCE(z.superficie, 0),
    COALESCE(z.lots_disponibles, 0),
    COALESCE(z.statut::text, 'actif'),
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
FROM dblink(
    'host=localhost port=5432 dbname=sigeti_node_db user=postgres password=postgres',
    'SELECT id, libelle, adresse, superficie, lots_disponibles, statut FROM zones_industrielles ORDER BY id'
) AS z(id integer, libelle text, adresse text, superficie double precision, lots_disponibles integer, statut text)
ON CONFLICT (zone_id) DO UPDATE SET
    nom_zone = EXCLUDED.nom_zone,
    localisation = EXCLUDED.localisation,
    superficie_totale = EXCLUDED.superficie_totale,
    nb_lots_total = EXCLUDED.nb_lots_total,
    statut_zone = EXCLUDED.statut_zone,
    date_modification = CURRENT_TIMESTAMP;

-- 2. MIGRATION DIMENSION ENTREPRISES  
-- ------------------------------------------------------------------
INSERT INTO dwh.dim_entreprises (
    entreprise_id, nom_entreprise, forme_juridique, secteur_activite, date_creation, date_modification
)
SELECT 
    e.id,
    COALESCE(e.raison_sociale, 'Entreprise sans nom'),
    COALESCE(e.forme_juridique, 'Non spécifiée'),
    'Non spécifié',
    COALESCE(e.date_creation::date, CURRENT_DATE),
    CURRENT_TIMESTAMP
FROM dblink(
    'host=localhost port=5432 dbname=sigeti_node_db user=postgres password=postgres',
    'SELECT id, raison_sociale, forme_juridique, date_creation FROM entreprises ORDER BY id'
) AS e(id integer, raison_sociale text, forme_juridique text, date_creation timestamp)
ON CONFLICT (entreprise_id) DO UPDATE SET
    nom_entreprise = EXCLUDED.nom_entreprise,
    forme_juridique = EXCLUDED.forme_juridique,
    date_modification = CURRENT_TIMESTAMP;

-- 3. AJOUT DE DONNÉES DE BASE DANS LES TABLES STATUTS ET TEMPS
-- ------------------------------------------------------------------
INSERT INTO dwh.dim_statuts (nom_statut, description_statut, couleur_statut) 
VALUES 
    ('EN_ATTENTE', 'Demande en attente de traitement', '#FFA500'),
    ('APPROUVEE', 'Demande approuvée', '#00FF00'), 
    ('REJETEE', 'Demande rejetée', '#FF0000'),
    ('EN_COURS', 'Demande en cours de traitement', '#0000FF')
ON CONFLICT (nom_statut) DO NOTHING;

INSERT INTO dwh.dim_temps (date_complete, annee, mois, jour, trimestre, nom_mois, nom_jour_semaine, numero_semaine)
SELECT 
    CURRENT_DATE,
    EXTRACT(YEAR FROM CURRENT_DATE),
    EXTRACT(MONTH FROM CURRENT_DATE), 
    EXTRACT(DAY FROM CURRENT_DATE),
    EXTRACT(QUARTER FROM CURRENT_DATE),
    TO_CHAR(CURRENT_DATE, 'Month'),
    TO_CHAR(CURRENT_DATE, 'Day'),
    EXTRACT(WEEK FROM CURRENT_DATE)
WHERE NOT EXISTS (SELECT 1 FROM dwh.dim_temps WHERE date_complete = CURRENT_DATE);

-- ==================================================================
-- RÉSULTAT DE LA MIGRATION
-- ==================================================================
SELECT 'MIGRATION TERMINEE' as status;