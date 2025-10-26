@echo off
setlocal EnableDelayedExpansion

:: Configuration depuis config.ini
set PGBIN=C:\Program Files\PostgreSQL\13\bin
set PGUSER=postgres
set PGHOST=localhost
set PGPORT=5432
set DB_SOURCE=sigeti_node_db
set DB_DWH=sigeti_dwh

echo ===============================================================================
echo                     DIAGNOSTIC TABLE dim_lots
echo ===============================================================================
echo.

echo [1] Contenu actuel de dim_lots dans le DWH...
"%PGBIN%\psql.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %DB_DWH% -c "SELECT COUNT(*) as nb_lots FROM dwh.dim_lots;" 2>nul

echo.
echo [2] Structure de dim_lots...
"%PGBIN%\psql.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %DB_DWH% -c "SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'dim_lots' ORDER BY ordinal_position;" 2>nul

echo.
echo [3] Recherche table lots dans la base source...
"%PGBIN%\psql.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %DB_SOURCE% -c "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' AND table_name ILIKE '%%lot%%' ORDER BY table_name;" 2>nul

echo.
echo [4] Contenu de la table lots dans la source...
"%PGBIN%\psql.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %DB_SOURCE% -c "SELECT COUNT(*) as nb_lots_source FROM lots;" 2>nul

echo.
echo [5] Échantillon de données lots source...
"%PGBIN%\psql.exe" -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %DB_SOURCE% -c "SELECT * FROM lots LIMIT 3;" 2>nul

echo.
echo ===============================================================================
pause