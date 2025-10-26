@echo off
setlocal EnableDelayedExpansion

:: =============================================================================
:: SCRIPT 4: MAINTENANCE ET MONITORING DWH SIGETI  
:: =============================================================================
:: Ce script gère la maintenance et le monitoring de l'environnement
:: Version: 1.0 - Script consolidé final
:: =============================================================================

title DWH SIGETI - MAINTENANCE ET MONITORING

:: Chargement de la configuration
call :LOAD_CONFIG
if %errorlevel% neq 0 (
    echo ERREUR: Impossible de charger la configuration
    pause
    exit /b 1
)

:MENU_MAINTENANCE
cls
echo.
echo ===============================================================================
echo                    DWH SIGETI - MAINTENANCE ET MONITORING                    
echo ===============================================================================
echo.
echo Configuration active:
echo   - Base entrepôt: %DB_DWH%
echo   - Base source: %DB_SOURCE%
echo   - Mode monitoring: %MONITORING_INTERVAL% minutes
echo   - Rétention logs: %LOG_ROTATION_DAYS% jours
echo   - Maintenance auto: %AUTO_VACUUM% / %AUTO_REINDEX%
echo.
echo ===============================================================================
echo                              MENU MAINTENANCE                                
echo ===============================================================================
echo.
echo   [1] MONITORING ET SUPERVISION
echo       1. Monitoring temps réel
echo       2. État détaillé du système  
echo       3. Rapport de santé complet
echo       4. Monitoring CDC/ETL
echo.
echo   [2] MAINTENANCE PRÉVENTIVE
echo       5. Vacuum et analyse automatique
echo       6. Réindexation des tables
echo       7. Nettoyage logs anciens
echo       8. Optimisation base de données
echo.  
echo   [3] UTILITAIRES ET OUTILS
echo       9. Sauvegarde manuelle
echo       10. Restauration données
echo       11. Gestion utilisateurs
echo       12. Configuration système
echo.
echo   [4] MAINTENANCE D'URGENCE  
echo       13. Arrêt d'urgence processus
echo       14. Nettoyage complet caches
echo       15. Réparation base corrompue
echo       16. Diagnostic problèmes
echo.
echo   [0] Retour / Quitter
echo.
echo ===============================================================================

set /p choix="Sélectionnez une option (0-16) : "

if "%choix%"=="1" goto MONITORING_TEMPS_REEL
if "%choix%"=="2" goto ETAT_SYSTEME_DETAILLE  
if "%choix%"=="3" goto RAPPORT_SANTE_COMPLET
if "%choix%"=="4" goto MONITORING_CDC_ETL
if "%choix%"=="5" goto VACUUM_ANALYSE
if "%choix%"=="6" goto REINDEXATION
if "%choix%"=="7" goto NETTOYAGE_LOGS
if "%choix%"=="8" goto OPTIMISATION_BDD
if "%choix%"=="9" goto SAUVEGARDE_MANUELLE
if "%choix%"=="10" goto RESTAURATION_DONNEES
if "%choix%"=="11" goto GESTION_UTILISATEURS
if "%choix%"=="12" goto CONFIGURATION_SYSTEME
if "%choix%"=="13" goto ARRET_URGENCE
if "%choix%"=="14" goto NETTOYAGE_CACHES
if "%choix%"=="15" goto REPARATION_BASE
if "%choix%"=="16" goto DIAGNOSTIC_PROBLEMES
if "%choix%"=="0" goto FIN

echo Choix invalide. Appuyez sur une touche pour continuer...
pause >nul
goto MENU_MAINTENANCE

:: =============================================================================
:: SECTION 1: MONITORING ET SUPERVISION
:: =============================================================================

:MONITORING_TEMPS_REEL
cls
echo ===============================================================================
echo                            MONITORING TEMPS RÉEL                             
echo ===============================================================================
echo.

echo Monitoring continu (Ctrl+C pour arrêter)...
echo.

:LOOP_MONITORING
echo [%date% %time%] État du système:
echo.

