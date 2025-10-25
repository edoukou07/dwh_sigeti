-- Configuration de la réplication dans le DWH
CREATE SCHEMA IF NOT EXISTS dwh;

-- Fonction pour traiter les changements CDC
CREATE OR REPLACE FUNCTION dwh.process_all_changes()
RETURNS void AS $$
DECLARE
    r RECORD;
BEGIN
    -- Récupérer les changements non traités depuis la base source
    FOR r IN (
        SELECT * FROM dblink(
            'dbname=sigeti_node_db user=postgres password=postgres',
            'SELECT id, table_name, operation, old_data, new_data 
             FROM cdc_log 
             WHERE processed = false 
             ORDER BY id'
        ) AS ct(id int, table_name text, operation text, old_data jsonb, new_data jsonb)
    )
    LOOP
        -- Traiter chaque changement selon la table et l'opération
        CASE r.table_name
            WHEN 'zones_industrielles' THEN
                CASE r.operation
                    WHEN 'INSERT' THEN
                        INSERT INTO dwh.dim_zones_industrielles (
                            id_source,
                            code,
                            libelle,
                            superficie,
                            unite_mesure,
                            statut,
                            date_debut_validite,
                            date_fin_validite,
                            est_actuel
                        )
                        SELECT 
                            (r.new_data->>'id')::integer,
                            r.new_data->>'code',
                            r.new_data->>'libelle',
                            (r.new_data->>'superficie')::float,
                            r.new_data->>'unite_mesure',
                            r.new_data->>'statut',
                            CURRENT_TIMESTAMP,
                            NULL,
                            true;

                    WHEN 'UPDATE' THEN
                        -- Fermer l'enregistrement actuel
                        UPDATE dwh.dim_zones_industrielles
                        SET date_fin_validite = CURRENT_TIMESTAMP - interval '1 second',
                            est_actuel = false
                        WHERE id_source = (r.new_data->>'id')::integer
                        AND est_actuel = true;

                        -- Insérer le nouvel enregistrement
                        INSERT INTO dwh.dim_zones_industrielles (
                            id_source,
                            code,
                            libelle,
                            superficie,
                            unite_mesure,
                            statut,
                            date_debut_validite,
                            date_fin_validite,
                            est_actuel
                        )
                        SELECT 
                            (r.new_data->>'id')::integer,
                            r.new_data->>'code',
                            r.new_data->>'libelle',
                            (r.new_data->>'superficie')::float,
                            r.new_data->>'unite_mesure',
                            r.new_data->>'statut',
                            CURRENT_TIMESTAMP,
                            NULL,
                            true;

                    WHEN 'DELETE' THEN
                        UPDATE dwh.dim_zones_industrielles
                        SET date_fin_validite = CURRENT_TIMESTAMP,
                            est_actuel = false
                        WHERE id_source = (r.old_data->>'id')::integer
                        AND est_actuel = true;
                END CASE;
            -- Ajouter d'autres tables ici avec leur logique de traitement
        END CASE;

        -- Marquer le changement comme traité dans la base source
        PERFORM dblink_exec(
            'dbname=sigeti_node_db user=postgres password=postgres',
            format('UPDATE cdc_log SET processed = true WHERE id = %s', r.id)
        );
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Créer la table des dimensions pour les zones industrielles si elle n'existe pas
CREATE TABLE IF NOT EXISTS dwh.dim_zones_industrielles (
    id_dwh SERIAL PRIMARY KEY,
    id_source INTEGER NOT NULL,
    code VARCHAR(50) NOT NULL,
    libelle VARCHAR(255) NOT NULL,
    superficie FLOAT,
    unite_mesure VARCHAR(10),
    statut VARCHAR(50),
    date_debut_validite TIMESTAMP NOT NULL,
    date_fin_validite TIMESTAMP,
    est_actuel BOOLEAN DEFAULT true,
    CONSTRAINT uk_zones_industrielles_version UNIQUE (id_source, date_debut_validite)
);

-- Index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_zi_id_source ON dwh.dim_zones_industrielles(id_source);
CREATE INDEX IF NOT EXISTS idx_zi_est_actuel ON dwh.dim_zones_industrielles(est_actuel);
CREATE INDEX IF NOT EXISTS idx_zi_dates ON dwh.dim_zones_industrielles(date_debut_validite, date_fin_validite);