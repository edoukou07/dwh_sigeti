# 🏢 Data Warehouse SIGETI
*Système Intégré de Gestion des Terrains Industriels*

Data Warehouse moderne avec **Change Data Capture (CDC) automatisé** et **pgAgent** pour le traitement temps-réel.

## 🚀 DÉPLOIEMENT AUTOMATIQUE

### ⚡ Démarrage rapide (Windows)
```batch
cd "C:\Users\hynco\Desktop\DWH"
deploiement_automatique.bat
```

### ⚡ Démarrage rapide (Linux/Unix/macOS)
```bash
chmod +x *.sh
./deploiement_automatique.sh
```

**✅ Déploiement complet en 3-5 minutes !**

## 📁 STRUCTURE OPTIMISÉE

```
DWH/
├── 📋 Documentation/                    # Guides et tests complets
│   ├── GUIDE_DEPLOIEMENT.md            # Guide détaillé de déploiement  
│   ├── executer_tests_complets.bat     # Tests automatisés (Windows)
│   └── surveillance_quotidienne.sql    # Monitoring quotidien
├── 🔧 Scripts/ (7 scripts essentiels)
│   ├── cdc/                            # Change Data Capture
│   │   ├── CDC_01_configuration_initiale.sql
│   │   ├── CDC_02_fonctions_essentielles.sql
│   │   ├── CDC_03_archivage_automatique.sql
│   │   ├── CDC_04_jobs_pgagent.sql
│   │   └── CDC_05_replication_dwh.sql
│   ├── schema/
│   │   └── DWH_01_structure_warehouse.sql
│   └── etl/
│       └── DWH_02_creation_complete.sql
├── deploiement_automatique.bat         # Déploiement Windows
├── deploiement_automatique.sh          # Déploiement Linux/Unix
└── deploy_helper.sh                    # Utilitaire de configuration
```

## 🎯 ARCHITECTURE MODERNE

### 🔄 Change Data Capture (CDC) Automatisé
- **Capture temps-réel** : Triggers PostgreSQL sur tables sources
- **Traitement automatique** : Jobs pgAgent (remplace Python)  
- **Réplication intelligente** : CDC → DWH avec SCD Type 2
- **Archivage automatique** : Nettoyage des anciennes données

### 🏢 Data Warehouse (DWH)  
- **Structure en étoile** optimisée pour l'analyse
- **Dimensions SCD Type 2** : Historique complet des changements
- **Tables de faits** : Données transactionnelles agrégées  
- **Performance** : Index et optimisations intégrées

### 🤖 Automatisation complète
- **pgAgent Jobs** : Traitement et nettoyage automatiques
- **Surveillance** : Monitoring intégré avec alertes
- **Tests** : Validation automatique de bout-en-bout
- **Maintenance** : Scripts de surveillance quotidienne

## 📋 PRÉREQUIS

✅ **PostgreSQL 13+** avec pgAgent activé  
✅ **Bases de données** : `sigeti_node_db` et `sigeti_dwh` créées  
✅ **Extension dblink** configurée  
✅ **Utilisateur postgres** avec droits administrateur  

### Création des bases (si nécessaire)
```sql
CREATE DATABASE sigeti_node_db;
CREATE DATABASE sigeti_dwh;
CREATE EXTENSION IF NOT EXISTS dblink;
```

## 🎯 DÉPLOIEMENT DÉTAILLÉ

### Option 1: Automatique (RECOMMANDÉ)
```batch
# Windows
deploiement_automatique.bat

# Linux/Unix/macOS  
./deploiement_automatique.sh
```

### Option 2: Manuel (ordre strict)
```sql
-- Phase 1: CDC (dans sigeti_node_db)
\i Scripts/cdc/CDC_01_configuration_initiale.sql
\i Scripts/cdc/CDC_02_fonctions_essentielles.sql
\i Scripts/cdc/CDC_03_archivage_automatique.sql  
\i Scripts/cdc/CDC_04_jobs_pgagent.sql

-- Phase 2: DWH (dans sigeti_dwh)
\i Scripts/schema/DWH_01_structure_warehouse.sql
\i Scripts/etl/DWH_02_creation_complete.sql
\i Scripts/cdc/CDC_05_replication_dwh.sql
```