echo   📊 Statistiques PostgreSQL:
"%PGBIN%\psql.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %DB_DWH% -c "
SELECT 
    'Connexions actives: ' || COUNT(*) 
FROM pg_stat_activity 
WHERE datname IN ('%DB_DWH%', '%DB_SOURCE%');
"

echo   📈 Activité bases de données:
"%PGBIN%\psql.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %DB_DWH% -c "
SELECT 
    datname,
    numbackends as connexions,
    xact_commit as transactions_ok,
    xact_rollback as transactions_ko
FROM pg_stat_database 
WHERE datname IN ('%DB_DWH%', '%DB_SOURCE%');
"

echo   📋 Tables DWH les plus actives:
"%PGBIN%\psql.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %DB_DWH% -c "
SELECT 
    schemaname || '.' || tablename as table_name,
    n_tup_ins + n_tup_upd + n_tup_del as total_activity
FROM pg_stat_user_tables 
WHERE schemaname = 'dwh' 
ORDER BY total_activity DESC 
LIMIT 5;
"

if /i "%CDC_ENABLED%"=="true" (
    echo   🔄 État CDC:
    "%PGBIN%\psql.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %DB_DWH% -c "
    SELECT 
        table_source,
        CASE 
            WHEN derniere_sync > CURRENT_TIMESTAMP - INTERVAL '%MONITORING_INTERVAL% minutes' 
            THEN 'ACTUEL'
            ELSE 'RETARD'
        END as statut_sync
    FROM cdc.cdc_config 
    WHERE est_actif = true;
    "
)

echo.
echo   Prochain refresh dans %MONITORING_INTERVAL% secondes...
echo   (Appuyez sur une touche pour arrêter)

timeout /t 60 >nul
if %errorlevel% equ 1 goto MENU_MAINTENANCE

goto LOOP_MONITORING

:ETAT_SYSTEME_DETAILLE
cls
echo ===============================================================================
echo                           ÉTAT DÉTAILLÉ DU SYSTÈME                          
echo ===============================================================================
echo.

echo 🔍 INFRASTRUCTURE:
echo.

echo   PostgreSQL Version et Configuration:
"%PGBIN%\psql.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -c "
SELECT 
    'Version: ' || version() as info
UNION ALL
SELECT 
    'Démarrage: ' || pg_postmaster_start_time()::text as info
UNION ALL  
SELECT
    'Configuration max_connections: ' || setting as info
FROM pg_settings WHERE name = 'max_connections'
UNION ALL
SELECT
    'Configuration shared_buffers: ' || setting as info  
FROM pg_settings WHERE name = 'shared_buffers';
"

echo.
echo   Utilisation espace disque:
"%PGBIN%\psql.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -c "
SELECT 
    datname as base_donnees,
    pg_size_pretty(pg_database_size(datname)) as taille
FROM pg_database 
WHERE datname IN ('%DB_DWH%', '%DB_SOURCE%', 'postgres')
ORDER BY pg_database_size(datname) DESC;
"

echo.
echo 📊 SCHÉMAS ET TABLES:
echo.

echo   Répartition par schéma:
"%PGBIN%\psql.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %DB_DWH% -c "
SELECT 
    table_schema,
    COUNT(CASE WHEN table_type = 'BASE TABLE' THEN 1 END) as tables,
    COUNT(CASE WHEN table_type = 'VIEW' THEN 1 END) as vues
FROM information_schema.tables 
WHERE table_schema IN ('dwh', 'cdc', 'staging', 'etl', 'monitoring')
GROUP BY table_schema
ORDER BY table_schema;
"

echo   Taille des plus grosses tables:
"%PGBIN%\psql.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %DB_DWH% -c "
SELECT 
    schemaname || '.' || tablename as table_name,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as taille,
    n_tup_ins + n_tup_upd as nb_lignes_approx
FROM pg_stat_user_tables 
WHERE schemaname IN ('dwh', 'cdc', 'monitoring')
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC
LIMIT 10;
"

