-- Fonction de nettoyage des logs CDC
CREATE OR REPLACE FUNCTION cdc.cleanup_old_logs()
RETURNS void AS $$
DECLARE
    v_count INTEGER;
BEGIN
    -- Archiver les entrées traitées de plus de 30 jours
    WITH moved_rows AS (
        DELETE FROM public.cdc_log
        WHERE processed = true
        AND changed_at < NOW() - INTERVAL '30 days'
        RETURNING *
    )
    INSERT INTO cdc.cdc_log_archive (
        table_name,
        operation,
        old_data,
        new_data,
        changed_at,
        processed
    )
    SELECT
        table_name,
        operation,
        old_data,
        new_data,
        changed_at,
        processed
    FROM moved_rows;

    GET DIAGNOSTICS v_count = ROW_COUNT;
    
    IF v_count > 0 THEN
        RAISE NOTICE 'Nettoyage CDC effectué à %. % entrées archivées.', NOW(), v_count;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Fonction pour obtenir les statistiques CDC
CREATE OR REPLACE FUNCTION cdc.get_cdc_stats()
RETURNS TABLE (
    category text,
    count bigint,
    oldest_entry timestamp,
    newest_entry timestamp
) AS $$
BEGIN
    RETURN QUERY
    SELECT 'CDC Actif' as category,
           COUNT(*),
           MIN(changed_at),
           MAX(changed_at)
    FROM public.cdc_log
    WHERE processed = false
    UNION ALL
    SELECT 'CDC Traité (non archivé)',
           COUNT(*),
           MIN(changed_at),
           MAX(changed_at)
    FROM public.cdc_log
    WHERE processed = true
    UNION ALL
    SELECT 'CDC Archivé',
           COUNT(*),
           MIN(changed_at),
           MAX(changed_at)
    FROM cdc.cdc_log_archive;
END;
$$ LANGUAGE plpgsql;