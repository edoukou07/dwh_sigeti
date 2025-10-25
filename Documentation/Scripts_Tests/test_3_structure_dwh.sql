-- Test 3: Structure DWH
-- Guide_Tests_DWH_SIGETI.md - Test 3
-- À exécuter dans sigeti_dwh

-- 3.1 Vérifier les tables DWH
SELECT 'Tables DWH' as verification;
SELECT schemaname, tablename FROM pg_tables 
WHERE schemaname = 'dwh'
ORDER BY tablename;

-- 3.2 Vérifier les fonctions DWH
SELECT 'Fonctions DWH' as verification;
SELECT 
    n.nspname as schema_name,
    p.proname as function_name,
    pg_get_function_result(p.oid) as return_type
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'dwh'
ORDER BY function_name;

-- 3.3 Structure de la table de dimension principale
SELECT 'Structure dim_zones_industrielles' as verification;
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'dwh' 
AND table_name = 'dim_zones_industrielles'
ORDER BY ordinal_position;

-- 3.4 État initial du DWH
SELECT 'État DWH Initial' as verification;
SELECT 
    COUNT(*) as total_zones,
    COUNT(CASE WHEN est_actuel = true THEN 1 END) as zones_actuelles,
    COUNT(CASE WHEN est_actuel = false THEN 1 END) as zones_historiques
FROM dwh.dim_zones_industrielles;

-- 3.5 Vérifier la connectivité vers la base source
SELECT 'Test connectivité source' as verification;
SELECT dblink_connect('test_source', 
    'dbname=sigeti_node_db user=postgres password=postgres');

SELECT 'Connexion source OK' as resultat
FROM dblink('test_source', 'SELECT COUNT(*) FROM zones_industrielles') AS t(count_zones bigint);

SELECT dblink_disconnect('test_source');