## ✅ VALIDATION POST-DÉPLOIEMENT

### Tests rapides (2 minutes)
```sql
-- Vérifier CDC (dans sigeti_node_db)
SELECT * FROM cdc.get_cdc_stats();

-- Vérifier jobs pgAgent
SELECT jobname, jobenabled FROM pgagent.pga_job WHERE jobname LIKE '%CDC%';

-- Vérifier DWH (dans sigeti_dwh)  
SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'dwh';
```

### Tests automatisés complets
```batch
# Windows
cd Documentation
executer_tests_complets.bat

# Linux/Unix
./deploy_helper.sh test
```

### Test fonctionnel de bout-en-bout
```sql
-- Insertion test (sigeti_node_db)
INSERT INTO zones_industrielles (code, nom) VALUES ('TEST_001', 'Zone Test');

-- Attendre 30 secondes puis vérifier réplication (sigeti_dwh)
SELECT * FROM dwh.dim_zones_industrielles WHERE code = 'TEST_001';

-- Nettoyage
DELETE FROM zones_industrielles WHERE code = 'TEST_001';
```

## 📊 SURVEILLANCE ET MAINTENANCE

### Surveillance quotidienne (2 minutes)
```sql
\i Documentation/surveillance_quotidienne.sql
```

### Maintenance hebdomadaire (5 minutes)
```sql
-- Optimisation des performances
VACUUM ANALYZE cdc_log;
VACUUM ANALYZE dwh.dim_zones_industrielles;
```

### Composants surveillés
✅ **CDC automatique** : Triggers + Table de log + Archivage  
✅ **Jobs pgAgent** : Processing toutes les 5 minutes + Cleanup quotidien  
✅ **Réplication DWH** : SCD Type 2 + Mise à jour dimensions  
✅ **Performances** : Index optimisés + Statistiques à jour  

## 📚 DOCUMENTATION UNIFIÉE

### 📖 Guide principal
- **`Documentation/GUIDE_COMPLET.md`** : 📚 **Documentation complète unifiée**  
  *Déploiement + Tests + Surveillance + Maintenance + Dépannage*

### 🔧 Outils spécialisés
- **`Documentation/Guide_Tests_DWH_SIGETI.md`** : Procédures techniques détaillées
- **`Documentation/surveillance_quotidienne.sql`** : Monitoring quotidien avec alertes
- **`Documentation/executer_tests_complets.bat`** : Tests automatisés complets

### 📋 Navigation
- **`Documentation/INDEX.md`** : Index de toute la documentation

## 🎯 ANALYSE DES DONNÉES

### Dimensions disponibles (SCD Type 2)
- **Zones industrielles** : Code, nom, superficie, statut avec historique
- **Lots** : Référence, zone, superficie, prix avec évolutions  
- **Entreprises** : Informations complètes avec changements trackés

### Requêtes analytiques typiques
```sql
-- Évolution des zones industrielles
SELECT code, nom, date_debut, date_fin, est_actuel 
FROM dwh.dim_zones_industrielles 
WHERE code = 'ZI_001' ORDER BY date_debut;

-- Statistiques temps-réel
SELECT COUNT(*) as total_zones_actives
FROM dwh.dim_zones_industrielles 
WHERE est_actuel = true;
```

## 🚀 AVANTAGES DE CETTE SOLUTION

✅ **Déploiement automatique** : 3-5 minutes au lieu de heures manuelles  
✅ **Zero-maintenance** : pgAgent remplace les scripts Python  
✅ **Temps-réel** : CDC avec traitement toutes les 5 minutes  
✅ **Historique complet** : SCD Type 2 pour toutes les dimensions  
✅ **Surveillance intégrée** : Monitoring et alertes automatiques  
✅ **Tests validés** : 10 phases de tests automatisés  
✅ **Multi-plateforme** : Windows + Linux/Unix avec scripts dédiés  
✅ **Production-ready** : Architecture robuste et optimisée  

---
**Dernière mise à jour** : 25 octobre 2025  
**Version** : 2.0 - Architecture optimisée avec pgAgent  
**Support** : Déploiement automatique Windows + Linux/Unix