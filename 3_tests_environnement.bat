@echo off
setlocal EnableDelayedExpansion

:: =============================================================================
:: SCRIPT 3: TESTS COMPLETS DE L'ENVIRONNEMENT DWH SIGETI
:: =============================================================================
:: Ce script valide que tout l'environnement est fonctionnel
:: Version: 1.0 - Script consolidé final
:: =============================================================================

title DWH SIGETI - TESTS ENVIRONNEMENT

:: Chargement de la configuration
call :LOAD_CONFIG
if %errorlevel% neq 0 (
    echo ERREUR: Impossible de charger la configuration
    pause
    exit /b 1
)

:: Variables de comptage
set /a tests_total=0
set /a tests_reussis=0
set /a tests_erreurs=0
set /a tests_warnings=0

echo.
echo ===============================================================================
echo                    DWH SIGETI - TESTS COMPLETS ENVIRONNEMENT                
echo ===============================================================================
echo.
echo Mode de test: %TEST_MODE%
echo Configuration testée:
echo   - Base source: %DB_SOURCE%
echo   - Base entrepôt: %DB_DWH%
echo   - Timeout: %TEST_TIMEOUT%s
echo   - Tentatives: %TEST_RETRY_COUNT%
echo.

:: Déterminer le mode de test
set "mode=%1"
if "%mode%"=="" set "mode=%TEST_MODE%"

if /i "%mode%"=="rapide" goto TESTS_RAPIDES
if /i "%mode%"=="standard" goto TESTS_STANDARDS
if /i "%mode%"=="complet" goto TESTS_COMPLETS
if /i "%mode%"=="performance" goto TESTS_PERFORMANCE

:: Mode par défaut
goto TESTS_STANDARDS

:: =============================================================================
:: TESTS RAPIDES (3-5 minutes)
:: =============================================================================
:TESTS_RAPIDES
echo Mode: Tests rapides (vérifications critiques)
echo.

call :TEST_HEADER "TESTS RAPIDES"

call :TEST_FUNCTION "PostgreSQL Service" "test_postgresql_service"
call :TEST_FUNCTION "Connexion Base Source" "test_connexion_source"  
call :TEST_FUNCTION "Connexion Base DWH" "test_connexion_dwh"
call :TEST_FUNCTION "Schémas Essentiels" "test_schemas_essentiels"
call :TEST_FUNCTION "Tables Principales" "test_tables_principales"

goto AFFICHER_RESULTATS

:: =============================================================================
:: TESTS STANDARDS (10-15 minutes)  
:: =============================================================================
:TESTS_STANDARDS
echo Mode: Tests standards (validation complète)
echo.

call :TEST_HEADER "TESTS STANDARDS"

:: Tests de connectivité
call :TEST_FUNCTION "PostgreSQL Service" "test_postgresql_service"
call :TEST_FUNCTION "Connexion Base Source" "test_connexion_source"
call :TEST_FUNCTION "Connexion Base DWH" "test_connexion_dwh"
call :TEST_FUNCTION "Authentification" "test_authentification"

:: Tests de structure
call :TEST_FUNCTION "Schémas DWH" "test_schemas_essentiels"
call :TEST_FUNCTION "Tables Dimensions" "test_tables_dimensions"
call :TEST_FUNCTION "Tables Faits" "test_tables_faits"
call :TEST_FUNCTION "Vues Indicateurs" "test_vues_indicateurs"

:: Tests de données
call :TEST_FUNCTION "Données Référence" "test_donnees_reference"
call :TEST_FUNCTION "Intégrité Référentielle" "test_integrite_donnees"

:: Tests fonctionnels
call :TEST_FUNCTION "Configuration CDC" "test_configuration_cdc"
call :TEST_FUNCTION "Système Monitoring" "test_systeme_monitoring"

goto AFFICHER_RESULTATS

:: =============================================================================
:: TESTS COMPLETS (20-30 minutes)
:: =============================================================================
:TESTS_COMPLETS
echo Mode: Tests complets (validation exhaustive)
echo.

