-- Test 9: Archivage CDC
-- Guide_Tests_DWH_SIGETI.md - Test 9
-- À exécuter dans sigeti_node_db

-- ===============================
-- TEST 9: ARCHIVAGE CDC
-- ===============================

SELECT 'TEST 9: ARCHIVAGE CDC' as test_phase;

-- 9.1 État avant archivage
SELECT 'État avant archivage' as verification;
SELECT * FROM cdc.get_cdc_stats();

-- 9.2 Simuler des données anciennes (pour test uniquement)
-- Attention: ceci modifie temporairement les données pour test
SELECT 'Simulation données anciennes' as verification;
UPDATE cdc_log 
SET changed_at = NOW() - INTERVAL '35 days'
WHERE id = (
    SELECT MIN(id) 
    FROM cdc_log 
    WHERE processed = true 
    AND table_name = 'zones_industrielles'
);

-- 9.3 Vérifier la modification
SELECT 'Vérification données simulées' as verification;
SELECT 
    COUNT(*) as total_logs,
    COUNT(CASE WHEN changed_at < NOW() - INTERVAL '30 days' AND processed = true THEN 1 END) as eligibles_archivage
FROM cdc_log;

-- 9.4 Lancer l'archivage
SELECT 'Lancement archivage' as verification;
SELECT cdc.cleanup_old_logs();

-- 9.5 État après archivage
SELECT 'État après archivage' as verification;
SELECT * FROM cdc.get_cdc_stats();

-- 9.6 Vérifier le contenu de l'archive
SELECT 'Contenu archive CDC' as verification;
SELECT 
    id, table_name, operation, processed, changed_at, archived_at
FROM cdc.cdc_log_archive
ORDER BY archived_at DESC;

-- 9.7 Vérifier que les données ont été supprimées de la table principale
SELECT 'Vérification suppression table principale' as verification;
SELECT COUNT(*) as logs_restants_anciens
FROM cdc_log
WHERE changed_at < NOW() - INTERVAL '30 days' 
AND processed = true;