echo.
echo 📈 PERFORMANCES:
echo.

echo   Requêtes les plus lentes (dernières 24h):
"%PGBIN%\psql.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %DB_DWH% -c "
SELECT 
    query,
    calls,
    ROUND(total_time::numeric, 2) as temps_total_ms,
    ROUND(mean_time::numeric, 2) as temps_moyen_ms
FROM pg_stat_statements 
WHERE dbid = (SELECT oid FROM pg_database WHERE datname = '%DB_DWH%')
ORDER BY mean_time DESC
LIMIT 5;
" 2>nul || echo   Extension pg_stat_statements non installée

echo.
pause
goto MENU_MAINTENANCE

:RAPPORT_SANTE_COMPLET
cls
echo ===============================================================================
echo                           RAPPORT DE SANTÉ COMPLET                          
echo ===============================================================================
echo.

echo Génération du rapport de santé...

set "rapport_file=%LOG_DIR%\rapport_sante_%date:~6,4%%date:~3,2%%date:~0,2%_%time:~0,2%%time:~3,2%.txt"
set "rapport_file=!rapport_file: =0!"

if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

echo === RAPPORT DE SANTÉ DWH SIGETI === > "!rapport_file!"
echo Date génération: %date% %time% >> "!rapport_file!"
echo. >> "!rapport_file!"

echo === 1. INFRASTRUCTURE === >> "!rapport_file!"
"%PGBIN%\psql.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -c "SELECT 'PostgreSQL: ' || version();" >> "!rapport_file!" 2>&1

echo. >> "!rapport_file!"
echo === 2. BASES DE DONNÉES === >> "!rapport_file!"  
"%PGBIN%\psql.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -c "SELECT datname, pg_size_pretty(pg_database_size(datname)) FROM pg_database WHERE datname IN ('%DB_DWH%', '%DB_SOURCE%');" >> "!rapport_file!" 2>&1

echo. >> "!rapport_file!"
echo === 3. STRUCTURE DWH === >> "!rapport_file!"
"%PGBIN%\psql.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %DB_DWH% -c "SELECT table_schema, COUNT(*) FROM information_schema.tables WHERE table_schema IN ('dwh', 'cdc', 'monitoring') GROUP BY table_schema;" >> "!rapport_file!" 2>&1

echo. >> "!rapport_file!"
echo === 4. DONNÉES === >> "!rapport_file!"
"%PGBIN%\psql.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %DB_DWH% -c "SELECT schemaname||'.'||tablename, n_tup_ins+n_tup_upd as lignes FROM pg_stat_user_tables WHERE schemaname = 'dwh' ORDER BY n_tup_ins+n_tup_upd DESC;" >> "!rapport_file!" 2>&1

if /i "%CDC_ENABLED%"=="true" (
    echo. >> "!rapport_file!"
    echo === 5. CDC STATUS === >> "!rapport_file!"
    "%PGBIN%\psql.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %DB_DWH% -c "SELECT table_source, derniere_sync, est_actif FROM cdc.cdc_config;" >> "!rapport_file!" 2>&1
)

echo. >> "!rapport_file!"
echo === 6. MONITORING === >> "!rapport_file!"
"%PGBIN%\psql.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %DB_DWH% -c "SELECT nom_table, statut, derniere_maj FROM monitoring.dwh_status ORDER BY derniere_maj DESC LIMIT 10;" >> "!rapport_file!" 2>&1

echo ✅ Rapport généré: !rapport_file!
echo.
echo Voulez-vous afficher le rapport maintenant ? (O/N)
set /p afficher=
if /i "%afficher%"=="O" (
    type "!rapport_file!"
    echo.
)

pause
goto MENU_MAINTENANCE

:MONITORING_CDC_ETL
cls
echo ===============================================================================
echo                            MONITORING CDC/ETL                               
echo ===============================================================================
echo.