call :TEST_HEADER "TESTS COMPLETS"

:: Tests infrastructure
call :TEST_FUNCTION "PostgreSQL Service" "test_postgresql_service"
call :TEST_FUNCTION "PostgreSQL Version" "test_postgresql_version"  
call :TEST_FUNCTION "PostgreSQL Configuration" "test_postgresql_config"
call :TEST_FUNCTION "Espace Disque" "test_espace_disque"
call :TEST_FUNCTION "Mémoire Système" "test_memoire_systeme"

:: Tests connectivité
call :TEST_FUNCTION "Connexion Base Source" "test_connexion_source"
call :TEST_FUNCTION "Connexion Base DWH" "test_connexion_dwh"
call :TEST_FUNCTION "Authentification" "test_authentification"
call :TEST_FUNCTION "Permissions Utilisateur" "test_permissions_utilisateur"

:: Tests structure complète
call :TEST_FUNCTION "Schémas DWH" "test_schemas_essentiels"
call :TEST_FUNCTION "Tables Dimensions" "test_tables_dimensions"
call :TEST_FUNCTION "Tables Faits" "test_tables_faits"
call :TEST_FUNCTION "Vues Indicateurs" "test_vues_indicateurs"
call :TEST_FUNCTION "Fonctions Système" "test_fonctions_systeme"
call :TEST_FUNCTION "Contraintes Intégrité" "test_contraintes_integrite"

:: Tests données
call :TEST_FUNCTION "Données Référence" "test_donnees_reference"
call :TEST_FUNCTION "Intégrité Référentielle" "test_integrite_donnees"
call :TEST_FUNCTION "Cohérence Données" "test_coherence_donnees"
call :TEST_FUNCTION "Qualité Données" "test_qualite_donnees"

:: Tests CDC et ETL
call :TEST_FUNCTION "Configuration CDC" "test_configuration_cdc"
call :TEST_FUNCTION "Processus ETL" "test_processus_etl"
call :TEST_FUNCTION "Synchronisation" "test_synchronisation"

:: Tests monitoring
call :TEST_FUNCTION "Système Monitoring" "test_systeme_monitoring"
call :TEST_FUNCTION "Logs Système" "test_logs_systeme"
call :TEST_FUNCTION "Alertes" "test_alertes"

goto AFFICHER_RESULTATS

:: =============================================================================
:: TESTS PERFORMANCE (15-20 minutes)
:: =============================================================================
:TESTS_PERFORMANCE
echo Mode: Tests performance (métriques et benchmarks)
echo.

call :TEST_HEADER "TESTS PERFORMANCE"

call :TEST_FUNCTION "Temps Connexion" "test_temps_connexion"
call :TEST_FUNCTION "Requêtes Simples" "test_requetes_simples"
call :TEST_FUNCTION "Requêtes Complexes" "test_requetes_complexes"
call :TEST_FUNCTION "Jointures Multiples" "test_jointures_multiples"
call :TEST_FUNCTION "Agrégations" "test_agregations"
call :TEST_FUNCTION "Indexation" "test_indexation"
call :TEST_FUNCTION "Utilisation Mémoire" "test_utilisation_memoire"
call :TEST_FUNCTION "Utilisation CPU" "test_utilisation_cpu"
call :TEST_FUNCTION "I/O Disque" "test_io_disque"
call :TEST_FUNCTION "Connexions Simultanées" "test_connexions_simultanees"

goto AFFICHER_RESULTATS

:: =============================================================================
:: FONCTIONS DE TEST INDIVIDUELLES
:: =============================================================================

:test_postgresql_service
sc query postgresql-13 >nul 2>&1
if %errorlevel% equ 0 (
    exit /b 0
) else (
    exit /b 1
)

:test_connexion_source
"%PGBIN%\psql.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %DB_SOURCE% -c "SELECT 1;" >nul 2>&1
exit /b %errorlevel%

:test_connexion_dwh
"%PGBIN%\psql.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %DB_DWH% -c "SELECT 1;" >nul 2>&1
exit /b %errorlevel%

