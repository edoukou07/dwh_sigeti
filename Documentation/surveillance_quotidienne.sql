-- Script de surveillance rapide quotidienne
-- À exécuter régulièrement pour vérifier l'état du système DWH

-- ===============================
-- SURVEILLANCE RAPIDE QUOTIDIENNE
-- ===============================

-- Connexion à sigeti_node_db d'abord
\echo 'SURVEILLANCE QUOTIDIENNE - ENTREPOT SIGETI'
\echo '=========================================='

\echo ''
\echo '1. ÉTAT CDC:'
\echo '-----------'
SELECT * FROM cdc.get_cdc_stats();

\echo ''
\echo '2. JOBS PGAGENT:'  
\echo '---------------'
SELECT 
    j.jobname,
    CASE WHEN j.jobenabled THEN 'Activé' ELSE 'Désactivé' END as statut,
    COALESCE(j.joblastrun::text, 'Jamais exécuté') as derniere_execution,
    CASE 
        WHEN j.joblastrun IS NULL THEN '⚠️  Jamais exécuté'
        WHEN j.jobname LIKE '%Processing%' AND 
             j.joblastrun < NOW() - INTERVAL '10 minutes' 
        THEN '🔴 ALERTE: Traitement en retard'
        WHEN j.jobname LIKE '%Cleanup%' AND 
             j.joblastrun < NOW() - INTERVAL '25 hours'
        THEN '🔴 ALERTE: Nettoyage en retard'  
        ELSE '✅ OK'
    END as alerte
FROM pgagent.pga_job j
WHERE j.jobname LIKE '%CDC%'
ORDER BY j.jobname;

\echo ''
\echo '3. ACTIVITÉ RÉCENTE:'
\echo '------------------'
SELECT 
    table_name,
    COUNT(*) as nb_changements_24h
FROM cdc_log 
WHERE changed_at >= NOW() - INTERVAL '24 hours'
GROUP BY table_name
ORDER BY nb_changements_24h DESC;

\echo ''
\echo '4. ALERTES SYSTÈME:'
\echo '-----------------'
SELECT 
    CASE
        WHEN COUNT(CASE WHEN processed = false THEN 1 END) > 100 
        THEN '🔴 ALERTE: Plus de 100 entrées non traitées (' || 
             COUNT(CASE WHEN processed = false THEN 1 END) || ')'
        WHEN COUNT(*) > 10000 
        THEN '🟡 ATTENTION: Table CDC volumineuse (' || COUNT(*) || ' entrées)'
        ELSE '✅ OK: Système normal'
    END as alerte_principale,
    COUNT(*) as total_entries,
    COUNT(CASE WHEN processed = false THEN 1 END) as non_traitees,
    COUNT(CASE WHEN processed = true THEN 1 END) as traitees
FROM cdc_log;

-- Note: Pour vérifier le DWH, exécuter dans sigeti_dwh:
-- \c sigeti_dwh
-- SELECT COUNT(*) as zones_actuelles FROM dwh.dim_zones_industrielles WHERE est_actuel = true;