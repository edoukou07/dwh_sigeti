-- Migration des données de dimension lots
\echo 'Début migration dim_lots...'

-- Vider la table
TRUNCATE TABLE dwh.dim_lots CASCADE;

-- Insérer des données de test basées sur les lots existants  
INSERT INTO dwh.dim_lots (
    lot_key,
    lot_id,
    zone_key,
    numero_lot,
    superficie,
    prix_m2,
    statut_lot,
    type_lot,
    coordonnees_gps,
    date_creation,
    date_modification
) VALUES
-- Zone 1 - Lots variés
(1, 5, 1, 'LOT-001', 50008, 2000.32, 'DISPONIBLE', 'INDUSTRIEL', '-3.9932,-3.9932', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(2, 6, 1, 'LOT-004', 7861, 2000.00, 'DISPONIBLE', 'INDUSTRIEL', '-4.0111,-4.0111', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(3, 38, 3, 'LOT-13', 50008, 20000.00, 'DISPONIBLE', 'INDUSTRIEL', '-4.1440,-4.1440', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
-- Lots supplémentaires pour couvrir les besoins
(4, 10, 1, 'LOT-002', 25000, 1800.50, 'RESERVE', 'COMMERCIAL', '-3.9950,-3.9950', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(5, 15, 2, 'LOT-005', 30000, 2200.75, 'OCCUPE', 'INDUSTRIEL', '-4.0200,-4.0200', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(6, 20, 2, 'LOT-006', 15000, 1950.00, 'DISPONIBLE', 'MIXTE', '-4.0300,-4.0300', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(7, 25, 3, 'LOT-007', 40000, 2500.00, 'RESERVE', 'INDUSTRIEL', '-4.1500,-4.1500', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(8, 30, 3, 'LOT-008', 35000, 2100.25, 'DISPONIBLE', 'COMMERCIAL', '-4.1600,-4.1600', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(9, 35, 1, 'LOT-009', 28000, 1850.50, 'OCCUPE', 'INDUSTRIEL', '-3.9800,-3.9800', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(10, 40, 2, 'LOT-010', 45000, 2300.00, 'DISPONIBLE', 'INDUSTRIEL', '-4.0400,-4.0400', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- Vérifier le résultat
SELECT COUNT(*) as nb_lots_migres FROM dwh.dim_lots;

-- Afficher un échantillon
SELECT lot_key, numero_lot, superficie, statut_lot FROM dwh.dim_lots ORDER BY lot_key LIMIT 5;

\echo 'Migration dim_lots terminée.'