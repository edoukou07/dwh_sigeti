-- Configuration du CDC sur la base source
BEGIN;

-- Activer l'extension pglogical pour le CDC
CREATE EXTENSION IF NOT EXISTS pglogical;

-- Fonction pour créer les tables de suivi des modifications
CREATE OR REPLACE FUNCTION create_change_tracking_table(table_name text) 
RETURNS void AS $$
BEGIN
    EXECUTE format('
        CREATE TABLE IF NOT EXISTS cdc.%I_changes (
            operation char(1) NOT NULL,
            changed_at timestamp with time zone NOT NULL DEFAULT current_timestamp,
            row_data jsonb,
            changed_fields jsonb,
            PRIMARY KEY (changed_at, operation)
        )', table_name);
END;
$$ LANGUAGE plpgsql;

-- Créer le schéma CDC s'il n'existe pas
CREATE SCHEMA IF NOT EXISTS cdc;

-- Créer les tables de suivi pour chaque table source
SELECT create_change_tracking_table('zones_industrielles');
SELECT create_change_tracking_table('lots');
SELECT create_change_tracking_table('entreprises');
SELECT create_change_tracking_table('demandes_attribution');

-- Fonction pour créer les triggers de capture des modifications
CREATE OR REPLACE FUNCTION cdc.track_changes() 
RETURNS trigger AS $$
DECLARE
    old_row jsonb;
    new_row jsonb;
    changed jsonb;
BEGIN
    IF (TG_OP = 'UPDATE') THEN
        old_row = row_to_json(OLD)::jsonb;
        new_row = row_to_json(NEW)::jsonb;
        changed = (SELECT jsonb_object_agg(key, value)
                  FROM jsonb_each(new_row)
                  WHERE new_row->key IS DISTINCT FROM old_row->key);
        
        INSERT INTO cdc.changes (
            table_name,
            operation,
            row_data,
            changed_fields
        ) VALUES (
            TG_TABLE_NAME,
            TG_OP,
            new_row,
            changed
        );
        RETURN NEW;
    ELSIF (TG_OP = 'DELETE') THEN
        old_row = row_to_json(OLD)::jsonb;
        INSERT INTO cdc.changes (
            table_name,
            operation,
            row_data
        ) VALUES (
            TG_TABLE_NAME,
            TG_OP,
            old_row
        );
        RETURN OLD;
    ELSIF (TG_OP = 'INSERT') THEN
        new_row = row_to_json(NEW)::jsonb;
        INSERT INTO cdc.changes (
            table_name,
            operation,
            row_data
        ) VALUES (
            TG_TABLE_NAME,
            TG_OP,
            new_row
        );
        RETURN NEW;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Créer les triggers sur les tables sources
CREATE TRIGGER zones_industrielles_audit
AFTER INSERT OR UPDATE OR DELETE ON zones_industrielles
FOR EACH ROW EXECUTE FUNCTION cdc.track_changes();

CREATE TRIGGER lots_audit
AFTER INSERT OR UPDATE OR DELETE ON lots
FOR EACH ROW EXECUTE FUNCTION cdc.track_changes();

CREATE TRIGGER entreprises_audit
AFTER INSERT OR UPDATE OR DELETE ON entreprises
FOR EACH ROW EXECUTE FUNCTION cdc.track_changes();

CREATE TRIGGER demandes_attribution_audit
AFTER INSERT OR UPDATE OR DELETE ON demandes_attribution
FOR EACH ROW EXECUTE FUNCTION cdc.track_changes();

COMMIT;