# 📋 TESTS DÉTAILLÉS - DWH SIGETI
*Procédures techniques spécialisées*

> **📚 GUIDE PRINCIPAL** : `GUIDE_COMPLET.md`  
> **🚀 TESTS AUTO** : `executer_tests_complets.bat`

## 🎯 Objectif
Procédures techniques détaillées pour validation experte du système DWH SIGETI.

## 🏗️ Architecture Testée

```
Base Source (sigeti_node_db)     →     Base DWH (sigeti_dwh)
├─ Tables métier                 →     ├─ Tables de dimensions
├─ Triggers CDC                  →     ├─ Fonctions de traitement
├─ Table cdc_log                 →     ├─ Jobs pgAgent
└─ Archive CDC                   →     └─ Versioning SCD Type 2
```

## 📋 Prérequis

### Logiciels Requis
- PostgreSQL 13+ avec pgAgent
- pgAdmin 4 (optionnel, pour interface graphique)
- PowerShell (Windows) ou Terminal (Linux/Mac)

### Extensions PostgreSQL
- `pgagent` - Pour les jobs automatiques
- `dblink` - Pour les connexions inter-bases
- `postgis` - Pour les données géographiques (si applicable)

### Bases de Données
- `sigeti_node_db` - Base source avec les données métier
- `sigeti_dwh` - Base d'entrepôt de données

## 🧪 Tests à Effectuer

### ✅ Test 1: Vérification des Prérequis

**Objectif:** S'assurer que tous les composants sont installés et configurés

```sql
-- 1.1 Vérifier les extensions dans sigeti_node_db
\c sigeti_node_db
SELECT extname, extversion FROM pg_extension 
WHERE extname IN ('pgagent', 'dblink', 'postgis');

-- 1.2 Vérifier les extensions dans sigeti_dwh  
\c sigeti_dwh
SELECT extname, extversion FROM pg_extension 
WHERE extname IN ('pgagent', 'dblink', 'postgis');

-- 1.3 Vérifier la connectivité dblink
SELECT dblink_connect('test_connection', 
    'dbname=sigeti_node_db user=postgres password=postgres');
SELECT dblink_disconnect('test_connection');
```

**Résultat Attendu:**
- Extensions installées et fonctionnelles
- Connexion dblink opérationnelle

---

### ✅ Test 2: Vérification de la Structure CDC

**Objectif:** Confirmer que les triggers et tables CDC sont en place

```sql
-- 2.1 Vérifier les tables CDC dans sigeti_node_db
\c sigeti_node_db
\dt cdc.*
\dt public.cdc_log

-- 2.2 Vérifier les triggers sur les tables métier
SELECT 
    schemaname,
    tablename,
    trigger_name
FROM information_schema.triggers 
WHERE trigger_name LIKE '%cdc%'
ORDER BY tablename;

-- 2.3 Vérifier les fonctions CDC
\df cdc.*
\df public.log_changes

-- 2.4 État initial des logs CDC
SELECT 
    COUNT(*) as total_logs,
    COUNT(*) FILTER (WHERE processed = false) as non_traites,
    COUNT(*) FILTER (WHERE processed = true) as traites
FROM public.cdc_log;
```

**Résultat Attendu:**
- Table `cdc.cdc_log_archive` existante
- Table `public.cdc_log` existante  
- Triggers CDC sur les tables métier
- Fonctions `log_changes()`, `cleanup_old_logs()`, `get_cdc_stats()`

---

### ✅ Test 3: Vérification de la Structure DWH

**Objectif:** Confirmer que les tables de dimension et fonctions DWH sont prêtes

```sql
-- 3.1 Vérifier les tables DWH dans sigeti_dwh
\c sigeti_dwh
\dt dwh.*

-- 3.2 Vérifier les fonctions DWH
\df dwh.*

-- 3.3 Structure de la table de dimension principale
\d dwh.dim_zones_industrielles

-- 3.4 État initial du DWH
SELECT 
    COUNT(*) as total_zones,
    COUNT(*) FILTER (WHERE est_actuel = true) as zones_actuelles,
    COUNT(*) FILTER (WHERE est_actuel = false) as zones_historiques
FROM dwh.dim_zones_industrielles;
```

**Résultat Attendu:**
- Tables de dimension `dwh.dim_*` existantes
- Fonction `dwh.process_all_changes()` opérationnelle
- Structure SCD Type 2 avec colonnes de versioning

---

### ✅ Test 4: Test de Capture CDC (INSERT)

**Objectif:** Vérifier que les changements sont correctement capturés

