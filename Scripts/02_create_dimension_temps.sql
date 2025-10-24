-- Script pour générer la dimension temps
BEGIN;

-- Nettoyage de la table
TRUNCATE TABLE dwh.dim_temps CASCADE;

-- Insertion des dates
WITH RECURSIVE dates AS (
    -- Date de début : 1er janvier 2025
    SELECT cast('2025-01-01' as timestamp without time zone) as date
    UNION ALL
    -- Générer les dates jusqu'au 31 décembre 2026
    SELECT date + interval '1 day'
    FROM dates
    WHERE date < '2026-12-31'
)
INSERT INTO dwh.dim_temps (
    date_complete,
    annee,
    trimestre,
    mois,
    jour,
    jour_semaine,
    nom_jour_semaine,
    nom_mois,
    est_weekend
)
SELECT
    cast(date as date) as date_complete,
    cast(EXTRACT(YEAR FROM date) as integer) as annee,
    cast(EXTRACT(QUARTER FROM date) as integer) as trimestre,
    cast(EXTRACT(MONTH FROM date) as integer) as mois,
    cast(EXTRACT(DAY FROM date) as integer) as jour,
    cast(EXTRACT(DOW FROM date) + 1 as integer) as jour_semaine,
    TRIM(TO_CHAR(date, 'Day')) as nom_jour_semaine,
    TRIM(TO_CHAR(date, 'Month')) as nom_mois,
    CASE 
        WHEN EXTRACT(DOW FROM date) IN (0, 6) THEN true 
        ELSE false 
    END as est_weekend
FROM dates;

COMMIT;