-- Script pour appliquer les changements CDC au data warehouse
BEGIN;

-- Configuration
SET search_path = dwh, staging, public;

-- Fonction pour appliquer les changements aux dimensions de type SCD2
CREATE OR REPLACE FUNCTION dwh.apply_scd2_changes(
    dimension_table text,
    source_table text,
    key_column text,
    tracked_columns text[]
) RETURNS void AS $$
DECLARE
    sql_text text;
BEGIN
    -- Fermer les enregistrements modifiés
    sql_text := format('
        UPDATE %I
        SET date_fin_validite = c.changed_at - interval ''1 microsecond'',
            est_courant = false
        FROM cdc.changes c
        WHERE c.table_name = %L
        AND c.operation IN (''U'', ''D'')
        AND %I.%I = (c.row_data->>%L)::integer
        AND %I.est_courant = true
        AND c.changed_at > %I.date_debut_validite',
        dimension_table, source_table, dimension_table, key_column, key_column, 
        dimension_table, dimension_table
    );
    EXECUTE sql_text;

    -- Insérer les nouveaux enregistrements
    sql_text := format('
        INSERT INTO %I (
            %I,
            %s,
            date_debut_validite,
            date_fin_validite,
            est_courant
        )
        SELECT
            (c.row_data->>%L)::integer,
            %s,
            c.changed_at,
            ''9999-12-31''::timestamp,
            true
        FROM cdc.changes c
        WHERE c.table_name = %L
        AND c.operation IN (''I'', ''U'')',
        dimension_table,
        key_column,
        array_to_string(tracked_columns, ', '),
        key_column,
        array_to_string(array(
            SELECT format('(c.row_data->>%L)::%s', col, 
                CASE WHEN col LIKE '%_id' THEN 'integer'
                     WHEN col IN ('superficie', 'prix') THEN 'numeric'
                     ELSE 'text'
                END)
            FROM unnest(tracked_columns) col
        ), ', '),
        source_table
    );
    EXECUTE sql_text;
END;
$$ LANGUAGE plpgsql;

-- Fonction pour appliquer les changements aux faits
CREATE OR REPLACE FUNCTION dwh.apply_fact_changes() RETURNS void AS $$
BEGIN
    -- Traiter les nouvelles demandes et mises à jour
    INSERT INTO dwh.fait_demandes_attribution (
        demande_source_id,
        temps_id,
        zone_id,
        lot_id,
        entreprise_id,
        numero_demande,
        type_demande,
        statut,
        est_prioritaire,
        duree_traitement,
        date_creation,
        date_validation,
        date_rejet
    )
    SELECT 
        (c.row_data->>'id')::integer as demande_source_id,
        t.temps_id,
        z.zone_id,
        l.lot_id,
        e.entreprise_id,
        c.row_data->>'reference' as numero_demande,
        c.row_data->>'type_demande' as type_demande,
        c.row_data->>'statut' as statut,
        CASE WHEN c.row_data->>'priorite' = 'HAUTE' THEN true ELSE false END as est_prioritaire,
        EXTRACT(DAY FROM (c.changed_at - (c.row_data->>'created_at')::timestamp))::integer as duree_traitement,
        (c.row_data->>'created_at')::timestamp as date_creation,
        CASE WHEN c.row_data->>'statut' = 'VALIDÉE' THEN c.changed_at ELSE NULL END as date_validation,
        CASE WHEN c.row_data->>'statut' = 'REJETÉE' THEN c.changed_at ELSE NULL END as date_rejet
    FROM cdc.changes c
    JOIN dwh.dim_temps t ON date(c.changed_at) = t.date_complete
    LEFT JOIN dwh.dim_zone_industrielle z ON (c.row_data->>'zone_id')::integer = z.zone_source_id
    LEFT JOIN dwh.dim_lot l ON (c.row_data->>'lot_id')::integer = l.lot_source_id
    LEFT JOIN dwh.dim_entreprise e ON (c.row_data->>'entreprise_id')::integer = e.entreprise_source_id
    WHERE c.table_name = 'demandes_attribution'
    AND c.operation IN ('I', 'U')
    ON CONFLICT (demande_source_id) DO UPDATE
    SET 
        statut = EXCLUDED.statut,
        duree_traitement = EXCLUDED.duree_traitement,
        date_validation = EXCLUDED.date_validation,
        date_rejet = EXCLUDED.date_rejet;
END;
$$ LANGUAGE plpgsql;

-- Fonction principale pour appliquer tous les changements
CREATE OR REPLACE FUNCTION dwh.process_all_changes() RETURNS void AS $$
BEGIN
    -- Traiter les changements des zones industrielles
    PERFORM dwh.apply_scd2_changes(
        'dim_zone_industrielle',
        'zones_industrielles',
        'zone_source_id',
        ARRAY['code', 'libelle', 'description', 'superficie', 'adresse', 'statut', 'lots_disponibles']
    );

    -- Traiter les changements des lots
    PERFORM dwh.apply_scd2_changes(
        'dim_lot',
        'lots',
        'lot_source_id',
        ARRAY['numero', 'ilot', 'superficie', 'unite_mesure', 'prix', 'statut', 'priorite', 'viabilite', 'description']
    );

    -- Traiter les changements des entreprises
    PERFORM dwh.apply_scd2_changes(
        'dim_entreprise',
        'entreprises',
        'entreprise_source_id',
        ARRAY['raison_sociale', 'telephone', 'email', 'registre_commerce', 'compte_contribuable', 'forme_juridique', 'adresse']
    );

    -- Traiter les changements des demandes
    PERFORM dwh.apply_fact_changes();

    -- Marquer les changements comme traités
    DELETE FROM cdc.changes WHERE changed_at <= now();
END;
$$ LANGUAGE plpgsql;

-- Créer un trigger pour le traitement automatique des changements
CREATE OR REPLACE FUNCTION dwh.trigger_process_changes() RETURNS trigger AS $$
BEGIN
    PERFORM dwh.process_all_changes();
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Créer le trigger sur la table des changements
CREATE TRIGGER process_changes_trigger
AFTER INSERT ON cdc.changes
FOR EACH STATEMENT
EXECUTE FUNCTION dwh.trigger_process_changes();

COMMIT;