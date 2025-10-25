@echo off
echo ================================================
echo     DÉPLOIEMENT AUTOMATIQUE DWH SIGETI
echo ================================================
echo.

set PSQL_PATH="C:\Program Files\PostgreSQL\13\bin\psql.exe"
set PGPASSWORD=postgres
set SCRIPTS_DIR=C:\Users\hynco\Desktop\DWH\Scripts

echo [INFO] Vérification des prérequis...
%PSQL_PATH% -U postgres -d postgres -c "SELECT version();" > nul 2>&1
if ERRORLEVEL 1 (
    echo [ERREUR] PostgreSQL non accessible !
    pause
    exit /b 1
)

echo [OK] PostgreSQL accessible
echo.

echo ================================================
echo     PHASE 1: CONFIGURATION CDC (sigeti_node_db)
echo ================================================

echo [1/4] Configuration initiale CDC...
%PSQL_PATH% -U postgres -d sigeti_node_db -f "%SCRIPTS_DIR%\cdc\CDC_01_configuration_initiale.sql"
if ERRORLEVEL 1 (
    echo [ERREUR] Échec configuration CDC !
    pause
    exit /b 1
)
echo [OK] Configuration CDC terminée

echo [2/4] Installation des fonctions essentielles...
%PSQL_PATH% -U postgres -d sigeti_node_db -f "%SCRIPTS_DIR%\cdc\CDC_02_fonctions_essentielles.sql"
if ERRORLEVEL 1 (
    echo [ERREUR] Échec installation fonctions !
    pause
    exit /b 1
)
echo [OK] Fonctions CDC installées

echo [3/4] Configuration de l'archivage automatique...
%PSQL_PATH% -U postgres -d sigeti_node_db -f "%SCRIPTS_DIR%\cdc\CDC_03_archivage_automatique.sql"
if ERRORLEVEL 1 (
    echo [ERREUR] Échec configuration archivage !
    pause
    exit /b 1
)
echo [OK] Archivage configuré

echo [4/4] Installation des jobs pgAgent...
%PSQL_PATH% -U postgres -d sigeti_node_db -f "%SCRIPTS_DIR%\cdc\CDC_04_jobs_pgagent.sql"
if ERRORLEVEL 1 (
    echo [ERREUR] Échec installation jobs !
    pause
    exit /b 1
)
echo [OK] Jobs pgAgent installés

echo.
echo ================================================
echo     PHASE 2: CONFIGURATION DWH (sigeti_dwh)
echo ================================================

echo [5/7] Création de la structure Data Warehouse...
%PSQL_PATH% -U postgres -d sigeti_dwh -f "%SCRIPTS_DIR%\schema\DWH_01_structure_warehouse.sql"
if ERRORLEVEL 1 (
    echo [ERREUR] Échec création structure DWH !
    pause
    exit /b 1
)
echo [OK] Structure DWH créée

echo [6/7] Création complète du DWH...
%PSQL_PATH% -U postgres -d sigeti_dwh -f "%SCRIPTS_DIR%\etl\DWH_02_creation_complete.sql"
if ERRORLEVEL 1 (
    echo [ERREUR] Échec création DWH !
    pause
    exit /b 1
)
echo [OK] DWH créé

echo [7/7] Configuration de la réplication...
%PSQL_PATH% -U postgres -d sigeti_dwh -f "%SCRIPTS_DIR%\cdc\CDC_05_replication_dwh.sql"
if ERRORLEVEL 1 (
    echo [ERREUR] Échec configuration réplication !
    pause
    exit /b 1
)
echo [OK] Réplication configurée

echo.
echo ================================================
echo     PHASE 3: VALIDATION DU DÉPLOIEMENT
echo ================================================

echo [INFO] Vérification de l'installation CDC...
%PSQL_PATH% -U postgres -d sigeti_node_db -c "SELECT * FROM cdc.get_cdc_stats();"

echo [INFO] Vérification des jobs pgAgent...
%PSQL_PATH% -U postgres -d sigeti_node_db -c "SELECT jobname, jobenabled FROM pgagent.pga_job WHERE jobname LIKE '%%CDC%%';"

echo [INFO] Vérification du DWH...
%PSQL_PATH% -U postgres -d sigeti_dwh -c "SELECT COUNT(*) as tables_dwh FROM information_schema.tables WHERE table_schema = 'dwh';"

echo.
echo ================================================
echo     DÉPLOIEMENT TERMINÉ AVEC SUCCÈS ! ✅
echo ================================================
echo.
echo Prochaines étapes recommandées:
echo 1. Exécuter les tests complets: Documentation\executer_tests_complets.bat
echo 2. Configurer la surveillance: Documentation\surveillance_quotidienne.sql
echo 3. Consulter la documentation: Documentation\Guide_Tests_DWH_SIGETI.md
echo.
pause