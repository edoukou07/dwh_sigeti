-- Test 4-7: Tests Fonctionnels Complets
-- Guide_Tests_DWH_SIGETI.md - Tests 4-7
-- À exécuter dans sigeti_node_db

-- ===============================
-- TEST 4: CAPTURE CDC (INSERT)
-- ===============================

SELECT 'TEST 4: CAPTURE CDC (INSERT)' as test_phase;

-- 4.1 Vérifier les valeurs d'enum autorisées
SELECT 'Valeurs enum autorisées' as verification;
SELECT 'unite_mesure' as enum_name, enumlabel as valeur 
FROM pg_enum WHERE enumtypid = (
    SELECT oid FROM pg_type WHERE typname = 'enum_zones_industrielles_unite_mesure'
)
UNION ALL
SELECT 'statut' as enum_name, enumlabel as valeur 
FROM pg_enum WHERE enumtypid = (
    SELECT oid FROM pg_type WHERE typname = 'enum_zones_industrielles_statut'
)
ORDER BY enum_name, valeur;

-- 4.2 Insérer une zone de test
SELECT 'Insertion zone test' as verification;
INSERT INTO zones_industrielles (
    code, libelle, superficie, unite_mesure, statut, created_at, updated_at
) VALUES (
    'ZI_TEST_CDC', 
    'Zone Test CDC Complete', 
    150.5, 
    'ha', 
    'actif', 
    NOW(), 
    NOW()
);

-- 4.3 Vérifier la capture CDC
SELECT 'Vérification capture INSERT' as verification;
SELECT 
    id, table_name, operation, processed, changed_at,
    COALESCE(new_data->>'code', old_data->>'code') as code_zone
FROM cdc_log 
WHERE table_name = 'zones_industrielles'
AND COALESCE(new_data->>'code', old_data->>'code') = 'ZI_TEST_CDC'
ORDER BY id DESC;

-- ===============================  
-- TEST 5: TRAITEMENT CDC
-- ===============================

-- Note: Cette partie doit être exécutée dans sigeti_dwh
-- Voir script test_5_traitement_dwh.sql

-- ===============================
-- TEST 6: MODIFICATION (UPDATE) 
-- ===============================

SELECT 'TEST 6: MODIFICATION (UPDATE)' as test_phase;

-- 6.1 Modification de la zone test
SELECT 'Modification zone test' as verification;
UPDATE zones_industrielles 
SET 
    libelle = 'Zone Test CDC MODIFIEE',
    superficie = 200.0,
    updated_at = NOW()
WHERE code = 'ZI_TEST_CDC';

-- 6.2 Vérifier la capture de la modification
SELECT 'Vérification capture UPDATE' as verification;
SELECT 
    id, operation, processed,
    old_data->>'libelle' as ancien_libelle,
    new_data->>'libelle' as nouveau_libelle,
    old_data->>'superficie' as ancienne_superficie,
    new_data->>'superficie' as nouvelle_superficie
FROM cdc_log 
WHERE table_name = 'zones_industrielles'
AND (old_data->>'code' = 'ZI_TEST_CDC' OR new_data->>'code' = 'ZI_TEST_CDC')
ORDER BY id DESC 
LIMIT 3;

-- ===============================
-- TEST 7: SUPPRESSION (DELETE)
-- ===============================

SELECT 'TEST 7: SUPPRESSION (DELETE)' as test_phase;

-- 7.1 Suppression de la zone test
SELECT 'Suppression zone test' as verification;
DELETE FROM zones_industrielles WHERE code = 'ZI_TEST_CDC';

-- 7.2 Vérifier la capture de la suppression
SELECT 'Vérification capture DELETE' as verification;
SELECT 
    id, operation, processed,
    old_data->>'code' as code_supprime,
    old_data->>'libelle' as libelle_supprime,
    old_data->>'superficie' as superficie_supprime
FROM cdc_log 
WHERE table_name = 'zones_industrielles'
AND old_data->>'code' = 'ZI_TEST_CDC'
ORDER BY id DESC;

-- ===============================
-- RÉSUMÉ DES TESTS 4-7
-- ===============================

SELECT 'RÉSUMÉ DES CAPTURES CDC' as verification;
SELECT 
    operation,
    COUNT(*) as nb_operations,
    COUNT(CASE WHEN processed = true THEN 1 END) as traitees,
    COUNT(CASE WHEN processed = false THEN 1 END) as non_traitees
FROM cdc_log 
WHERE table_name = 'zones_industrielles'
AND (old_data->>'code' = 'ZI_TEST_CDC' OR new_data->>'code' = 'ZI_TEST_CDC')
GROUP BY operation
ORDER BY operation;