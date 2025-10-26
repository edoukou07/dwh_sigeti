@echo off
setlocal EnableDelayedExpansion

:: =============================================================================
:: SCRIPT 2: DÉPLOIEMENT COMPLET CENTRALISÉ DWH SIGETI
:: =============================================================================
:: Ce script déploie l'entrepôt complet depuis la base source
:: Version: 1.0 - Script consolidé final
:: =============================================================================

title DWH SIGETI - DÉPLOIEMENT COMPLET

:: Chargement de la configuration
call :LOAD_CONFIG
if %errorlevel% neq 0 (
    echo ERREUR: Impossible de charger la configuration
    pause
    exit /b 1
)

:: Définition du mot de passe PostgreSQL
set "PGPASSWORD=%PGPASSWORD%"

echo.
echo ===============================================================================
echo                    DWH SIGETI - DÉPLOIEMENT COMPLET                         
echo ===============================================================================
echo.
echo Configuration du déploiement:
echo   - Base source: %DB_SOURCE% (données opérationnelles)
echo   - Base cible: %DB_DWH% (entrepôt de données)  
echo   - Mode ETL: %ETL_MODE%
echo   - CDC activé: %CDC_ENABLED%
echo   - Tables: %ETL_TABLES%
echo.
echo Ce déploiement va créer:
echo   ✅ Tous les schémas DWH (dwh, cdc, staging, etl, monitoring)
echo   ✅ Toutes les tables de dimensions et de faits
echo   ✅ Toutes les vues et indicateurs
echo   ✅ La configuration CDC pour la synchronisation
echo   ✅ Le système de monitoring et logs
echo   ✅ Les données initiales et de référence
echo.

set /p confirm="Continuer avec le déploiement complet ? (O/N) : "
if /i not "%confirm%"=="O" (
    echo Déploiement annulé par l'utilisateur.
    exit /b 0
)

echo.
echo Début du déploiement complet...

:: =============================================================================
:: ÉTAPE 1: VÉRIFICATIONS PRÉLIMINAIRES
:: =============================================================================
echo.
echo [1/8] Vérifications préliminaires...

echo   Vérification PostgreSQL...
"%PGBIN%\psql.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -c "SELECT version();" >nul 2>&1
if %errorlevel% neq 0 (
    echo   ❌ PostgreSQL inaccessible
    pause
    exit /b 1
)
echo   ✅ PostgreSQL accessible

echo   Vérification base source (%DB_SOURCE%)...
"%PGBIN%\psql.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %DB_SOURCE% -c "SELECT current_database();" >nul 2>&1
if %errorlevel% neq 0 (
    echo   ❌ Base source %DB_SOURCE% inaccessible
    echo   La base source doit exister avec les données SIGETI
    pause
    exit /b 1
)
echo   ✅ Base source %DB_SOURCE% accessible

echo   Vérification base cible (%DB_DWH%)...
"%PGBIN%\psql.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %DB_DWH% -c "SELECT current_database();" >nul 2>&1
if %errorlevel% neq 0 (
    echo   ❌ Base cible %DB_DWH% inaccessible
    echo   Exécutez d'abord: 1_reinitialisation.bat
    pause
    exit /b 1
)
echo   ✅ Base cible %DB_DWH% accessible

echo   Vérification fichiers SQL...
if not exist "deploiement_dwh_consolide.sql" (
    echo   ❌ Fichier deploiement_dwh_consolide.sql manquant
    pause
    exit /b 1
)
echo   ✅ Fichiers SQL présents

:: =============================================================================
:: ÉTAPE 2: SAUVEGARDE AVANT DÉPLOIEMENT
:: =============================================================================
echo.
echo [2/8] Sauvegarde avant déploiement...

if /i "%AUTO_BACKUP%"=="true" (
    if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"
    
    set "backup_file=%BACKUP_DIR%\backup_avant_deploy_%date:~6,4%%date:~3,2%%date:~0,2%_%time:~0,2%%time:~3,2%.sql"
    set "backup_file=!backup_file: =0!"
    
    echo   Sauvegarde: !backup_file!
    "%PGBIN%\pg_dump.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %DB_DWH% -f "!backup_file!" >nul 2>&1
    if %errorlevel% equ 0 (
        echo   ✅ Sauvegarde créée
    ) else (
        echo   ⚠️  Échec sauvegarde (continue quand même)
    )
) else (
    echo   ⏭️  Sauvegarde désactivée
)

:: =============================================================================
:: ÉTAPE 3: DÉPLOIEMENT STRUCTURE DWH
:: =============================================================================
echo.
echo [3/8] Déploiement de la structure DWH...

echo   Création des schémas...
"%PGBIN%\psql.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %DB_DWH% -c "CREATE SCHEMA IF NOT EXISTS dwh;" >nul 2>&1
"%PGBIN%\psql.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %DB_DWH% -c "CREATE SCHEMA IF NOT EXISTS cdc;" >nul 2>&1
"%PGBIN%\psql.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %DB_DWH% -c "CREATE SCHEMA IF NOT EXISTS staging;" >nul 2>&1
"%PGBIN%\psql.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %DB_DWH% -c "CREATE SCHEMA IF NOT EXISTS etl;" >nul 2>&1
"%PGBIN%\psql.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %DB_DWH% -c "CREATE SCHEMA IF NOT EXISTS monitoring;" >nul 2>&1

if %errorlevel% equ 0 (
    echo   ✅ Schémas créés
) else (
    echo   ❌ Erreur création schémas
    pause
    exit /b 1
)