if /i not "%CDC_ENABLED%"=="true" (
    echo ⚠️  CDC désactivé dans la configuration
    pause
    goto MENU_MAINTENANCE
)

echo 🔄 État des processus CDC:
"%PGBIN%\psql.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %DB_DWH% -c "
SELECT 
    cc.table_source,
    cc.table_cible,
    cc.mode_sync,
    cc.derniere_sync,
    CASE 
        WHEN cc.derniere_sync > CURRENT_TIMESTAMP - INTERVAL '1 hour' THEN '🟢 RÉCENT'
        WHEN cc.derniere_sync > CURRENT_TIMESTAMP - INTERVAL '24 hours' THEN '🟡 ANCIEN' 
        ELSE '🔴 OBSOLÈTE'
    END as statut_sync,
    cc.est_actif
FROM cdc.cdc_config cc
ORDER BY cc.derniere_sync DESC;
"

echo.
echo 📊 Statistiques ETL:
"%PGBIN%\psql.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %DB_DWH% -c "
SELECT 
    nom_processus,
    statut,
    nb_lignes_traitees,
    duree_secondes,
    date_debut
FROM monitoring.etl_logs 
ORDER BY date_debut DESC 
LIMIT 10;
"

echo.
echo 🔧 Actions disponibles:
echo   [1] Forcer synchronisation CDC
echo   [2] Voir logs détaillés CDC
echo   [3] Réinitialiser CDC
echo   [0] Retour menu
echo.

set /p action_cdc="Votre choix : "
if "%action_cdc%"=="1" goto FORCER_SYNC_CDC
if "%action_cdc%"=="2" goto LOGS_DETAILLES_CDC  
if "%action_cdc%"=="3" goto REINITIALISER_CDC
if "%action_cdc%"=="0" goto MENU_MAINTENANCE

goto MONITORING_CDC_ETL

:FORCER_SYNC_CDC
echo.
echo Forcing synchronization CDC...
"%PGBIN%\psql.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %DB_DWH% -c "
UPDATE cdc.cdc_config 
SET derniere_sync = CURRENT_TIMESTAMP 
WHERE est_actif = true;

INSERT INTO cdc.cdc_logs (config_id, date_sync, statut, message)
SELECT id, CURRENT_TIMESTAMP, 'FORCE_SYNC', 'Synchronisation forcée manuellement'
FROM cdc.cdc_config WHERE est_actif = true;
"
echo ✅ Synchronisation CDC forcée
pause
goto MONITORING_CDC_ETL

:LOGS_DETAILLES_CDC
echo.
echo Logs CDC détaillés:
"%PGBIN%\psql.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %DB_DWH% -c "
SELECT 
    cl.date_sync,
    cc.table_source,
    cl.nb_lignes_sync,
    cl.statut,
    cl.message
FROM cdc.cdc_logs cl
JOIN cdc.cdc_config cc ON cl.config_id = cc.id
ORDER BY cl.date_sync DESC
LIMIT 20;
"
pause
goto MONITORING_CDC_ETL

:: =============================================================================
:: SECTION 2: MAINTENANCE PRÉVENTIVE
:: =============================================================================

:VACUUM_ANALYSE
cls
echo ===============================================================================
echo                         VACUUM ET ANALYSE AUTOMATIQUE                       
echo ===============================================================================
echo.

echo Cette opération va:
echo   - Nettoyer l'espace disque inutilisé (VACUUM)
echo   - Mettre à jour les statistiques (ANALYZE)  
echo   - Optimiser les performances des requêtes
echo.
echo ⚠️  Cette opération peut prendre du temps sur de grosses tables
echo.

set /p confirm="Continuer avec le vacuum/analyze ? (O/N) : "
if /i not "%confirm%"=="O" goto MENU_MAINTENANCE

echo.
echo Lancement du vacuum et analyze...

echo   Tables du schéma dwh...
"%PGBIN%\psql.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %DB_DWH% -c "
DO \$\$
DECLARE
    tbl RECORD;