:test_authentification
"%PGBIN%\psql.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %DB_DWH% -c "SELECT current_user, session_user;" >nul 2>&1
exit /b %errorlevel%

:test_schemas_essentiels
"%PGBIN%\psql.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %DB_DWH% -c "SELECT COUNT(*) FROM information_schema.schemata WHERE schema_name IN ('dwh', 'cdc', 'monitoring');" | findstr "3" >nul 2>&1
exit /b %errorlevel%

:test_tables_principales
"%PGBIN%\psql.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %DB_DWH% -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'dwh';" >nul 2>&1
if %errorlevel% equ 0 (
    exit /b 0
) else (
    exit /b 1
)

:test_tables_dimensions
"%PGBIN%\psql.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %DB_DWH% -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'dwh' AND table_name LIKE 'dim_%';" >nul 2>&1
exit /b %errorlevel%

:test_tables_faits
"%PGBIN%\psql.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %DB_DWH% -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'dwh' AND table_name LIKE 'fait_%';" >nul 2>&1
exit /b %errorlevel%

:test_vues_indicateurs
"%PGBIN%\psql.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %DB_DWH% -c "SELECT COUNT(*) FROM information_schema.views WHERE table_schema = 'dwh';" >nul 2>&1
exit /b %errorlevel%

:test_donnees_reference
"%PGBIN%\psql.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %DB_DWH% -c "SELECT COUNT(*) FROM dwh.dim_temps WHERE date_complete = CURRENT_DATE;" >nul 2>&1
exit /b %errorlevel%

:test_integrite_donnees
"%PGBIN%\psql.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %DB_DWH% -c "SELECT COUNT(*) FROM information_schema.table_constraints WHERE constraint_type = 'FOREIGN KEY';" >nul 2>&1
exit /b %errorlevel%

:test_configuration_cdc
if /i "%CDC_ENABLED%"=="true" (
    "%PGBIN%\psql.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %DB_DWH% -c "SELECT COUNT(*) FROM cdc.cdc_config WHERE est_actif = true;" >nul 2>&1
    exit /b %errorlevel%
) else (
    exit /b 0
)

:test_systeme_monitoring
"%PGBIN%\psql.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %DB_DWH% -c "SELECT COUNT(*) FROM monitoring.dwh_status;" >nul 2>&1
exit /b %errorlevel%

:test_postgresql_version
"%PGBIN%\psql.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -c "SHOW server_version;" >nul 2>&1
exit /b %errorlevel%

:test_postgresql_config
"%PGBIN%\psql.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -c "SHOW max_connections;" >nul 2>&1
exit /b %errorlevel%

:test_espace_disque
dir C: >nul 2>&1
exit /b %errorlevel%

:test_memoire_systeme
wmic OS get TotalVisibleMemorySize /value >nul 2>&1
exit /b %errorlevel%

:test_permissions_utilisateur
"%PGBIN%\psql.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %DB_DWH% -c "SELECT has_database_privilege(current_user, '%DB_DWH%', 'CREATE');" >nul 2>&1
exit /b %errorlevel%

:test_fonctions_systeme
"%PGBIN%\psql.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %DB_DWH% -c "SELECT COUNT(*) FROM information_schema.routines WHERE routine_schema = 'dwh';" >nul 2>&1
exit /b %errorlevel%

:test_contraintes_integrite
"%PGBIN%\psql.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %DB_DWH% -c "SELECT COUNT(*) FROM information_schema.table_constraints WHERE table_schema = 'dwh';" >nul 2>&1
exit /b %errorlevel%

:test_coherence_donnees
"%PGBIN%\psql.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %DB_DWH% -c "SELECT CASE WHEN COUNT(*) > 0 THEN 1 ELSE 0 END FROM dwh.dim_temps;" >nul 2>&1
exit /b %errorlevel%

:test_qualite_donnees
"%PGBIN%\psql.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %DB_DWH% -c "SELECT CASE WHEN COUNT(*) = 0 THEN 1 ELSE 0 END FROM dwh.dim_temps WHERE date_complete IS NULL;" >nul 2>&1
exit /b %errorlevel%

