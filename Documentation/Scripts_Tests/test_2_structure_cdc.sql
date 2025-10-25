-- Test 2: Structure CDC
-- Guide_Tests_DWH_SIGETI.md - Test 2

-- 2.1 Vérifier les tables CDC
SELECT 'Tables CDC' as verification;
SELECT schemaname, tablename FROM pg_tables 
WHERE schemaname = 'cdc' OR (schemaname = 'public' AND tablename = 'cdc_log')
ORDER BY schemaname, tablename;

-- 2.2 Vérifier les triggers CDC sur les tables métier
SELECT 'Triggers CDC' as verification;
SELECT 
    schemaname,
    tablename,
    triggername
FROM pg_trigger t
JOIN pg_class c ON t.tgrelid = c.oid
JOIN pg_namespace n ON c.relnamespace = n.oid
WHERE triggername LIKE '%cdc%'
ORDER BY tablename;

-- 2.3 Vérifier les fonctions CDC
SELECT 'Fonctions CDC' as verification;
SELECT 
    n.nspname as schema_name,
    p.proname as function_name,
    pg_get_function_result(p.oid) as return_type
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'cdc' OR p.proname LIKE '%cdc%' OR p.proname = 'log_changes'
ORDER BY schema_name, function_name;

-- 2.4 État initial des logs CDC
SELECT 'État CDC Initial' as verification;
SELECT 
    COUNT(*) as total_logs,
    COUNT(CASE WHEN processed = false THEN 1 END) as non_traites,
    COUNT(CASE WHEN processed = true THEN 1 END) as traites
FROM public.cdc_log;

-- 2.5 Derniers logs CDC (pour référence)
SELECT 'Derniers logs CDC' as verification;
SELECT id, table_name, operation, processed, changed_at
FROM public.cdc_log
ORDER BY id DESC
LIMIT 5;