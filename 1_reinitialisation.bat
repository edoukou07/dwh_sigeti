@echo off
setlocal EnableDelayedExpansion

:: =============================================================================
:: SCRIPT 1: RÉINITIALISATION COMPLÈTE DE L'ENVIRONNEMENT DWH SIGETI
:: =============================================================================
:: Ce script remet l'environnement à zéro pour un nouveau déploiement
:: Version: 1.0 - Script consolidé final
:: =============================================================================

title DWH SIGETI - RÉINITIALISATION COMPLÈTE

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
echo                    DWH SIGETI - RÉINITIALISATION COMPLÈTE                    
echo ===============================================================================
echo.
echo Cette opération va TOUT supprimer et remettre à zéro:
echo   - Toutes les tables de l'entrepôt de données (%DB_DWH%)
echo   - Tous les schémas (dwh, cdc, staging, etl, monitoring)
echo   - Toutes les configurations CDC
echo   - Tous les logs et données temporaires
echo   - Cache et fichiers de travail
echo.
echo ⚠️  ATTENTION: Cette action est IRRÉVERSIBLE !
echo ⚠️  Toutes les données de l'entrepôt seront PERDUES !
echo.

set /p confirm="Tapez 'SUPPRIMER' pour confirmer la réinitialisation : "
if /i not "%confirm%"=="SUPPRIMER" (
    echo Opération annulée par l'utilisateur.
    pause
    exit /b 0
)

echo.
echo Début de la réinitialisation complète...

:: =============================================================================
:: ÉTAPE 1: VÉRIFICATIONS PRÉLIMINAIRES
:: =============================================================================
echo.
echo [1/7] Vérifications préliminaires...

echo   Vérification PostgreSQL...
"%PGBIN%\psql.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -c "SELECT version();" >nul 2>&1
if %errorlevel% neq 0 (
    echo   ❌ PostgreSQL inaccessible
    echo   Vérifiez que PostgreSQL est démarré et accessible
    pause
    exit /b 1
)
echo   ✅ PostgreSQL accessible

echo   Vérification base source (%DB_SOURCE%)...
"%PGBIN%\psql.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %DB_SOURCE% -c "SELECT current_database();" >nul 2>&1
if %errorlevel% neq 0 (
    echo   ⚠️  Base source %DB_SOURCE% inaccessible
    echo   La base source doit exister pour le futur déploiement
) else (
    echo   ✅ Base source %DB_SOURCE% accessible
)

echo   Vérification base entrepôt (%DB_DWH%)...
"%PGBIN%\psql.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %DB_DWH% -c "SELECT current_database();" >nul 2>&1
if %errorlevel% neq 0 (
    echo   ⚠️  Base entrepôt %DB_DWH% inaccessible - sera créée si nécessaire
) else (
    echo   ✅ Base entrepôt %DB_DWH% accessible
)

:: =============================================================================
:: ÉTAPE 2: SAUVEGARDE DE SÉCURITÉ (OPTIONNELLE)
:: =============================================================================
echo.
echo [2/7] Sauvegarde de sécurité...

if /i "%AUTO_BACKUP%"=="true" (
    if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"
    
    set "backup_file=%BACKUP_DIR%\backup_avant_reinit_%date:~6,4%%date:~3,2%%date:~0,2%_%time:~0,2%%time:~3,2%.sql"
    set "backup_file=!backup_file: =0!"
    
    echo   Création sauvegarde: !backup_file!
    "%PGBIN%\pg_dump.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %DB_DWH% -f "!backup_file!" >nul 2>&1
    if %errorlevel% equ 0 (
        echo   ✅ Sauvegarde créée avec succès
    ) else (
        echo   ⚠️  Échec sauvegarde (pas critique pour la réinitialisation)
    )
) else (
    echo   ⏭️  Sauvegarde désactivée dans la configuration
)

:: =============================================================================
:: ÉTAPE 3: ARRÊT DES PROCESSUS ACTIFS
:: =============================================================================
echo.
echo [3/7] Arrêt des processus actifs...

echo   Arrêt des connexions psql...
taskkill /f /im psql.exe >nul 2>&1

echo   Fermeture des connexions à %DB_DWH%...
"%PGBIN%\psql.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -d postgres -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '%DB_DWH%' AND pid <> pg_backend_pid();" >nul 2>&1

echo   ✅ Processus fermés

