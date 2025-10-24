#!/usr/bin/env python3
import psycopg2
import time
import logging
from datetime import datetime

# Configuration du logging
logging.basicConfig(
    filename='cdc_process.log',
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)

# Configuration de la base de données
DB_CONFIG = {
    'source_db': {
        'dbname': 'sigeti_node_db',
        'user': 'postgres',
        'password': 'postgres',
        'host': 'localhost',
        'port': '5432'
    },
    'target_db': {
        'dbname': 'sigeti_dwh',
        'user': 'postgres',
        'password': 'postgres',
        'host': 'localhost',
        'port': '5432'
    }
}

def connect_db(config):
    """Établit une connexion à la base de données."""
    try:
        conn = psycopg2.connect(**config)
        return conn
    except Exception as e:
        logging.error(f"Erreur de connexion à la base de données: {str(e)}")
        raise

def process_changes():
    """Traite les changements CDC."""
    try:
        # Connexion à la base de données cible (DWH)
        conn_dwh = connect_db(DB_CONFIG['target_db'])
        cur_dwh = conn_dwh.cursor()
        
        # Exécuter la fonction de traitement des changements
        cur_dwh.execute("SELECT dwh.process_all_changes();")
        conn_dwh.commit()
        
        # Log du succès
        logging.info("Changements CDC traités avec succès")
        
    except Exception as e:
        logging.error(f"Erreur lors du traitement des changements CDC: {str(e)}")
        if 'conn_dwh' in locals():
            conn_dwh.rollback()
    finally:
        if 'cur_dwh' in locals():
            cur_dwh.close()
        if 'conn_dwh' in locals():
            conn_dwh.close()

def main():
    """Fonction principale qui exécute le processus CDC en continu."""
    logging.info("Démarrage du processus CDC")
    
    while True:
        try:
            process_changes()
            time.sleep(60)  # Attendre 1 minute avant la prochaine vérification
            
        except KeyboardInterrupt:
            logging.info("Arrêt du processus CDC")
            break
            
        except Exception as e:
            logging.error(f"Erreur inattendue: {str(e)}")
            time.sleep(300)  # En cas d'erreur, attendre 5 minutes avant de réessayer

if __name__ == "__main__":
    main()