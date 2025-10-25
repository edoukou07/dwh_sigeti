-- Test 5: Traitement dans le DWH
-- Guide_Tests_DWH_SIGETI.md - Test 5  
-- À exécuter dans sigeti_dwh

-- ===============================
-- TEST 5: TRAITEMENT CDC DANS DWH
-- ===============================

SELECT 'TEST 5: TRAITEMENT CDC DANS DWH' as test_phase;

-- 5.1 État avant traitement
SELECT 'État avant traitement' as verification;
SELECT 
    COUNT(*) as zones_avant_traitement,
    COUNT(CASE WHEN est_actuel = true THEN 1 END) as actuelles_avant
FROM dwh.dim_zones_industrielles;

-- 5.2 Traitement des changements
SELECT 'Traitement des changements CDC' as verification;
SELECT dwh.process_all_changes();

-- 5.3 État après traitement  
SELECT 'État après traitement' as verification;
SELECT 
    COUNT(*) as zones_apres_traitement,
    COUNT(CASE WHEN est_actuel = true THEN 1 END) as actuelles_apres
FROM dwh.dim_zones_industrielles;

-- 5.4 Vérifier la zone test dans le DWH (après INSERT)
SELECT 'Zone test dans DWH après INSERT' as verification;
SELECT 
    id_source, code, libelle, superficie, unite_mesure,
    statut, est_actuel, date_debut_validite
FROM dwh.dim_zones_industrielles 
WHERE code = 'ZI_TEST_CDC'
ORDER BY date_debut_validite DESC;

-- Traitement après UPDATE (à exécuter après le test UPDATE)
-- 5.5 Traitement après modification
SELECT 'Traitement après UPDATE' as verification;
SELECT dwh.process_all_changes();

-- 5.6 Vérifier le versioning SCD Type 2
SELECT 'Versioning SCD Type 2' as verification;
SELECT 
    id_source, code, libelle, superficie, est_actuel,
    date_debut_validite, date_fin_validite
FROM dwh.dim_zones_industrielles 
WHERE code = 'ZI_TEST_CDC'
ORDER BY date_debut_validite;

-- Traitement après DELETE (à exécuter après le test DELETE)
-- 5.7 Traitement après suppression
SELECT 'Traitement après DELETE' as verification;
SELECT dwh.process_all_changes();

-- 5.8 Vérifier fermeture après suppression
SELECT 'État après suppression' as verification;
SELECT 
    id_source, code, libelle, est_actuel,
    date_debut_validite, date_fin_validite
FROM dwh.dim_zones_industrielles 
WHERE code = 'ZI_TEST_CDC'
ORDER BY date_debut_validite;