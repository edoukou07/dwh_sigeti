@echo off
set PGPASSWORD=postgres
"C:\Program Files\PostgreSQL\13\bin\createdb.exe" -U postgres sigeti_node_db
"C:\Program Files\PostgreSQL\13\bin\createdb.exe" -U postgres sigeti_dwh
"C:\Program Files\PostgreSQL\13\bin\psql.exe" -U postgres -d sigeti_node_db -f "C:\Users\hynco\Desktop\DWH\Scripts\source_schema.sql"
"C:\Program Files\PostgreSQL\13\bin\psql.exe" -U postgres -d sigeti_dwh -f "C:\Users\hynco\Desktop\DWH\Scripts\dwh_schema.sql"
"C:\Program Files\PostgreSQL\13\bin\psql.exe" -U postgres -d sigeti_node_db -f "C:\Users\hynco\Desktop\DWH\Scripts\cdc_setup_source_optimized.sql"