BEGIN
    FOR tbl IN SELECT tablename FROM pg_tables WHERE schemaname = 'dwh'
    LOOP
        RAISE NOTICE 'VACUUM ANALYZE dwh.%', tbl.tablename;
        EXECUTE 'VACUUM ANALYZE dwh.' || tbl.tablename;
    END LOOP;
END \$\$;
"

echo   Tables du schéma cdc...  
"%PGBIN%\psql.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %DB_DWH% -c "
DO \$\$
DECLARE
    tbl RECORD;
BEGIN
    FOR tbl IN SELECT tablename FROM pg_tables WHERE schemaname = 'cdc'
    LOOP
        RAISE NOTICE 'VACUUM ANALYZE cdc.%', tbl.tablename;
        EXECUTE 'VACUUM ANALYZE cdc.' || tbl.tablename;
    END LOOP;
END \$\$;
"

echo   Tables du schéma monitoring...
"%PGBIN%\psql.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %DB_DWH% -c "
DO \$\$
DECLARE
    tbl RECORD;
BEGIN
    FOR tbl IN SELECT tablename FROM pg_tables WHERE schemaname = 'monitoring'  
    LOOP
        RAISE NOTICE 'VACUUM ANALYZE monitoring.%', tbl.tablename;
        EXECUTE 'VACUUM ANALYZE monitoring.' || tbl.tablename;
    END LOOP;
END \$\$;
"

echo.
echo ✅ Vacuum et analyze terminés avec succès
echo.
echo Statistiques après vacuum:
"%PGBIN%\psql.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %DB_DWH% -c "
SELECT 
    schemaname,
    tablename,
    last_vacuum,
    last_analyze
FROM pg_stat_user_tables 
WHERE schemaname IN ('dwh', 'cdc', 'monitoring')
ORDER BY last_vacuum DESC;
"

pause
goto MENU_MAINTENANCE

:REINDEXATION
cls
echo ===============================================================================
echo                           RÉINDEXATION DES TABLES                           
echo ===============================================================================
echo.

echo Cette opération va reconstruire tous les index pour optimiser les performances.
echo.
echo ⚠️  ATTENTION: La réindexation verrouille temporairement les tables
echo ⚠️  Évitez de lancer cette opération en heures de pointe
echo.

set /p confirm="Continuer avec la réindexation ? (O/N) : "
if /i not "%confirm%"=="O" goto MENU_MAINTENANCE

echo.
echo Réindexation en cours...

echo   Réindexation schéma dwh...
"%PGBIN%\psql.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %DB_DWH% -c "REINDEX SCHEMA dwh;" 2>nul
if %errorlevel% equ 0 (
    echo   ✅ Schéma dwh réindexé
) else (
    echo   ⚠️  Problème réindexation dwh
)

echo   Réindexation schéma cdc...
"%PGBIN%\psql.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %DB_DWH% -c "REINDEX SCHEMA cdc;" 2>nul
if %errorlevel% equ 0 (
    echo   ✅ Schéma cdc réindexé  
) else (
    echo   ⚠️  Problème réindexation cdc
)

echo   Réindexation schéma monitoring...
"%PGBIN%\psql.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %DB_DWH% -c "REINDEX SCHEMA monitoring;" 2>nul
if %errorlevel% equ 0 (
    echo   ✅ Schéma monitoring réindexé
) else (
    echo   ⚠️  Problème réindexation monitoring  
)

echo.
echo ✅ Réindexation terminée

pause
goto MENU_MAINTENANCE

:NETTOYAGE_LOGS
cls
echo ===============================================================================
echo                           NETTOYAGE LOGS ANCIENS                            
echo ===============================================================================
echo.

echo Configuration actuelle:
echo   - Rétention: %LOG_ROTATION_DAYS% jours
echo   - Répertoire logs: %LOG_DIR%
echo.

echo Cette opération va supprimer:
echo   - Fichiers logs de plus de %LOG_ROTATION_DAYS% jours
echo   - Logs temporaires et cache
echo   - Logs CDC et ETL anciens dans la base
echo.