```sql
-- 4.1 Connexion à la base source
\c sigeti_node_db

-- 4.2 Vérifier les valeurs d'enum autorisées
SELECT 'unite_mesure' as enum_name, enumlabel as valeur 
FROM pg_enum WHERE enumtypid = (
    SELECT oid FROM pg_type WHERE typname = 'enum_zones_industrielles_unite_mesure'
)
UNION ALL
SELECT 'statut' as enum_name, enumlabel as valeur 
FROM pg_enum WHERE enumtypid = (
    SELECT oid FROM pg_type WHERE typname = 'enum_zones_industrielles_statut'
)
ORDER BY enum_name, valeur;

-- 4.3 Insérer une zone de test
INSERT INTO zones_industrielles (
    code, libelle, superficie, unite_mesure, statut, created_at, updated_at
) VALUES (
    'ZI_TEST_001', 
    'Zone Test CDC', 
    150.5, 
    'ha', 
    'actif', 
    NOW(), 
    NOW()
);

-- 4.4 Vérifier que le trigger a capturé l'insertion
SELECT 
    id, table_name, operation, processed, changed_at,
    COALESCE(new_data->>'code', old_data->>'code') as code_zone
FROM public.cdc_log 
WHERE table_name = 'zones_industrielles'
ORDER BY id DESC 
LIMIT 3;
```

**Résultat Attendu:**
- Nouvelle entrée dans `cdc_log` avec `operation = 'INSERT'`
- `processed = false` 
- `new_data` contient les données de la nouvelle zone

---

### ✅ Test 5: Test de Traitement CDC

**Objectif:** Vérifier que les changements sont traités vers le DWH

```sql
-- 5.1 Connexion à la base DWH
\c sigeti_dwh

-- 5.2 État avant traitement
SELECT COUNT(*) as zones_avant_traitement 
FROM dwh.dim_zones_industrielles 
WHERE est_actuel = true;

-- 5.3 Traitement des changements
SELECT dwh.process_all_changes();

-- 5.4 État après traitement
SELECT COUNT(*) as zones_apres_traitement 
FROM dwh.dim_zones_industrielles 
WHERE est_actuel = true;

-- 5.5 Vérifier la nouvelle zone dans le DWH
SELECT 
    id_source, code, libelle, superficie, unite_mesure, 
    statut, est_actuel, date_debut_validite
FROM dwh.dim_zones_industrielles 
WHERE code = 'ZI_TEST_001'
ORDER BY date_debut_validite DESC;
```

**Résultat Attendu:**
- Nombre de zones augmenté de 1
- Nouvelle zone présente avec `est_actuel = true`
- `date_debut_validite` récente

```sql
-- 5.6 Vérifier que le changement est marqué comme traité
\c sigeti_node_db
SELECT id, table_name, operation, processed, changed_at
FROM public.cdc_log 
WHERE table_name = 'zones_industrielles'
AND processed = true
ORDER BY id DESC 
LIMIT 1;
```

**Résultat Attendu:**
- Entrée CDC marquée `processed = true`

---

### ✅ Test 6: Test de Modification (UPDATE)

**Objectif:** Vérifier le versioning SCD Type 2

```sql
-- 6.1 Connexion à la base source
\c sigeti_node_db

-- 6.2 Modification de la zone test
UPDATE zones_industrielles 
SET 
    libelle = 'Zone Test CDC MODIFIEE',
    superficie = 200.0,
    updated_at = NOW()
WHERE code = 'ZI_TEST_001';

-- 6.3 Vérifier la capture de la modification
SELECT 
    id, operation, processed,
    old_data->>'libelle' as ancien_libelle,
    new_data->>'libelle' as nouveau_libelle
FROM public.cdc_log 
WHERE table_name = 'zones_industrielles'
ORDER BY id DESC 
LIMIT 2;
```

**Résultat Attendu:**
- Nouvelle entrée avec `operation = 'UPDATE'`
- `old_data` et `new_data` avec les valeurs avant/après

```sql
-- 6.4 Traitement de la modification
\c sigeti_dwh
SELECT dwh.process_all_changes();

-- 6.5 Vérifier le versioning dans le DWH
SELECT 
    id_source, code, libelle, superficie, est_actuel,
    date_debut_validite, date_fin_validite
FROM dwh.dim_zones_industrielles 
WHERE code = 'ZI_TEST_001'
ORDER BY date_debut_validite;
```

**Résultat Attendu:**
- 2 enregistrements pour la même zone
- Premier enregistrement: `est_actuel = false`, `date_fin_validite` renseignée
- Deuxième enregistrement: `est_actuel = true`, `date_fin_validite` NULL

---

### ✅ Test 7: Test de Suppression (DELETE)

**Objectif:** Vérifier la gestion des suppressions

