-- =============================================================================
-- NETTOYAGE COMPLET DE LA BASE SIGETI_DWH
-- =============================================================================

-- Suppression des contraintes de clés étrangères en premier
DO $$
DECLARE
    constraint_record RECORD;
BEGIN
    -- Supprimer toutes les contraintes de clés étrangères
    FOR constraint_record IN
        SELECT constraint_name, table_name, table_schema
        FROM information_schema.table_constraints
        WHERE constraint_type = 'FOREIGN KEY'
        AND table_schema IN ('dwh', 'cdc', 'staging', 'etl', 'monitoring')
    LOOP
        EXECUTE format('ALTER TABLE %I.%I DROP CONSTRAINT IF EXISTS %I',
                      constraint_record.table_schema,
                      constraint_record.table_name,
                      constraint_record.constraint_name);
        RAISE NOTICE 'Contrainte supprimée: %.%', constraint_record.table_name, constraint_record.constraint_name;
    END LOOP;
END $$;

-- Suppression de toutes les vues
DO $$
DECLARE
    view_record RECORD;
BEGIN
    FOR view_record IN
        SELECT table_name, table_schema
        FROM information_schema.views
        WHERE table_schema IN ('dwh', 'cdc', 'staging', 'etl', 'monitoring')
    LOOP
        EXECUTE format('DROP VIEW IF EXISTS %I.%I CASCADE', view_record.table_schema, view_record.table_name);
        RAISE NOTICE 'Vue supprimée: %.%', view_record.table_schema, view_record.table_name;
    END LOOP;
END $$;

-- Suppression de toutes les fonctions
DO $$
DECLARE
    func_record RECORD;
BEGIN
    FOR func_record IN
        SELECT routine_name, routine_schema
        FROM information_schema.routines
        WHERE routine_type = 'FUNCTION'
        AND routine_schema IN ('dwh', 'cdc', 'staging', 'etl', 'monitoring')
    LOOP
        EXECUTE format('DROP FUNCTION IF EXISTS %I.%I CASCADE', func_record.routine_schema, func_record.routine_name);
        RAISE NOTICE 'Fonction supprimée: %.%', func_record.routine_schema, func_record.routine_name;
    END LOOP;
END $$;

-- Suppression de toutes les tables
DO $$
DECLARE
    table_record RECORD;
BEGIN
    FOR table_record IN
        SELECT table_name, table_schema
        FROM information_schema.tables
        WHERE table_type = 'BASE TABLE'
        AND table_schema IN ('dwh', 'cdc', 'staging', 'etl', 'monitoring')
    LOOP
        EXECUTE format('DROP TABLE IF EXISTS %I.%I CASCADE', table_record.table_schema, table_record.table_name);
        RAISE NOTICE 'Table supprimée: %.%', table_record.table_schema, table_record.table_name;
    END LOOP;
END $$;

-- Suppression des schémas (ils seront recréés après)
DROP SCHEMA IF EXISTS dwh CASCADE;
DROP SCHEMA IF EXISTS cdc CASCADE;
DROP SCHEMA IF EXISTS staging CASCADE;
DROP SCHEMA IF EXISTS etl CASCADE;
DROP SCHEMA IF EXISTS monitoring CASCADE;

-- Message de confirmation
SELECT 'NETTOYAGE COMPLET TERMINE - BASE SIGETI_DWH VIDEE' as status;