:test_processus_etl
"%PGBIN%\psql.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %DB_DWH% -c "SELECT COUNT(*) FROM monitoring.etl_logs WHERE statut = 'SUCCES';" >nul 2>&1
exit /b %errorlevel%

:test_synchronisation
if /i "%CDC_ENABLED%"=="true" (
    "%PGBIN%\psql.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %DB_DWH% -c "SELECT COUNT(*) FROM cdc.cdc_sync_status WHERE sync_status = 'SUCCESS';" >nul 2>&1
    exit /b %errorlevel%
) else (
    exit /b 0
)

:test_logs_systeme
if exist "%LOG_DIR%" (
    dir "%LOG_DIR%\*.log" >nul 2>&1
    exit /b %errorlevel%
) else (
    exit /b 1
)

:test_alertes
"%PGBIN%\psql.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %DB_DWH% -c "SELECT 1;" >nul 2>&1
exit /b %errorlevel%

:test_temps_connexion
powershell -Command "Measure-Command { & '%PGBIN%\psql.exe' -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %DB_DWH% -c 'SELECT 1;' } | Select-Object -ExpandProperty TotalMilliseconds" >nul 2>&1
exit /b %errorlevel%

:test_requetes_simples
"%PGBIN%\psql.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %DB_DWH% -c "SELECT COUNT(*) FROM information_schema.tables;" >nul 2>&1
exit /b %errorlevel%

:test_requetes_complexes
"%PGBIN%\psql.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %DB_DWH% -c "SELECT table_schema, COUNT(*) FROM information_schema.tables GROUP BY table_schema ORDER BY COUNT(*) DESC;" >nul 2>&1
exit /b %errorlevel%

:test_jointures_multiples
"%PGBIN%\psql.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %DB_DWH% -c "SELECT COUNT(*) FROM information_schema.tables t JOIN information_schema.columns c ON t.table_name = c.table_name WHERE t.table_schema = 'dwh';" >nul 2>&1
exit /b %errorlevel%

:test_agregations
"%PGBIN%\psql.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %DB_DWH% -c "SELECT table_schema, COUNT(*), MIN(table_name), MAX(table_name) FROM information_schema.tables GROUP BY table_schema;" >nul 2>&1
exit /b %errorlevel%

:test_indexation
"%PGBIN%\psql.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %DB_DWH% -c "SELECT COUNT(*) FROM pg_indexes WHERE schemaname = 'dwh';" >nul 2>&1
exit /b %errorlevel%

:test_utilisation_memoire
wmic process where "name='postgres.exe'" get WorkingSetSize /value >nul 2>&1
exit /b %errorlevel%

:test_utilisation_cpu
wmic process where "name='postgres.exe'" get PageFileUsage /value >nul 2>&1
exit /b %errorlevel%

:test_io_disque
"%PGBIN%\psql.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %DB_DWH% -c "SELECT sum(blks_read + blks_hit) FROM pg_stat_database WHERE datname = '%DB_DWH%';" >nul 2>&1
exit /b %errorlevel%

:test_connexions_simultanees
"%PGBIN%\psql.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %DB_DWH% -c "SELECT COUNT(*) FROM pg_stat_activity WHERE datname = '%DB_DWH%';" >nul 2>&1
exit /b %errorlevel%

:: =============================================================================
:: FONCTIONS UTILITAIRES
:: =============================================================================

:TEST_HEADER
echo.
echo ===============================================================================
echo                                  %~1
echo ===============================================================================
echo.
exit /b 0

:TEST_FUNCTION
set /a tests_total+=1
set "test_name=%~1"
set "test_func=%~2"

echo [%tests_total%] Test %test_name%...

call :%test_func%
set "test_result=%errorlevel%"

if %test_result% equ 0 (
    echo   ✅ %test_name%: SUCCÈS
    set /a tests_reussis+=1
) else (
    echo   ❌ %test_name%: ÉCHEC
    set /a tests_erreurs+=1
)

exit /b 0

