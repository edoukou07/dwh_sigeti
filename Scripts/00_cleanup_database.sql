-- Script pour fermer les connexions et nettoyer la base de données
SELECT pg_terminate_backend(pg_stat_activity.pid)
FROM pg_stat_activity
WHERE pg_stat_activity.datname = 'sigeti_dwh'
AND pid <> pg_backend_pid();

DROP DATABASE IF EXISTS sigeti_dwh;

CREATE DATABASE sigeti_dwh;