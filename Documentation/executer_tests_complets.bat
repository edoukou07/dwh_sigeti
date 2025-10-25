@echo off
REM Script de test complet pour l'entrepôt de données SIGETI
REM Guide_Tests_DWH_SIGETI.md - Script d'automatisation

echo ===============================================
echo 🧪 TESTS ENTREPOT DE DONNEES SIGETI
echo ===============================================
echo.

REM Configuration
set PGPASSWORD=postgres
set PSQL_PATH="C:\Program Files\PostgreSQL\13\bin\psql.exe"
set SOURCE_DB=sigeti_node_db
set DWH_DB=sigeti_dwh
set SCRIPTS_DIR=%~dp0Scripts_Tests

REM Vérifier que les fichiers de test existent
if not exist "%SCRIPTS_DIR%" (
    echo ERREUR: Dossier Scripts_Tests non trouvé
    pause
    exit /b 1
)

echo 🔧 Configuration:
echo - Base source: %SOURCE_DB%
echo - Base DWH: %DWH_DB%
echo - Scripts: %SCRIPTS_DIR%
echo.

REM Test 1: Prérequis
echo ✅ Test 1: Vérification des prérequis...
%PSQL_PATH% -U postgres -d %SOURCE_DB% -f "%SCRIPTS_DIR%\test_1_prerequis.sql"
if %ERRORLEVEL% neq 0 (
    echo ❌ ÉCHEC Test 1
    pause
    exit /b 1
)
echo ✅ Test 1 RÉUSSI
echo.

REM Test 2: Structure CDC
echo ✅ Test 2: Structure CDC...
%PSQL_PATH% -U postgres -d %SOURCE_DB% -f "%SCRIPTS_DIR%\test_2_structure_cdc.sql"
if %ERRORLEVEL% neq 0 (
    echo ❌ ÉCHEC Test 2
    pause
    exit /b 1
)
echo ✅ Test 2 RÉUSSI
echo.

REM Test 3: Structure DWH
echo ✅ Test 3: Structure DWH...
%PSQL_PATH% -U postgres -d %DWH_DB% -f "%SCRIPTS_DIR%\test_3_structure_dwh.sql"
if %ERRORLEVEL% neq 0 (
    echo ❌ ÉCHEC Test 3
    pause
    exit /b 1
)
echo ✅ Test 3 RÉUSSI
echo.

REM Tests 4-7: Tests fonctionnels
echo ✅ Tests 4-7: Tests fonctionnels...
echo   - Exécution dans la base source...
%PSQL_PATH% -U postgres -d %SOURCE_DB% -f "%SCRIPTS_DIR%\test_4_7_fonctionnels.sql"
if %ERRORLEVEL% neq 0 (
    echo ❌ ÉCHEC Tests 4-7 (partie source)
    pause
    exit /b 1
)

echo   - Exécution dans le DWH...
%PSQL_PATH% -U postgres -d %DWH_DB% -f "%SCRIPTS_DIR%\test_5_traitement_dwh.sql"
if %ERRORLEVEL% neq 0 (
    echo ❌ ÉCHEC Tests 4-7 (partie DWH)
    pause
    exit /b 1
)
echo ✅ Tests 4-7 RÉUSSIS
echo.

REM Test 8: Jobs pgAgent
echo ✅ Test 8: Jobs pgAgent...
%PSQL_PATH% -U postgres -d %SOURCE_DB% -f "%SCRIPTS_DIR%\test_8_jobs.sql"
if %ERRORLEVEL% neq 0 (
    echo ❌ ÉCHEC Test 8
    pause
    exit /b 1
)
echo ✅ Test 8 RÉUSSI
echo.

REM Test 9: Archivage
echo ✅ Test 9: Archivage CDC...
%PSQL_PATH% -U postgres -d %SOURCE_DB% -f "%SCRIPTS_DIR%\test_9_archivage.sql"
if %ERRORLEVEL% neq 0 (
    echo ❌ ÉCHEC Test 9
    pause
    exit /b 1
)
echo ✅ Test 9 RÉUSSI
echo.

REM Test 10: Performance
echo ✅ Test 10: Performance...
echo   - Partie source...
%PSQL_PATH% -U postgres -d %SOURCE_DB% -f "%SCRIPTS_DIR%\test_10_performance.sql"
if %ERRORLEVEL% neq 0 (
    echo ❌ ÉCHEC Test 10 (partie source)
    pause
    exit /b 1
)

echo   - Partie DWH...
%PSQL_PATH% -U postgres -d %DWH_DB% -f "%SCRIPTS_DIR%\test_10_performance_dwh.sql"
if %ERRORLEVEL% neq 0 (
    echo ❌ ÉCHEC Test 10 (partie DWH)
    pause
    exit /b 1
)
echo ✅ Test 10 RÉUSSI
echo.

REM Résumé final
echo ===============================================
echo 🎉 TOUS LES TESTS SONT RÉUSSIS !
echo ===============================================
echo.
echo 📊 Résumé:
echo ✅ Test 1 - Prérequis
echo ✅ Test 2 - Structure CDC  
echo ✅ Test 3 - Structure DWH
echo ✅ Test 4-7 - Tests fonctionnels
echo ✅ Test 8 - Jobs pgAgent
echo ✅ Test 9 - Archivage CDC
echo ✅ Test 10 - Performance
echo.
echo 🚀 L'entrepôt de données SIGETI est opérationnel !
echo.
echo Appuyez sur une touche pour continuer...
pause > nul