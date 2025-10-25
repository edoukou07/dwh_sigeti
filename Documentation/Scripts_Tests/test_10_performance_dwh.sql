-- Test 10 DWH: Performance dans le DWH
-- Guide_Tests_DWH_SIGETI.md - Test 10 (partie DWH)
-- À exécuter dans sigeti_dwh

-- ===============================
-- TEST 10 DWH: PERFORMANCE DANS LE DWH
-- ===============================

SELECT 'TEST 10 DWH: PERFORMANCE DANS LE DWH' as test_phase;

-- 10.1 Répartition des données dans le DWH
SELECT 'Répartition données DWH' as verification;
SELECT 
    COUNT(*) as total_enregistrements,
    COUNT(CASE WHEN est_actuel = true THEN 1 END) as actuels,
    COUNT(CASE WHEN est_actuel = false THEN 1 END) as historiques,
    ROUND(
        COUNT(CASE WHEN est_actuel = false THEN 1 END)::numeric / 
        COUNT(*)::numeric * 100, 2
    ) as pourcentage_historique
FROM dwh.dim_zones_industrielles;

-- 10.2 Distribution par statut
SELECT 'Distribution par statut' as verification;
SELECT 
    statut,
    COUNT(*) as nb_zones,
    COUNT(CASE WHEN est_actuel = true THEN 1 END) as actuelles
FROM dwh.dim_zones_industrielles
GROUP BY statut
ORDER BY nb_zones DESC;

-- 10.3 Évolution temporelle des données
SELECT 'Évolution temporelle' as verification;
SELECT 
    DATE_TRUNC('day', date_debut_validite) as jour,
    COUNT(*) as nouvelles_versions
FROM dwh.dim_zones_industrielles
WHERE date_debut_validite >= NOW() - INTERVAL '7 days'
GROUP BY DATE_TRUNC('day', date_debut_validite)
ORDER BY jour DESC;

-- 10.4 Zones avec le plus de versions
SELECT 'Zones avec plus de versions' as verification;
SELECT 
    code,
    COUNT(*) as nb_versions,
    MIN(date_debut_validite) as premiere_version,
    MAX(COALESCE(date_fin_validite, NOW())) as derniere_version
FROM dwh.dim_zones_industrielles
GROUP BY code
HAVING COUNT(*) > 1
ORDER BY nb_versions DESC;

-- 10.5 Taille des tables DWH
SELECT 'Taille tables DWH' as verification;
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as taille
FROM pg_tables 
WHERE schemaname = 'dwh'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- 10.6 Performance de la fonction de traitement
-- Test de performance de process_all_changes
SELECT 'Test performance traitement' as verification;
SELECT 
    'Début test performance' as statut,
    NOW() as timestamp_debut;

-- Exécuter le traitement (même s'il n'y a rien à traiter)
SELECT dwh.process_all_changes();

SELECT 
    'Fin test performance' as statut,
    NOW() as timestamp_fin;