```sql
-- 7.1 Connexion à la base source
\c sigeti_node_db

-- 7.2 Suppression de la zone test
DELETE FROM zones_industrielles WHERE code = 'ZI_TEST_001';

-- 7.3 Vérifier la capture de la suppression
SELECT 
    id, operation, processed,
    old_data->>'code' as code_supprime,
    old_data->>'libelle' as libelle_supprime
FROM public.cdc_log 
WHERE table_name = 'zones_industrielles'
ORDER BY id DESC 
LIMIT 3;
```

**Résultat Attendu:**
- Nouvelle entrée avec `operation = 'DELETE'`
- `old_data` contient les données supprimées

```sql
-- 7.4 Traitement de la suppression
\c sigeti_dwh
SELECT dwh.process_all_changes();

-- 7.5 Vérifier que la zone est fermée dans le DWH
SELECT 
    id_source, code, libelle, est_actuel,
    date_debut_validite, date_fin_validite
FROM dwh.dim_zones_industrielles 
WHERE code = 'ZI_TEST_001'
ORDER BY date_debut_validite;
```

**Résultat Attendu:**
- Tous les enregistrements ont `est_actuel = false`
- Tous ont une `date_fin_validite` renseignée

---

### ✅ Test 8: Test des Jobs pgAgent

**Objectif:** Vérifier que les jobs automatiques fonctionnent

```sql
-- 8.1 Connexion à la base source
\c sigeti_node_db

-- 8.2 Vérifier l'état des jobs
SELECT 
    j.jobid, j.jobname, j.jobenabled, j.joblastrun, j.jobnextrun,
    js.jstname, s.jscname as schedule_name
FROM pgagent.pga_job j
LEFT JOIN pgagent.pga_jobstep js ON j.jobid = js.jstjobid
LEFT JOIN pgagent.pga_schedule s ON j.jobid = s.jscjobid
WHERE j.jobname LIKE '%CDC%'
ORDER BY j.jobid;

-- 8.3 Test manuel des fonctions des jobs
-- Test du nettoyage
SELECT cdc.cleanup_old_logs();

-- Test des statistiques
SELECT * FROM cdc.get_cdc_stats();
```

**Résultat Attendu:**
- Jobs `CDC_Cleanup_Job` et `CDC_Processing_Job` présents et activés
- Fonctions s'exécutent sans erreur

```sql
-- 8.4 Vérifier les logs d'exécution (s'il y en a)
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
```

---

### ✅ Test 9: Test d'Archivage CDC

**Objectif:** Vérifier le système d'archivage automatique

```sql
-- 9.1 Connexion à la base source
\c sigeti_node_db

-- 9.2 Simuler des données anciennes (pour test uniquement)
UPDATE public.cdc_log 
SET changed_at = NOW() - INTERVAL '35 days'
WHERE id = (SELECT MIN(id) FROM public.cdc_log WHERE processed = true);

-- 9.3 Vérifier l'état avant archivage
SELECT * FROM cdc.get_cdc_stats();

-- 9.4 Lancer l'archivage
SELECT cdc.cleanup_old_logs();

-- 9.5 Vérifier l'état après archivage
SELECT * FROM cdc.get_cdc_stats();

-- 9.6 Vérifier le contenu de l'archive
SELECT 
    id, table_name, operation, processed, changed_at, archived_at
FROM cdc.cdc_log_archive
ORDER BY archived_at DESC;
```

**Résultat Attendu:**
- Message de confirmation avec nombre d'entrées archivées
- Diminution des "CDC Traité (non archivé)"
- Augmentation des "CDC Archivé"
- Présence d'enregistrements dans `cdc_log_archive`

---

### ✅ Test 10: Test de Performance et Surveillance

**Objectif:** Vérifier les performances et outils de surveillance

```sql
-- 10.1 Statistiques de performance
\c sigeti_node_db

-- Taille des tables CDC
SELECT 
    schemaname, tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as taille
FROM pg_tables 
WHERE (schemaname = 'cdc' OR (schemaname = 'public' AND tablename = 'cdc_log'))
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- Statistiques des opérations CDC
SELECT 
    operation,
    COUNT(*) as nb_operations,
    COUNT(*) FILTER (WHERE processed = true) as traitees,
    COUNT(*) FILTER (WHERE processed = false) as non_traitees
FROM public.cdc_log 
GROUP BY operation
ORDER BY operation;
```

```sql
-- 10.2 Performance du DWH
\c sigeti_dwh

-- Répartition des données dans le DWH
SELECT 
    COUNT(*) as total_enregistrements,
    COUNT(*) FILTER (WHERE est_actuel = true) as actuels,
    COUNT(*) FILTER (WHERE est_actuel = false) as historiques,
    ROUND(
        COUNT(*) FILTER (WHERE est_actuel = false)::numeric / 
        COUNT(*)::numeric * 100, 2
    ) as pourcentage_historique
FROM dwh.dim_zones_industrielles;
```

