-- Test 8: Jobs pgAgent
-- Guide_Tests_DWH_SIGETI.md - Test 8
-- À exécuter dans sigeti_node_db

-- ===============================
-- TEST 8: JOBS PGAGENT
-- ===============================

SELECT 'TEST 8: JOBS PGAGENT' as test_phase;

-- 8.1 Vérifier l'état des jobs
SELECT 'État des jobs pgAgent' as verification;
SELECT 
    j.jobid, j.jobname, j.jobenabled, j.joblastrun, j.jobnextrun,
    js.jstname, s.jscname as schedule_name
FROM pgagent.pga_job j
LEFT JOIN pgagent.pga_jobstep js ON j.jobid = js.jstjobid
LEFT JOIN pgagent.pga_schedule s ON j.jobid = s.jscjobid
WHERE j.jobname LIKE '%CDC%'
ORDER BY j.jobid;

-- 8.2 Test manuel de la fonction de nettoyage
SELECT 'Test fonction cleanup_old_logs' as verification;
SELECT cdc.cleanup_old_logs();

-- 8.3 Test des statistiques CDC
SELECT 'Statistiques CDC' as verification;
SELECT * FROM cdc.get_cdc_stats();

-- 8.4 Vérifier les logs d'exécution des jobs (s'il y en a)
SELECT 'Logs d''exécution des jobs' as verification;
SELECT 
    j.jobname, jl.jlgstatus, jl.jlgstart, jl.jlgduration,
    CASE jl.jlgstatus
        WHEN 's' THEN 'Succès'
        WHEN 'f' THEN 'ÉCHEC'  
        WHEN 'r' THEN 'En cours'
        ELSE 'Inconnu'
    END as statut_execution
FROM pgagent.pga_job j
JOIN pgagent.pga_joblog jl ON j.jobid = jl.jlgjobid
WHERE j.jobname LIKE '%CDC%'
ORDER BY jl.jlgstart DESC
LIMIT 5;

-- 8.5 Statut de surveillance des jobs
SELECT 'Surveillance des jobs' as verification;
SELECT 
    j.jobname, j.jobenabled, j.joblastrun,
    CASE 
        WHEN j.joblastrun IS NULL THEN 'Jamais exécuté'
        WHEN j.jobname LIKE '%Processing%' AND 
             j.joblastrun < NOW() - INTERVAL '10 minutes' 
        THEN 'ALERTE: Traitement en retard'
        WHEN j.jobname LIKE '%Cleanup%' AND 
             j.joblastrun < NOW() - INTERVAL '25 hours'
        THEN 'ALERTE: Nettoyage en retard'  
        ELSE 'OK'
    END as statut
FROM pgagent.pga_job j
WHERE j.jobname LIKE '%CDC%'
ORDER BY j.jobname;