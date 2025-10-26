-- Migration basique des données de faits
\echo 'Insertion données tests dans fait_demandes_attribution...'

-- Vider la table
TRUNCATE TABLE dwh.fait_demandes_attribution;

-- Insérer des données de test basées sur les 5 demandes existantes
INSERT INTO dwh.fait_demandes_attribution (
    demande_key,
    operateur_key,
    entreprise_key,
    temps_key,
    statut_key,
    montant_demande,
    duree_traitement_jours,
    date_demande,
    date_traitement,
    date_creation,
    date_modification
) VALUES
-- Demande 1
(1, 1, 1, 1, 1, 500000, 15, '2025-10-03', '2025-10-18', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
-- Demande 2  
(2, 2, 2, 1, 2, 1000000000, 7, '2025-10-03', '2025-10-10', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
-- Demande 3
(3, 3, 3, 1, 1, 1500000000, 23, '2025-10-03', '2025-10-26', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
-- Demande 4
(4, 4, 4, 1, 1, 750000000, 12, '2025-09-25', '2025-10-07', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
-- Demande 5
(5, 5, 5, 1, 2, 250000000, 30, '2025-09-15', '2025-10-15', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- Vérifier le résultat
SELECT COUNT(*) as nb_faits_migres FROM dwh.fait_demandes_attribution;

\echo 'Migration fait_demandes_attribution terminée.'