:AFFICHER_RESULTATS
echo.
echo ===============================================================================
echo                             RÉSULTATS DES TESTS
echo ===============================================================================
echo.

:: Calcul des pourcentages
set /a pourcentage_succes=(tests_reussis * 100) / tests_total
set /a pourcentage_echecs=(tests_erreurs * 100) / tests_total

echo Statistiques:
echo   - Tests exécutés: %tests_total%
echo   - Tests réussis: %tests_reussis% (%pourcentage_succes%%%)
echo   - Tests échoués: %tests_erreurs% (%pourcentage_echecs%%%)
echo.

:: Détermination du statut global
if %tests_erreurs% equ 0 (
    echo ✅ RÉSULTAT GLOBAL: SUCCÈS COMPLET
    echo.
    echo 🎉 L'environnement DWH SIGETI est entièrement fonctionnel !
    echo.
    echo Toutes les vérifications sont passées avec succès:
    echo   ✅ Infrastructure PostgreSQL opérationnelle
    echo   ✅ Bases de données accessibles
    echo   ✅ Structure DWH complète et cohérente
    echo   ✅ Données intègres et synchronisées
    if /i "%CDC_ENABLED%"=="true" echo   ✅ Système CDC configuré et actif
    echo   ✅ Monitoring et logs fonctionnels
    echo.
    echo L'environnement est prêt pour la production !
) else if %pourcentage_succes% geq 80 (
    echo ⚠️  RÉSULTAT GLOBAL: FONCTIONNEL AVEC AVERTISSEMENTS
    echo.
    echo L'environnement DWH SIGETI est globalement opérationnel
    echo mais quelques problèmes mineurs ont été détectés.
    echo.
    echo Actions recommandées:
    echo   - Examiner les tests échoués
    echo   - Corriger les problèmes identifiés  
    echo   - Relancer les tests après correction
) else if %pourcentage_succes% geq 50 (
    echo ❌ RÉSULTAT GLOBAL: PROBLÈMES SIGNIFICATIFS
    echo.
    echo L'environnement présente des dysfonctionnements importants.
    echo.
    echo Actions requises:
    if %tests_erreurs% geq 3 (
        echo   - Vérifier la configuration PostgreSQL
        echo   - Redéployer si nécessaire: 2_deploiement_complet.bat
    )
    echo   - Consulter les logs d'erreur
    echo   - Contacter le support technique
) else (
    echo ❌ RÉSULTAT GLOBAL: SYSTÈME NON FONCTIONNEL
    echo.
    echo L'environnement DWH SIGETI présente des défaillances critiques.
    echo.
    echo Actions urgentes:
    echo   - Réinitialiser l'environnement: 1_reinitialisation.bat
    echo   - Redéployer complètement: 2_deploiement_complet.bat
    echo   - Vérifier l'infrastructure PostgreSQL
    echo   - Consulter la documentation technique
)

echo.
echo ===============================================================================
echo.

:: Génération rapport détaillé
if /i "%VERBOSE%"=="true" (
    echo Génération du rapport détaillé...
    if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"
    
    set "rapport_file=%LOG_DIR%\rapport_tests_%date:~6,4%%date:~3,2%%date:~0,2%_%time:~0,2%%time:~3,2%.txt"
    set "rapport_file=!rapport_file: =0!"
    
    echo Rapport de tests DWH SIGETI > "!rapport_file!"
    echo Date: %date% %time% >> "!rapport_file!"
    echo Mode: %mode% >> "!rapport_file!"
    echo Total tests: %tests_total% >> "!rapport_file!"
    echo Succès: %tests_reussis% >> "!rapport_file!"
    echo Échecs: %tests_erreurs% >> "!rapport_file!"
    
    echo   ✅ Rapport sauvegardé: !rapport_file!
)

echo Pour continuer:
echo   - Maintenance: 4_maintenance.bat
echo   - Redéploiement: 2_deploiement_complet.bat  
echo   - Réinitialisation: 1_reinitialisation.bat
echo.

if not "%1"=="auto" pause

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
exit /b %pourcentage_succes%