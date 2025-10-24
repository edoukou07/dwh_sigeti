-- Script pour charger les dimensions et les faits
BEGIN;

-- Configuration du search_path
SET search_path = dwh, staging, public;

-- 1. Dimension Zone Industrielle (Type 2)
INSERT INTO dwh.dim_zone_industrielle (
    zone_source_id,
    zone_code,
    zone_libelle,
    description,
    superficie,
    adresse,
    statut,
    lots_disponibles,
    date_debut_validite,
    date_fin_validite
)
SELECT 
    id as zone_source_id,
    code as zone_code,
    libelle as zone_libelle,
    description,
    superficie,
    adresse,
    statut,
    lots_disponibles,
    created_at as date_debut_validite,
    cast('9999-12-31 23:59:59' as timestamp with time zone) as date_fin_validite
FROM staging.stg_zones_industrielles;

-- 2. Dimension Lot (Type 2)
INSERT INTO dwh.dim_lot (
    lot_source_id,
    lot_code,
    lot_libelle,
    zone_id,
    superficie,
    statut,
    date_debut_validite,
    date_fin_validite
)
SELECT 
    l.id as lot_source_id,
    l.numero as lot_code,
    l.ilot as lot_libelle,
    z.zone_id,
    l.superficie,
    l.statut,
    l.created_at as date_debut_validite,
    cast('9999-12-31 23:59:59' as timestamp with time zone) as date_fin_validite
FROM staging.stg_lots l
JOIN dwh.dim_zone_industrielle z ON l.zone_industrielle_id = z.zone_source_id;

-- 3. Dimension Entreprise (Type 2)
INSERT INTO dwh.dim_entreprise (
    entreprise_source_id,
    raison_sociale,
    domaine_activite,
    telephone,
    email,
    adresse,
    date_debut_validite,
    date_fin_validite
)
SELECT 
    id as entreprise_source_id,
    raison_sociale,
    'INDÉFINI' as domaine_activite, -- À enrichir plus tard avec une table de correspondance
    telephone,
    email,
    adresse,
    date_creation as date_debut_validite,
    cast('9999-12-31 23:59:59' as timestamp with time zone) as date_fin_validite
FROM staging.stg_entreprises;

-- 4. Fait Demandes Attribution
INSERT INTO dwh.fait_demandes_attribution (
    demande_source_id,
    temps_id,
    zone_id,
    lot_id,
    entreprise_id,
    numero_demande,
    type_demande,
    statut,
    est_prioritaire,
    duree_traitement,
    date_creation,
    date_validation,
    date_rejet
)
SELECT 
    d.id as demande_source_id,
    t.temps_id as temps_id,
    z.zone_id,
    l.lot_id,
    e.entreprise_id,
    d.reference as numero_demande,
    d.type_demande,
    d.statut,
    CASE WHEN d.priorite = 'HAUTE' THEN true ELSE false END as est_prioritaire,
    COALESCE(
        EXTRACT(DAY FROM 
            COALESCE(
                CASE 
                    WHEN d.statut = 'VALIDÉE' THEN d.updated_at 
                    WHEN d.statut = 'REJETÉE' THEN d.updated_at
                    ELSE NULL 
                END,
                d.updated_at
            ) - d.created_at
        )::integer,
        0
    ) as duree_traitement,
    d.created_at as date_creation,
    CASE WHEN d.statut = 'VALIDÉE' THEN d.updated_at ELSE NULL END as date_validation,
    CASE WHEN d.statut = 'REJETÉE' THEN d.updated_at ELSE NULL END as date_rejet
FROM staging.stg_demandes_attribution d
LEFT JOIN dwh.dim_temps t ON 
    t.annee = EXTRACT(YEAR FROM d.created_at)::integer AND
    t.mois = EXTRACT(MONTH FROM d.created_at)::integer AND
    t.jour = EXTRACT(DAY FROM d.created_at)::integer
LEFT JOIN dwh.dim_zone_industrielle z ON d.zone_id = z.zone_source_id
LEFT JOIN dwh.dim_lot l ON d.lot_id = l.lot_source_id
LEFT JOIN dwh.dim_entreprise e ON d.entreprise_id = e.entreprise_source_id
WHERE t.temps_id IS NOT NULL; -- S'assurer que la date existe dans la dimension temps

COMMIT;