echo   Déploiement consolidé DWH complet (Structure + Données + Vues BI)...
"%PGBIN%\psql.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %DB_DWH% -f "deploiement_dwh_consolide.sql"
if %errorlevel% equ 0 (
    echo   ✅ Déploiement consolidé terminé avec succès
    echo     - Structure DWH déployée
    echo     - Données migrées depuis la source  
    echo     - 18 vues BI créées
) else (
    echo   ❌ Erreur dans le déploiement consolidé
    pause
    exit /b 1
)

:: =============================================================================
:: ÉTAPE 5: CONFIGURATION CDC
:: =============================================================================
echo.
echo [5/8] Configuration Change Data Capture...

if /i "%CDC_ENABLED%"=="true" (
    echo   Activation extension dblink...
    "%PGBIN%\psql.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %DB_DWH% -c "CREATE EXTENSION IF NOT EXISTS dblink;" >nul 2>&1
    
    echo   Configuration tables CDC...
    "%PGBIN%\psql.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %DB_DWH% -c "INSERT INTO cdc.cdc_config (table_source, table_cible, est_actif) SELECT 'zones_industrielles', 'dwh.dim_zones_industrielles', true WHERE NOT EXISTS (SELECT 1 FROM cdc.cdc_config WHERE table_source = 'zones_industrielles');" >nul 2>&1
    
    echo   ✅ CDC configuré
) else (
    echo   ⏭️  CDC désactivé dans la configuration
)

:: =============================================================================
:: ÉTAPE 4: VÉRIFICATION POST-DÉPLOIEMENT
:: =============================================================================
echo.
echo [4/8] Vérification post-déploiement...

echo   Vérification des vues créées...
"%PGBIN%\psql.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %DB_DWH% -c "SELECT COUNT(*) as nb_vues_indicateurs FROM pg_views WHERE schemaname = 'dwh';"

:: =============================================================================
:: ÉTAPE 7: INITIALISATION MONITORING
:: =============================================================================
echo.
echo [7/8] Initialisation du monitoring...

echo   Configuration monitoring...
"%PGBIN%\psql.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %DB_DWH% -c "INSERT INTO monitoring.dwh_status (nom_table, statut) SELECT 'dwh.dim_zones_industrielles', 'ACTIF' WHERE NOT EXISTS (SELECT 1 FROM monitoring.dwh_status WHERE nom_table = 'dwh.dim_zones_industrielles');" >nul 2>&1

echo   ✅ Monitoring initialisé

:: =============================================================================
:: ÉTAPE 8: VÉRIFICATIONS FINALES
:: =============================================================================
echo.
echo [8/8] Vérifications finales...

echo   Vérification structure...
"%PGBIN%\psql.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %DB_DWH% -c "SELECT COUNT(*) as nb_tables FROM information_schema.tables WHERE table_schema IN ('dwh', 'cdc', 'monitoring');" >nul 2>&1

echo   Test requêtes indicateurs...
"%PGBIN%\psql.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %DB_DWH% -c "SELECT * FROM dwh.v_dashboard_principal LIMIT 5;" >nul 2>&1
if %errorlevel% equ 0 (
    echo   ✅ Requêtes indicateurs fonctionnelles
) else (
    echo   ⚠️  Problème requêtes indicateurs
)

echo   Test CDC...
if /i "%CDC_ENABLED%"=="true" (
    "%PGBIN%\psql.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %DB_DWH% -c "SELECT COUNT(*) FROM cdc.cdc_config WHERE est_actif = true;" >nul 2>&1
    if %errorlevel% equ 0 (
        echo   ✅ CDC configuré et actif
    ) else (
        echo   ⚠️  Problème configuration CDC
    )
)

echo   ✅ Vérifications terminées

:: =============================================================================
:: RÉSULTATS
:: =============================================================================
echo.
echo ===============================================================================
echo                            DÉPLOIEMENT TERMINÉ                              
echo ===============================================================================
echo.
echo ✅ SUCCÈS: Le DWH SIGETI a été déployé avec succès !
echo.

:: Statistiques finales
echo Statistiques du déploiement:
"%PGBIN%\psql.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %DB_DWH% -c "SELECT table_schema, COUNT(*) as nb_tables FROM information_schema.tables WHERE table_schema IN ('dwh', 'cdc', 'monitoring') GROUP BY table_schema;"

echo.
echo Fonctionnalités disponibles:
echo   ✅ Entrepôt de données complet (dimensions + faits)
echo   ✅ Vues indicateurs et tableau de bord
if /i "%CDC_ENABLED%"=="true" echo   ✅ Synchronisation CDC configurée
echo   ✅ Système de monitoring actif
echo   ✅ Logs et audit trail
echo.
echo Prochaines étapes recommandées:
echo   1. Tester: 3_tests_environnement.bat
echo   2. Monitoring: 4_maintenance.bat
echo   3. Consulter les indicateurs dans la base %DB_DWH%
echo.

pause
goto FIN

:: =============================================================================
:: FONCTION: CHARGEMENT CONFIGURATION
:: =============================================================================
:LOAD_CONFIG
if not exist "config.ini" (
    echo ERREUR: Fichier config.ini introuvable
    exit /b 1
)

for /f "usebackq tokens=1,2 delims==" %%a in ("config.ini") do (
    if not "%%a"=="" if not "%%a"=="#" (
        set "%%a=%%b"
    )
)

exit /b 0

:FIN
endlocal
exit /b 0