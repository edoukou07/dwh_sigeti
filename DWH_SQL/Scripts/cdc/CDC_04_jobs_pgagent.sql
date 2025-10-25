-- Installation de pgAgent si ce n'est pas déjà fait
CREATE EXTENSION IF NOT EXISTS pgagent;

-- Création du job de nettoyage CDC
DO $$
DECLARE
    v_job_id integer;
    v_step_id integer;
    v_schedule_id integer;
BEGIN
    -- Création du job
    SELECT jobid INTO v_job_id
    FROM pgagent.pga_job
    WHERE jobname = 'CDC_Cleanup_Job';

    IF v_job_id IS NULL THEN
        INSERT INTO pgagent.pga_job(
            jobjclid, jobname, jobdesc, jobhostagent, jobenabled
        ) VALUES (
            1::integer, -- PostgreSQL job class
            'CDC_Cleanup_Job',
            'Nettoyage quotidien des logs CDC',
            '',        -- Run on any agent
            true      -- Enable the job
        ) RETURNING jobid INTO v_job_id;

        -- Création de l'étape du job
        INSERT INTO pgagent.pga_jobstep(
            jstjobid, jstname, jstenabled, jstkind,
            jstconnstr, jstdbname, jstcode, jstdesc
        ) VALUES (
            v_job_id,
            'Cleanup_Step',
            true,
            'sql'::character(1),
            '', -- Use default connection
            'sigeti_node_db',
            'SELECT cdc.cleanup_old_logs();',
            'Exécute la fonction de nettoyage CDC'
        ) RETURNING jstid INTO v_step_id;

        -- Création du schedule (tous les jours à 3h du matin)
        INSERT INTO pgagent.pga_schedule(
            jscjobid, jscname, jscdesc,
            jscenabled,
            jscstart    -- Date de début (maintenant)
        ) VALUES (
            v_job_id,
            'Daily_Schedule',
            'Exécution quotidienne à 3h du matin',
            true,
            current_timestamp
        ) RETURNING jscid INTO v_schedule_id;
        
        -- Mise à jour des horaires du schedule
        UPDATE pgagent.pga_schedule 
        SET jscminutes = ARRAY[true,false,false,false,false,false,false,false,false,false,
                              false,false,false,false,false,false,false,false,false,false,
                              false,false,false,false,false,false,false,false,false,false,
                              false,false,false,false,false,false,false,false,false,false,
                              false,false,false,false,false,false,false,false,false,false,
                              false,false,false,false,false,false,false,false,false,false]::boolean[], -- Minute 0
            jschours = ARRAY[false,false,false,true,false,false,false,false,false,false,
                           false,false,false,false,false,false,false,false,false,false,
                           false,false,false,false]::boolean[], -- 3h du matin
            jscweekdays = ARRAY[true,true,true,true,true,true,true]::boolean[], -- Tous les jours
            jscmonthdays = ARRAY[true,true,true,true,true,true,true,true,true,true,
                                true,true,true,true,true,true,true,true,true,true,
                                true,true,true,true,true,true,true,true,true,true,
                                true]::boolean[], -- Tous les jours du mois
            jscmonths = ARRAY[true,true,true,true,true,true,true,true,true,true,
                             true,true]::boolean[]     -- Tous les mois
        WHERE jscid = v_schedule_id;

        RAISE NOTICE 'Job de nettoyage CDC créé avec succès (ID: %)', v_job_id;
    ELSE
        RAISE NOTICE 'Le job de nettoyage CDC existe déjà (ID: %)', v_job_id;
    END IF;
END;
$$;