**Résultat Attendu:**
- Tailles de tables raisonnables
- Répartition équilibrée des opérations
- Pourcentage d'historique cohérent

---

## 🔧 Scripts de Surveillance Automatique

### Script de Vérification Rapide

```sql
-- surveillance_rapide.sql
-- À exécuter régulièrement pour vérifier l'état du système

\c sigeti_node_db

SELECT 'ÉTAT CDC' as composant;
SELECT * FROM cdc.get_cdc_stats();

SELECT 'JOBS PGAGENT' as composant;
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
WHERE j.jobname LIKE '%CDC%';

\c sigeti_dwh

SELECT 'ÉTAT DWH' as composant;
SELECT 
    COUNT(*) as total_zones,
    COUNT(*) FILTER (WHERE est_actuel = true) as zones_actuelles
FROM dwh.dim_zones_industrielles;
```

### Script de Test Complet

```bash
#!/bin/bash
# test_complet_dwh.sh
# Script pour automatiser tous les tests

echo "🧪 DÉBUT DES TESTS ENTREPÔT DE DONNÉES SIGETI"
echo "=============================================="

# Test 1: Prérequis
echo "✅ Test 1: Vérification des prérequis..."
psql -U postgres -d sigeti_node_db -f test_1_prerequis.sql

# Test 2: Structure CDC  
echo "✅ Test 2: Structure CDC..."
psql -U postgres -d sigeti_node_db -f test_2_structure_cdc.sql

# Test 3: Structure DWH
echo "✅ Test 3: Structure DWH..."
psql -U postgres -d sigeti_dwh -f test_3_structure_dwh.sql

# Tests 4-7: Tests fonctionnels
echo "✅ Tests 4-7: Tests fonctionnels..."
psql -U postgres -d sigeti_node_db -f test_4_7_fonctionnels.sql

# Test 8: Jobs pgAgent
echo "✅ Test 8: Jobs pgAgent..."
psql -U postgres -d sigeti_node_db -f test_8_jobs.sql

# Test 9: Archivage
echo "✅ Test 9: Archivage..."
psql -U postgres -d sigeti_node_db -f test_9_archivage.sql

# Test 10: Performance
echo "✅ Test 10: Performance..."
psql -U postgres -d sigeti_node_db -f test_10_performance.sql

echo "🎉 TOUS LES TESTS TERMINÉS !"
```

---

## 📊 Résultats Attendus

### ✅ Critères de Succès

| Test | Critère de Succès |
|------|------------------|
| **Capture CDC** | Tous les INSERT/UPDATE/DELETE sont capturés |
| **Traitement** | `process_all_changes()` traite sans erreur |
| **Versioning** | SCD Type 2 fonctionne (historique préservé) |
| **Jobs** | pgAgent remplace le script Python |
| **Archivage** | Anciens logs archivés automatiquement |
| **Performance** | Traitement en < 5 secondes pour 1000 enregistrements |

### 🚨 Alertes à Surveiller

- **CDC non traités** : > 100 entrées non traitées
- **Jobs en échec** : Statut différent de 's' (succès)
- **Retard traitement** : Processing job pas exécuté depuis > 10 min
- **Retard nettoyage** : Cleanup job pas exécuté depuis > 25h
- **Taille excessive** : Tables CDC > 1GB

---

## 🔄 Procédure de Maintenance

### Hebdomadaire
1. Exécuter le script de surveillance rapide
2. Vérifier les logs d'erreurs pgAgent
3. Contrôler la croissance des tables CDC

### Mensuelle  
1. Exécuter tous les tests fonctionnels
2. Analyser les performances du DWH
3. Optimiser les index si nécessaire

### Trimestrielle
1. Tests complets de bout en bout
2. Vérification de l'intégrité des données
3. Mise à jour de la documentation

---

## 📞 Support et Dépannage

### Problèmes Courants

**Problème** : Jobs pgAgent ne s'exécutent pas
**Solution** : Vérifier que le service pgAgent est démarré

**Problème** : Erreur de connexion dblink  
**Solution** : Vérifier les paramètres de connexion dans `process_all_changes()`

**Problème** : CDC logs non traités
**Solution** : Vérifier que le job Processing fonctionne et relancer manuellement si nécessaire

### Commandes d'Urgence

```sql
-- Traitement manuel immédiat
\c sigeti_dwh
SELECT dwh.process_all_changes();

-- Nettoyage manuel immédiat
\c sigeti_node_db  
SELECT cdc.cleanup_old_logs();

-- Statistiques de diagnostic
SELECT * FROM cdc.get_cdc_stats();
```

---

**📝 Dernière mise à jour :** 25 octobre 2025  
**👨‍💻 Auteur :** Équipe DWH SIGETI  
**📧 Contact :** support-dwh@sigeti.com