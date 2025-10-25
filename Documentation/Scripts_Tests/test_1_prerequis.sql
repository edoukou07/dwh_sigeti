-- Test 1: Vérification des Prérequis
-- Guide_Tests_DWH_SIGETI.md - Test 1

\echo '🧪 TEST 1: VÉRIFICATION DES PRÉREQUIS'
\echo '====================================='

-- 1.1 Vérifier les extensions dans sigeti_node_db
\echo '1.1 Extensions dans sigeti_node_db:'
SELECT extname, extversion FROM pg_extension 
WHERE extname IN ('pgagent', 'dblink', 'postgis')
ORDER BY extname;

-- 1.2 Vérifier la connectivité dblink vers sigeti_dwh
\echo '1.2 Test connectivité dblink:'
SELECT dblink_connect('test_connection', 
    'dbname=sigeti_dwh user=postgres password=postgres');

SELECT 'Connexion réussie vers sigeti_dwh' as resultat
FROM dblink('test_connection', 'SELECT 1') AS t(test int);

SELECT dblink_disconnect('test_connection');

-- 1.3 Vérifier que PostgreSQL peut exécuter des fonctions PL/pgSQL
\echo '1.3 Test PL/pgSQL:'
DO $$
BEGIN
    RAISE NOTICE 'PL/pgSQL fonctionne correctement';
END;
$$;

-- 1.4 Vérifier l'existence des bases de données
\echo '1.4 Bases de données disponibles:'
SELECT datname FROM pg_database 
WHERE datname IN ('sigeti_node_db', 'sigeti_dwh')
ORDER BY datname;