-- Requêtes d'analyse du Data Warehouse SIGETI

-- 1. Nombre de demandes par zone industrielle et par statut
SELECT 
    z.zone_libelle,
    f.statut,
    COUNT(*) as nombre_demandes,
    AVG(f.duree_traitement) as duree_moyenne_traitement
FROM dwh.fait_demandes_attribution f
JOIN dwh.dim_zone_industrielle z ON f.zone_id = z.zone_id
GROUP BY z.zone_libelle, f.statut
ORDER BY z.zone_libelle, f.statut;

-- 2. Taux d'occupation des lots par zone industrielle
SELECT 
    z.zone_libelle,
    COUNT(l.lot_id) as nombre_total_lots,
    SUM(CASE WHEN l.statut = 'OCCUPE' THEN 1 ELSE 0 END) as lots_occupes,
    ROUND(
        SUM(CASE WHEN l.statut = 'OCCUPE' THEN 1 ELSE 0 END)::numeric * 100 / 
        COUNT(l.lot_id)::numeric, 
    2) as taux_occupation
FROM dwh.dim_zone_industrielle z
LEFT JOIN dwh.dim_lot l ON z.zone_id = l.zone_id
GROUP BY z.zone_libelle
ORDER BY taux_occupation DESC;

-- 3. Évolution mensuelle des demandes
SELECT 
    t.annee,
    t.mois,
    t.nom_mois,
    COUNT(*) as nombre_demandes,
    SUM(CASE WHEN f.statut = 'VALIDÉE' THEN 1 ELSE 0 END) as demandes_validees,
    SUM(CASE WHEN f.statut = 'REJETÉE' THEN 1 ELSE 0 END) as demandes_rejetees
FROM dwh.fait_demandes_attribution f
JOIN dwh.dim_temps t ON f.temps_id = t.temps_id
GROUP BY t.annee, t.mois, t.nom_mois
ORDER BY t.annee, t.mois;

-- 4. Analyse des entreprises par demande
WITH stats_entreprises AS (
    SELECT 
        e.entreprise_id,
        e.raison_sociale,
        COUNT(f.demande_id) as nombre_demandes,
        SUM(CASE WHEN f.statut = 'VALIDÉE' THEN 1 ELSE 0 END) as demandes_validees,
        AVG(f.duree_traitement) as duree_moyenne_traitement
    FROM dwh.dim_entreprise e
    LEFT JOIN dwh.fait_demandes_attribution f ON e.entreprise_id = f.entreprise_id
    GROUP BY e.entreprise_id, e.raison_sociale
)
SELECT 
    raison_sociale,
    nombre_demandes,
    demandes_validees,
    ROUND(demandes_validees::numeric * 100 / NULLIF(nombre_demandes, 0)::numeric, 2) as taux_succes,
    ROUND(duree_moyenne_traitement::numeric, 1) as duree_moyenne_jours
FROM stats_entreprises
WHERE nombre_demandes > 0
ORDER BY nombre_demandes DESC;

-- 5. Performance du traitement des demandes
SELECT 
    CASE 
        WHEN duree_traitement <= 7 THEN '1. ≤ 1 semaine'
        WHEN duree_traitement <= 14 THEN '2. ≤ 2 semaines'
        WHEN duree_traitement <= 30 THEN '3. ≤ 1 mois'
        ELSE '4. > 1 mois'
    END as categorie_duree,
    COUNT(*) as nombre_demandes,
    ROUND(AVG(duree_traitement)::numeric, 1) as duree_moyenne,
    MIN(duree_traitement) as duree_min,
    MAX(duree_traitement) as duree_max
FROM dwh.fait_demandes_attribution
WHERE statut IN ('VALIDÉE', 'REJETÉE')
GROUP BY 
    CASE 
        WHEN duree_traitement <= 7 THEN '1. ≤ 1 semaine'
        WHEN duree_traitement <= 14 THEN '2. ≤ 2 semaines'
        WHEN duree_traitement <= 30 THEN '3. ≤ 1 mois'
        ELSE '4. > 1 mois'
    END
ORDER BY categorie_duree;

-- 6. Analyse de la surface des lots par zone
SELECT 
    z.zone_libelle,
    COUNT(l.lot_id) as nombre_lots,
    ROUND(MIN(l.superficie)::numeric, 2) as surface_min,
    ROUND(AVG(l.superficie)::numeric, 2) as surface_moyenne,
    ROUND(MAX(l.superficie)::numeric, 2) as surface_max,
    ROUND(SUM(l.superficie)::numeric, 2) as surface_totale
FROM dwh.dim_zone_industrielle z
LEFT JOIN dwh.dim_lot l ON z.zone_id = l.zone_id
GROUP BY z.zone_libelle
ORDER BY surface_totale DESC;