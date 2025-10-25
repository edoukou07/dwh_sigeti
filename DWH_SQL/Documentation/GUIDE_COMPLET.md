# 📚 DWH SIGETI - DOCUMENTATION UNIFIÉE
*Guide complet pour déploiement, tests et maintenance*

## 🚀 DÉMARRAGE RAPIDE

### ⚡ Déploiement automatique
```batch
# Windows
deploiement_automatique.bat

# Linux/Unix/macOS
chmod +x *.sh && ./deploiement_automatique.sh
```
**✅ Déploiement complet en 3-5 minutes !**

### ⚡ Tests automatiques  
```batch
# Windows
cd Documentation && executer_tests_complets.bat

# Linux/Unix  
./deploy_helper.sh test
```

### ⚡ Surveillance quotidienne
```sql
\i Documentation/surveillance_quotidienne.sql
```

---

## 📋 TABLE DES MATIÈRES

1. [🔧 Déploiement](#-déploiement)
2. [✅ Tests et Validation](#-tests-et-validation)  
3. [📊 Surveillance](#-surveillance)
4. [🏗️ Architecture](#️-architecture)
5. [🔧 Maintenance](#-maintenance)
6. [🆘 Dépannage](#-dépannage)

---

## 🔧 DÉPLOIEMENT

### Prérequis obligatoires
✅ PostgreSQL 13+ avec pgAgent  
✅ Bases `sigeti_node_db` et `sigeti_dwh` créées  
✅ Extension `dblink` configurée  
✅ Utilisateur postgres avec droits admin  

### Scripts de déploiement (7 essentiels)
```
Scripts/
├── cdc/
│   ├── CDC_01_configuration_initiale.sql    # Configuration CDC + triggers
│   ├── CDC_02_fonctions_essentielles.sql    # Fonctions get_cdc_stats(), process_changes()
│   ├── CDC_03_archivage_automatique.sql     # Archivage automatique
│   ├── CDC_04_jobs_pgagent.sql              # Jobs automatisés (remplace Python)
│   └── CDC_05_replication_dwh.sql           # Réplication CDC → DWH
├── schema/
│   └── DWH_01_structure_warehouse.sql       # Structure Data Warehouse
└── etl/
    └── DWH_02_creation_complete.sql         # Création complète DWH
```

### Ordre d'exécution (IMPÉRATIF)
```sql
-- Phase 1: CDC (sigeti_node_db)
\i Scripts/cdc/CDC_01_configuration_initiale.sql
\i Scripts/cdc/CDC_02_fonctions_essentielles.sql
\i Scripts/cdc/CDC_03_archivage_automatique.sql
\i Scripts/cdc/CDC_04_jobs_pgagent.sql

-- Phase 2: DWH (sigeti_dwh)  
\i Scripts/schema/DWH_01_structure_warehouse.sql
\i Scripts/etl/DWH_02_creation_complete.sql
\i Scripts/cdc/CDC_05_replication_dwh.sql
```

### Options de déploiement

#### Option 1: Automatique (RECOMMANDÉ)
| Plateforme | Commande |
|------------|----------|
| **Windows** | `deploiement_automatique.bat` |
| **Linux/Unix** | `./deploiement_automatique.sh` |
| **macOS** | `./deploiement_automatique.sh` |
| **WSL** | `./deploiement_automatique.sh` |

#### Option 2: Helper Linux/Unix
```bash
# Configuration interactive
./deploy_helper.sh config

# Vérification prérequis
./deploy_helper.sh prereq

# Déploiement
./deploy_helper.sh deploy
```

---

## ✅ TESTS ET VALIDATION

### Tests rapides (2 minutes)
```sql
-- 1. Vérifier CDC (sigeti_node_db)
SELECT * FROM cdc.get_cdc_stats();

-- 2. Vérifier jobs pgAgent
SELECT jobname, jobenabled FROM pgagent.pga_job WHERE jobname LIKE '%CDC%';

-- 3. Vérifier DWH (sigeti_dwh)
SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'dwh';

-- 4. Test connectivité dblink
SELECT dblink_connect('test', 'dbname=sigeti_node_db host=localhost');
SELECT dblink_disconnect('test');
```

### Tests complets automatisés (10 phases)
```bash
# Windows
cd Documentation
executer_tests_complets.bat

# Linux/Unix
./deploy_helper.sh test
```

#### Phases de tests couvertes
1. **Prérequis** - PostgreSQL, bases, extensions
2. **Structure CDC** - Schéma, triggers, tables
3. **Fonctions CDC** - get_cdc_stats(), process_changes()  
4. **Jobs pgAgent** - Processing + Cleanup automatiques
5. **Réplication** - CDC → DWH avec dblink
6. **Données DWH** - Tables dimensions et structure
7. **SCD Type 2** - Historique et versions
8. **Archivage** - Nettoyage automatique anciennes données
9. **Intégration** - Test bout-en-bout complet
10. **Performance** - Optimisations et index

### Test fonctionnel de bout-en-bout
```sql
-- 1. Insertion test (sigeti_node_db)
INSERT INTO zones_industrielles (code, nom) VALUES ('TEST_DEPLOY', 'Zone Test');

-- 2. Attendre traitement CDC (30 secondes)

-- 3. Vérifier réplication (sigeti_dwh)
SELECT * FROM dwh.dim_zones_industrielles 
WHERE code = 'TEST_DEPLOY' AND est_actuel = true;

-- 4. Nettoyage
DELETE FROM zones_industrielles WHERE code = 'TEST_DEPLOY';
```

---

## 📊 SURVEILLANCE

### Surveillance quotidienne (2 minutes)
```sql
-- Exécuter chaque matin
\i Documentation/surveillance_quotidienne.sql

-- Ou requête rapide
SELECT 
    (SELECT COUNT(*) FROM cdc_log WHERE processed = false) as non_traites,
    (SELECT COUNT(*) FROM pgagent.pga_job WHERE jobname LIKE '%CDC%' AND jobenabled) as jobs_actifs,
    (SELECT COUNT(*) FROM dwh.dim_zones_industrielles WHERE est_actuel = true) as zones_actuelles;
```

### Alertes système
| Condition | Alerte | Action |
|-----------|--------|--------|
| CDC non traité > 100 | 🔴 CRITIQUE | Vérifier jobs pgAgent |
| Jobs pgAgent désactivés | 🔴 CRITIQUE | Redémarrer pgAgent |
| Pas de traitement 24h | 🟡 ATTENTION | Vérifier logs PostgreSQL |
| DWH tables = 0 | 🔴 CRITIQUE | Redéployer DWH |

### Métriques de performance
```sql
-- Statistiques CDC temps-réel
SELECT 
    table_name,
    COUNT(*) as changements_24h,
    COUNT(*) FILTER (WHERE processed = false) as en_attente
FROM cdc_log 
WHERE changed_at >= NOW() - INTERVAL '24 hours'
GROUP BY table_name;

-- Performance jobs pgAgent
SELECT 
    j.jobname,
    j.joblastrun,
    EXTRACT(minutes FROM NOW() - j.joblastrun) as minutes_depuis_exec
FROM pgagent.pga_job j
WHERE j.jobname LIKE '%CDC%';
```

---

## 🏗️ ARCHITECTURE

### Change Data Capture (CDC)
- **Triggers PostgreSQL** sur tables sources (INSERT/UPDATE/DELETE)
- **Table cdc_log** centralisée avec métadonnées
- **Fonctions CDC** : get_cdc_stats(), process_changes()
- **Archivage automatique** des données anciennes

### pgAgent Jobs (remplace Python)
- **CDC Processing Job** : Traitement toutes les 5 minutes
- **CDC Cleanup Job** : Nettoyage quotidien à 2h00
- **Gestion d'erreurs** : Retry automatique + logging

### Data Warehouse (DWH)
- **Architecture en étoile** optimisée pour l'analyse
- **SCD Type 2** : Historique complet avec date_debut/date_fin
- **Dimensions** : zones_industrielles, lots, entreprises
- **Réplication temps-réel** via dblink

### Flux de données
```
Tables Source → Triggers → CDC Log → pgAgent Job → dblink → DWH (SCD Type 2)
     ↓              ↓           ↓           ↓            ↓
  INSERT/       Capture    Centralisé   Traitement   Historique
  UPDATE/       temps-      + Meta-     automatique   complet
  DELETE        réel        données     toutes 5min   conservé
```

---

## 🔧 MAINTENANCE

### Hebdomadaire (5 minutes)
```sql
-- Optimisation performances
VACUUM ANALYZE cdc_log;
VACUUM ANALYZE dwh.dim_zones_industrielles;

-- Statistiques à jour
ANALYZE cdc_log;
ANALYZE dwh.dim_zones_industrielles;
```

### Mensuelle (15 minutes)
```sql
-- Nettoyage avancé
REINDEX DATABASE sigeti_node_db;
REINDEX DATABASE sigeti_dwh;

-- Vérification intégrité
SELECT COUNT(*) FROM cdc_log WHERE processed = false;
SELECT COUNT(*) FROM dwh.dim_zones_industrielles WHERE est_actuel = true;
```

### Sauvegarde recommandée
```bash
# Sauvegarde mensuelle
pg_dump sigeti_node_db > backup_source_$(date +%Y%m%d).sql
pg_dump sigeti_dwh > backup_dwh_$(date +%Y%m%d).sql
```

### Calendrier de maintenance
| Fréquence | Tâches | Temps |
|-----------|--------|-------|
| **Quotidien** | Surveillance monitoring | 2 min |
| **Hebdomadaire** | Tests + optimisation | 5 min |
| **Mensuel** | Tests complets + sauvegarde | 15 min |
| **Semestriel** | Révision architecture | 1h |

---

## 🆘 DÉPANNAGE

### Erreurs courantes

#### "relation cdc_log does not exist"
```bash
# Cause: Script CDC_01 non exécuté
# Solution: 
psql -d sigeti_node_db -f Scripts/cdc/CDC_01_configuration_initiale.sql
```

#### "function get_cdc_stats() does not exist"  
```bash
# Cause: Script CDC_02 non exécuté
# Solution:
psql -d sigeti_node_db -f Scripts/cdc/CDC_02_fonctions_essentielles.sql
```

#### "pgAgent job failed"
```sql
-- Cause: Service pgAgent arrêté
-- Solution: Redémarrer pgAgent
SELECT * FROM pgagent.pga_joblog ORDER BY jlgstart DESC LIMIT 5;
-- Puis redémarrer le service pgAgent
```

#### "dblink connection failed"
```sql  
-- Cause: Extension dblink manquante
-- Solution:
CREATE EXTENSION IF NOT EXISTS dblink;
```

### Diagnostic système
```sql
-- Vérifier état complet
SELECT 
    'PostgreSQL' as composant,
    version() as info
UNION ALL
SELECT 
    'pgAgent',
    CASE WHEN COUNT(*) > 0 THEN 'Disponible' ELSE 'Non disponible' END
FROM pgagent.pga_job
UNION ALL
SELECT
    'dblink',
    CASE WHEN COUNT(*) > 0 THEN 'Installé' ELSE 'Non installé' END  
FROM pg_extension WHERE extname = 'dblink';
```

### Réinitialisation d'urgence
```sql
-- ⚠️ ATTENTION: Supprime toutes les données CDC et DWH

-- Nettoyage sigeti_node_db
DROP SCHEMA IF EXISTS cdc CASCADE;
DELETE FROM pgagent.pga_job WHERE jobname LIKE '%CDC%';

-- Nettoyage sigeti_dwh  
DROP SCHEMA IF EXISTS dwh CASCADE;

-- Puis redéployer complètement
```

### Scripts de diagnostic
```bash
# Windows
deploiement_automatique.bat  # Inclut validation

# Linux/Unix  
./deploy_helper.sh prereq    # Vérification prérequis
./deploy_helper.sh test      # Tests post-déploiement
```

---

## 📞 SUPPORT ET RESSOURCES

### Fichiers utiles
- **`surveillance_quotidienne.sql`** : Monitoring quotidien
- **`executer_tests_complets.bat`** : Tests Windows automatisés  
- **`deploy_helper.sh`** : Utilitaire Linux/Unix
- **Logs** : `deployment_*.log`, logs PostgreSQL

### En cas de problème
1. **Consulter** les logs PostgreSQL  
2. **Exécuter** surveillance_quotidienne.sql
3. **Vérifier** que tous les services sont démarrés
4. **Utiliser** les scripts de diagnostic
5. **Réinitialiser** si nécessaire avec les scripts d'urgence

### Métriques de succès
✅ **7 scripts** exécutés sans erreur  
✅ **2 jobs pgAgent** créés et activés  
✅ **CDC opérationnel** avec get_cdc_stats()  
✅ **DWH créé** avec tables dimensions  
✅ **Réplication fonctionnelle** CDC → DWH  
✅ **Tests passent** à 100%  

---
**Documentation unifiée** - 25 octobre 2025  
**Version** - Architecture optimisée avec pgAgent  
**Couverture** - Déploiement + Tests + Surveillance + Maintenance + Support