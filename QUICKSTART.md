# 🚀 Guide de Démarrage Rapide - DWH SIGETI

## ⚡ Installation en 3 étapes

### 1️⃣ Configuration (2 minutes)
```batch
# Ouvrir config.ini et ajuster vos paramètres :
PGUSER=votre_utilisateur
PGPASSWORD=votre_mot_de_passe
PGHOST=votre_serveur
```

### 2️⃣ Déploiement (10-15 minutes)
```batch
# Déployer l'entrepôt complet
2_deploiement_complet.bat
```

### 3️⃣ Validation (3 minutes)
```batch
# Tester l'environnement
3_tests_environnement.bat
# Choisir Mode 1 (Test rapide)
```

## 🎯 Utilisation quotidienne

### ✅ Tests rapides quotidiens
```batch
3_tests_environnement.bat → Mode 1
```

### 🔧 Maintenance hebdomadaire  
```batch
4_maintenance.bat → Option 5 (Vacuum)
4_maintenance.bat → Option 7 (Nettoyage logs)
```

### 🔄 Redéploiement (si nécessaire)
```batch
1_reinitialisation.bat  # Reset complet
2_deploiement_complet.bat  # Redéploiement
```

## 🆘 En cas de problème

### ❌ Erreur de connexion
```batch
# Diagnostic automatique
4_maintenance.bat → Option 16
```

### ⚠️ Tests en échec
```batch
# Consulter les logs
dir logs\*.log

# Redéployer si nécessaire
1_reinitialisation.bat
2_deploiement_complet.bat
```

### 📞 Support
- Logs détaillés : `/logs`  
- Documentation complète : `README.md`
- Diagnostic automatique : Script 4, Option 16

---

**🎉 Félicitations !** Votre DWH SIGETI est prêt pour la production !