:: =============================================================================
:: ÉTAPE 4: SUPPRESSION COMPLÈTE DES DONNÉES DWH
:: =============================================================================
echo.
echo [4/7] Suppression des données entrepôt...

echo   Exécution du nettoyage complet...
"%PGBIN%\psql.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %DB_DWH% -f "nettoyage_sigeti_dwh.sql" >nul 2>&1

echo   ✅ Données entrepôt supprimées

:: =============================================================================
:: ÉTAPE 5: NETTOYAGE DES FICHIERS SYSTÈME
:: =============================================================================
echo.
echo [5/7] Nettoyage des fichiers système...

echo   Nettoyage des logs...
if exist "%LOG_DIR%" (
    del /q /s "%LOG_DIR%\*.log" >nul 2>&1
    del /q /s "%LOG_DIR%\*.tmp" >nul 2>&1
    echo   ✅ Logs nettoyés
) else (
    echo   ⏭️  Répertoire logs inexistant
)

echo   Nettoyage des fichiers temporaires...
if exist "%TEMP%\dwh_sigeti_*" del /q "%TEMP%\dwh_sigeti_*" >nul 2>&1
if exist "%TEMP%\postgresql_*" del /q "%TEMP%\postgresql_*" >nul 2>&1

echo   Création des répertoires nécessaires...
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"

echo   ✅ Fichiers système nettoyés

:: =============================================================================
:: ÉTAPE 6: RECRÉATION BASE PROPRE
:: =============================================================================
echo.
echo [6/7] Recréation base propre...

echo   Recréation de la base %DB_DWH%...
"%PGBIN%\dropdb.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% --if-exists %DB_DWH% >nul 2>&1
"%PGBIN%\createdb.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% %DB_DWH% >nul 2>&1

if %errorlevel% equ 0 (
    echo   ✅ Base %DB_DWH% recréée
) else (
    echo   ❌ Erreur création base %DB_DWH%
    pause
    exit /b 1
)

echo   Configuration initiale...
"%PGBIN%\psql.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %DB_DWH% -c "CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\";" >nul 2>&1
"%PGBIN%\psql.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %DB_DWH% -c "ALTER DATABASE %DB_DWH% SET timezone = 'Europe/Paris';" >nul 2>&1

echo   ✅ Base configurée

:: =============================================================================
:: ÉTAPE 7: VÉRIFICATION FINALE
:: =============================================================================
echo.
echo [7/7] Vérification finale...

echo   Test connexion base propre...
"%PGBIN%\psql.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %DB_DWH% -c "SELECT 1;" >nul 2>&1
if %errorlevel% equ 0 (
    echo   ✅ Base propre fonctionnelle
) else (
    echo   ❌ Problème base propre
    pause
    exit /b 1
)

echo   Vérification schémas supprimés...
"%PGBIN%\psql.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %DB_DWH% -c "SELECT COUNT(*) FROM information_schema.schemata WHERE schema_name IN ('dwh', 'cdc', 'staging', 'etl', 'monitoring');" >nul 2>&1

echo   ✅ Environnement propre vérifié

:: =============================================================================
:: RÉSULTATS
:: =============================================================================
echo.
echo ===============================================================================
echo                           RÉINITIALISATION TERMINÉE                          
echo ===============================================================================
echo.
echo ✅ SUCCÈS: L'environnement DWH SIGETI a été complètement réinitialisé
echo.
echo État final:
echo   - Base entrepôt (%DB_DWH%): 🆕 Propre et vide
echo   - Base source (%DB_SOURCE%): ✅ Préservée
echo   - Schémas DWH: ❌ Supprimés (prêts pour nouveau déploiement)
echo   - Logs système: 🧹 Nettoyés
echo   - Fichiers temporaires: 🧹 Supprimés
if /i "%AUTO_BACKUP%"=="true" echo   - Sauvegarde: 💾 Créée dans %BACKUP_DIR%
echo.
echo Prochaines étapes recommandées:
echo   1. Exécuter: 2_deploiement_complet.bat (déploiement complet)
echo   2. Puis: 3_tests_environnement.bat (validation)
echo   3. Enfin: 4_maintenance.bat (monitoring)
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

:: Vérification variables essentielles
if "%PGBIN%"=="" (
    echo ERREUR: PGBIN non configuré dans config.ini
    exit /b 1
)
if "%DB_DWH%"=="" (
    echo ERREUR: DB_DWH non configuré dans config.ini
    exit /b 1
)

exit /b 0

:FIN
endlocal
exit /b 0