-- Test 10: Performance et Surveillance
-- Guide_Tests_DWH_SIGETI.md - Test 10
-- À exécuter dans sigeti_node_db puis sigeti_dwh

-- ===============================
-- TEST 10: PERFORMANCE ET SURVEILLANCE
-- ===============================

SELECT 'TEST 10: PERFORMANCE ET SURVEILLANCE' as test_phase;

-- 10.1 Taille des tables CDC
SELECT 'Taille des tables CDC' as verification;
SELECT 
    schemaname, 
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as taille,
    pg_total_relation_size(schemaname||'.'||tablename) as taille_bytes
FROM pg_tables 
WHERE (schemaname = 'cdc' OR (schemaname = 'public' AND tablename = 'cdc_log'))
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- 10.2 Statistiques des opérations CDC
SELECT 'Statistiques opérations CDC' as verification;
SELECT 
    operation,
    COUNT(*) as nb_operations,
    COUNT(CASE WHEN processed = true THEN 1 END) as traitees,
    COUNT(CASE WHEN processed = false THEN 1 END) as non_traitees,
    ROUND(
        COUNT(CASE WHEN processed = true THEN 1 END)::numeric / 
        COUNT(*)::numeric * 100, 2
    ) as pourcentage_traite
FROM cdc_log 
GROUP BY operation
ORDER BY operation;

-- 10.3 Performance par table
SELECT 'Performance par table' as verification;
SELECT 
    table_name,
    COUNT(*) as nb_changements,
    COUNT(CASE WHEN processed = true THEN 1 END) as traites,
    MIN(changed_at) as plus_ancien,
    MAX(changed_at) as plus_recent
FROM cdc_log 
GROUP BY table_name
ORDER BY nb_changements DESC;

-- 10.4 Statistiques temporelles (dernières 24h)
SELECT 'Activité dernières 24h' as verification;
SELECT 
    DATE_TRUNC('hour', changed_at) as heure,
    COUNT(*) as nb_changements
FROM cdc_log 
WHERE changed_at >= NOW() - INTERVAL '24 hours'
GROUP BY DATE_TRUNC('hour', changed_at)
ORDER BY heure DESC;

-- 10.5 Alertes système
SELECT 'Alertes système' as verification;
SELECT 
    CASE
        WHEN COUNT(CASE WHEN processed = false THEN 1 END) > 100 
        THEN 'ALERTE: Plus de 100 entrées non traitées (' || 
             COUNT(CASE WHEN processed = false THEN 1 END) || ')'
        WHEN COUNT(*) > 10000 
        THEN 'ATTENTION: Table CDC volumineuse (' || COUNT(*) || ' entrées)'
        ELSE 'OK: Système normal'
    END as alerte_principale,
    COUNT(*) as total_entries,
    COUNT(CASE WHEN processed = false THEN 1 END) as non_traitees
FROM cdc_log;

-- Note: Les parties suivantes doivent être exécutées dans sigeti_dwh
-- Voir script test_10_performance_dwh.sql pour la partie DWH