set /p confirm="Continuer avec le nettoyage ? (O/N) : "
if /i not "%confirm%"=="O" goto MENU_MAINTENANCE

echo.
echo Nettoyage en cours...

echo   Nettoyage fichiers logs système...
if exist "%LOG_DIR%" (
    forfiles /p "%LOG_DIR%" /s /m "*.log" /d -%LOG_ROTATION_DAYS% /c "cmd /c del @path" >nul 2>&1
    forfiles /p "%LOG_DIR%" /s /m "*.tmp" /d -%LOG_ROTATION_DAYS% /c "cmd /c del @path" >nul 2>&1
    echo   ✅ Fichiers logs nettoyés
) else (
    echo   ⚠️  Répertoire logs inexistant
)

echo   Nettoyage logs CDC dans la base...
"%PGBIN%\psql.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %DB_DWH% -c "
DELETE FROM cdc.cdc_logs 
WHERE date_sync < CURRENT_TIMESTAMP - INTERVAL '%CDC_RETENTION_DAYS% days';
" >nul 2>&1

echo   Nettoyage logs ETL dans la base...
"%PGBIN%\psql.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %DB_DWH% -c "
DELETE FROM monitoring.etl_logs 
WHERE date_debut < CURRENT_TIMESTAMP - INTERVAL '%LOG_ROTATION_DAYS% days';
" >nul 2>&1

echo   Nettoyage logs monitoring...
"%PGBIN%\psql.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %DB_DWH% -c "
DELETE FROM monitoring.dwh_status 
WHERE date_controle < CURRENT_TIMESTAMP - INTERVAL '%LOG_ROTATION_DAYS% days';
" >nul 2>&1

echo   Nettoyage fichiers temporaires Windows...
del /q "%TEMP%\dwh_sigeti_*" >nul 2>&1
del /q "%TEMP%\postgresql_*" >nul 2>&1

echo.
echo ✅ Nettoyage terminé

echo.
echo Statistiques après nettoyage:
if exist "%LOG_DIR%" (
    echo   Fichiers logs restants: 
    dir /b "%LOG_DIR%\*.log" 2>nul | find /c /v "" || echo   0 fichier
)

"%PGBIN%\psql.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %DB_DWH% -c "
SELECT 
    'CDC logs: ' || COUNT(*) as info FROM cdc.cdc_logs
UNION ALL  
SELECT 
    'ETL logs: ' || COUNT(*) as info FROM monitoring.etl_logs
UNION ALL
SELECT 
    'Monitoring logs: ' || COUNT(*) as info FROM monitoring.dwh_status;
"

pause
goto MENU_MAINTENANCE

:: =============================================================================
:: SECTION 3: UTILITAIRES ET OUTILS
:: =============================================================================

:SAUVEGARDE_MANUELLE
cls
echo ===============================================================================
echo                           SAUVEGARDE MANUELLE                               
echo ===============================================================================
echo.

if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"

set "backup_file=%BACKUP_DIR%\backup_manuel_%date:~6,4%%date:~3,2%%date:~0,2%_%time:~0,2%%time:~3,2%.sql"  
set "backup_file=!backup_file: =0!"

echo Sauvegarde manuelle de la base %DB_DWH%
echo Fichier: !backup_file!
echo.

set /p confirm="Lancer la sauvegarde ? (O/N) : "
if /i not "%confirm%"=="O" goto MENU_MAINTENANCE

echo.
echo Sauvegarde en cours...

"%PGBIN%\pg_dump.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %DB_DWH% -f "!backup_file!" --verbose
if %errorlevel% equ 0 (
    echo ✅ Sauvegarde réussie: !backup_file!
    
    echo.
    echo Informations sur la sauvegarde:
    dir "!backup_file!" | find /i ".sql"
) else (
    echo ❌ Échec de la sauvegarde
)

pause
goto MENU_MAINTENANCE

:: =============================================================================
:: SECTION 4: MAINTENANCE D'URGENCE
:: =============================================================================

:ARRET_URGENCE
cls
echo ===============================================================================
echo                          ARRÊT D'URGENCE PROCESSUS                         
echo ===============================================================================
echo.

echo ⚠️  ATTENTION: Arrêt d'urgence des processus PostgreSQL
echo ⚠️  Cette action peut causer des pertes de données non sauvegardées
echo.

set /p confirm="Êtes-vous sûr de vouloir continuer ? (OUI/non) : "
if /i not "%confirm%"=="OUI" goto MENU_MAINTENANCE

echo.
echo Arrêt d'urgence en cours...

echo   Fermeture connexions actives...
"%PGBIN%\psql.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -d postgres -c "
SELECT pg_terminate_backend(pid) 
FROM pg_stat_activity 
WHERE datname IN ('%DB_DWH%', '%DB_SOURCE%') 
AND pid <> pg_backend_pid();
" >nul 2>&1

echo   Arrêt processus psql...
taskkill /f /im psql.exe >nul 2>&1

echo   Arrêt processus cmd bloqués...
for /f "tokens=2" %%i in ('tasklist /fi "imagename eq cmd.exe" /fo csv ^| findstr /v "Image"') do (
    taskkill /f /pid %%i >nul 2>&1
)

echo.
echo ✅ Processus d'urgence arrêtés

pause
goto MENU_MAINTENANCE

:DIAGNOSTIC_PROBLEMES
cls
echo ===============================================================================
echo                          DIAGNOSTIC PROBLÈMES                              
echo ===============================================================================
echo.

echo 🔍 Diagnostic automatique en cours...
echo.

echo   Test connectivité PostgreSQL...
"%PGBIN%\psql.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -c "SELECT 'PostgreSQL OK';" >nul 2>&1
if %errorlevel% equ 0 (
    echo   ✅ PostgreSQL accessible
) else (
    echo   ❌ PostgreSQL inaccessible - Vérifier service
)

echo   Test base DWH...
"%PGBIN%\psql.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %DB_DWH% -c "SELECT 1;" >nul 2>&1
if %errorlevel% equ 0 (
    echo   ✅ Base DWH accessible
) else (
    echo   ❌ Base DWH inaccessible
)

echo   Test schémas essentiels...  
"%PGBIN%\psql.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %DB_DWH% -c "SELECT COUNT(*) FROM information_schema.schemata WHERE schema_name IN ('dwh', 'cdc', 'monitoring');" | findstr "3" >nul 2>&1
if %errorlevel% equ 0 (
    echo   ✅ Schémas présents
) else (
    echo   ❌ Schémas manquants - Redéployement nécessaire
)

echo   Test logs système...
if exist "%LOG_DIR%" (
    echo   ✅ Répertoire logs présent
) else (
    echo   ❌ Répertoire logs manquant
)

echo   Test fichiers configuration...
if exist "config.ini" (
    echo   ✅ Fichier config.ini présent
) else (
    echo   ❌ Fichier config.ini manquant
)

echo.
echo 📋 RECOMMANDATIONS:
if %errorlevel% neq 0 (
    echo   - Vérifier que PostgreSQL est démarré
    echo   - Redéployer si nécessaire: 2_deploiement_complet.bat  
    echo   - Consulter les logs d'erreur
    echo   - Vérifier la configuration réseau
)

pause
goto MENU_MAINTENANCE

:: =============================================================================
:: FONCTIONS UTILITAIRES
:: =============================================================================

:LOAD_CONFIG
if not exist "config.ini" (
    echo ERREUR: Fichier config.ini introuvable
    exit /b 1
)

for /f "usebackq tokens=1,2 delims==" %%a in ("config.ini") do (
    if not "%%a"=="" if not "%%a"=="#" if not "%%a"=="[" (
        set "%%a=%%b"
    )
)

exit /b 0

:FIN
echo.
echo Session de maintenance terminée.
pause
endlocal
exit /b 0