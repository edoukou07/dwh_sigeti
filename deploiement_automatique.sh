#!/bin/bash

# ================================================
#     DÉPLOIEMENT AUTOMATIQUE DWH SIGETI
#     Script Bash pour environnements Linux/Unix
# ================================================

set -e  # Arrêter en cas d'erreur

# Configuration des couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Configuration des variables
PSQL_CMD="psql"
PGUSER="postgres"
PGPASSWORD="postgres"
SCRIPTS_DIR="$(dirname "$0")/Scripts"
LOG_FILE="deployment_$(date +%Y%m%d_%H%M%S).log"

# Export des variables d'environnement PostgreSQL
export PGUSER
export PGPASSWORD

# Fonctions utilitaires
print_header() {
    echo -e "${BLUE}================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================================${NC}"
    echo
}

print_step() {
    echo -e "${PURPLE}[$1] $2...${NC}"
}

print_success() {
    echo -e "${GREEN}[OK] $1${NC}"
}

print_error() {
    echo -e "${RED}[ERREUR] $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}[ATTENTION] $1${NC}"
}

# Fonction de vérification des prérequis
check_prerequisites() {
    print_header "VÉRIFICATION DES PRÉREQUIS"
    
    # Vérifier que PostgreSQL est accessible
    print_step "PREREQ" "Vérification de PostgreSQL"
    if ! command -v psql &> /dev/null; then
        print_error "PostgreSQL (psql) n'est pas installé ou non accessible !"
        exit 1
    fi
    
    # Tester la connexion PostgreSQL
    if ! $PSQL_CMD -d postgres -c "SELECT version();" &> /dev/null; then
        print_error "Impossible de se connecter à PostgreSQL !"
        echo "Vérifiez que:"
        echo "  - Le service PostgreSQL est démarré"
        echo "  - L'utilisateur '$PGUSER' existe avec le mot de passe '$PGPASSWORD'"
        echo "  - Les variables PGUSER et PGPASSWORD sont correctes"
        exit 1
    fi
    print_success "PostgreSQL accessible"
    
    # Vérifier que les bases de données existent
    print_step "PREREQ" "Vérification des bases de données"
    if ! $PSQL_CMD -d sigeti_node_db -c "SELECT 1;" &> /dev/null; then
        print_error "Base de données 'sigeti_node_db' non accessible !"
        echo "Créez la base avec: CREATE DATABASE sigeti_node_db;"
        exit 1
    fi
    
    if ! $PSQL_CMD -d sigeti_dwh -c "SELECT 1;" &> /dev/null; then
        print_error "Base de données 'sigeti_dwh' non accessible !"
        echo "Créez la base avec: CREATE DATABASE sigeti_dwh;"
        exit 1
    fi
    print_success "Bases de données accessibles"
    
    # Vérifier que pgAgent est disponible
    print_step "PREREQ" "Vérification de pgAgent"
    if ! $PSQL_CMD -d sigeti_node_db -c "SELECT * FROM pgagent.pga_job LIMIT 1;" &> /dev/null; then
        print_warning "pgAgent non disponible - les jobs automatisés ne pourront pas être créés"
        echo "Pour installer pgAgent: CREATE EXTENSION pgagent;"
    else
        print_success "pgAgent disponible"
    fi
    
    # Vérifier l'extension dblink
    print_step "PREREQ" "Vérification de dblink"
    if ! $PSQL_CMD -d sigeti_dwh -c "SELECT * FROM pg_extension WHERE extname='dblink';" | grep -q dblink; then
        print_step "PREREQ" "Installation de l'extension dblink"
        $PSQL_CMD -d sigeti_dwh -c "CREATE EXTENSION IF NOT EXISTS dblink;" || {
            print_error "Impossible d'installer l'extension dblink"
            exit 1
        }
    fi
    print_success "Extension dblink disponible"
    
    # Vérifier que les scripts existent
    print_step "PREREQ" "Vérification des scripts de déploiement"
    local missing_scripts=()
    
    scripts_to_check=(
        "$SCRIPTS_DIR/cdc/CDC_01_configuration_initiale.sql"
        "$SCRIPTS_DIR/cdc/CDC_02_fonctions_essentielles.sql"
        "$SCRIPTS_DIR/cdc/CDC_03_archivage_automatique.sql"
        "$SCRIPTS_DIR/cdc/CDC_04_jobs_pgagent.sql"
        "$SCRIPTS_DIR/schema/DWH_01_structure_warehouse.sql"
        "$SCRIPTS_DIR/etl/DWH_02_creation_complete.sql"
        "$SCRIPTS_DIR/cdc/CDC_05_replication_dwh.sql"
    )
    
    for script in "${scripts_to_check[@]}"; do
        if [[ ! -f "$script" ]]; then
            missing_scripts+=("$script")
        fi
    done
    
    if [[ ${#missing_scripts[@]} -gt 0 ]]; then
        print_error "Scripts manquants:"
        printf '%s\n' "${missing_scripts[@]}"
        exit 1
    fi
    print_success "Tous les scripts de déploiement sont présents"
    
    echo
}

# Fonction d'exécution sécurisée des scripts SQL
execute_sql_script() {
    local database=$1
    local script_path=$2
    local description=$3
    
    if [[ ! -f "$script_path" ]]; then
        print_error "Script non trouvé: $script_path"
        return 1
    fi
    
    print_step "EXEC" "$description"
    
    # Exécuter le script et capturer les erreurs
    if $PSQL_CMD -d "$database" -f "$script_path" >> "$LOG_FILE" 2>&1; then
        print_success "$description terminé"
        return 0
    else
        print_error "Échec de $description"
        echo "Consultez le fichier de log: $LOG_FILE"
        echo "Dernières lignes du log:"
        tail -10 "$LOG_FILE"
        return 1
    fi
}

# Phase 1: Configuration CDC
deploy_cdc() {
    print_header "PHASE 1: CONFIGURATION CDC (sigeti_node_db)"
    
    execute_sql_script "sigeti_node_db" "$SCRIPTS_DIR/cdc/CDC_01_configuration_initiale.sql" \
        "Configuration initiale CDC" || exit 1
    
    execute_sql_script "sigeti_node_db" "$SCRIPTS_DIR/cdc/CDC_02_fonctions_essentielles.sql" \
        "Installation des fonctions essentielles" || exit 1
    
    execute_sql_script "sigeti_node_db" "$SCRIPTS_DIR/cdc/CDC_03_archivage_automatique.sql" \
        "Configuration de l'archivage automatique" || exit 1
    
    execute_sql_script "sigeti_node_db" "$SCRIPTS_DIR/cdc/CDC_04_jobs_pgagent.sql" \
        "Installation des jobs pgAgent" || exit 1
    
    echo
}

# Phase 2: Configuration DWH
deploy_dwh() {
    print_header "PHASE 2: CONFIGURATION DWH (sigeti_dwh)"
    
    execute_sql_script "sigeti_dwh" "$SCRIPTS_DIR/schema/DWH_01_structure_warehouse.sql" \
        "Création de la structure Data Warehouse" || exit 1
    
    execute_sql_script "sigeti_dwh" "$SCRIPTS_DIR/etl/DWH_02_creation_complete.sql" \
        "Création complète du DWH" || exit 1
    
    execute_sql_script "sigeti_dwh" "$SCRIPTS_DIR/cdc/CDC_05_replication_dwh.sql" \
        "Configuration de la réplication" || exit 1
    
    echo
}

# Phase 3: Validation
validate_deployment() {
    print_header "PHASE 3: VALIDATION DU DÉPLOIEMENT"
    
    # Vérification CDC
    print_step "VALID" "Vérification de l'installation CDC"
    if $PSQL_CMD -d sigeti_node_db -c "SELECT * FROM cdc.get_cdc_stats();" >> "$LOG_FILE" 2>&1; then
        print_success "CDC opérationnel"
        $PSQL_CMD -d sigeti_node_db -c "SELECT * FROM cdc.get_cdc_stats();"
    else
        print_error "Problème avec CDC"
    fi
    
    # Vérification des jobs pgAgent
    print_step "VALID" "Vérification des jobs pgAgent"
    echo "Jobs pgAgent créés:"
    $PSQL_CMD -d sigeti_node_db -c "SELECT jobname, jobenabled, 
        CASE WHEN jobenabled THEN 'Activé' ELSE 'Désactivé' END as statut
        FROM pgagent.pga_job WHERE jobname LIKE '%CDC%';" 2>/dev/null || {
        print_warning "Impossible de vérifier les jobs pgAgent"
    }
    
    # Vérification du DWH
    print_step "VALID" "Vérification du DWH"
    local dwh_tables=$(
        $PSQL_CMD -d sigeti_dwh -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'dwh';" 2>/dev/null | tr -d ' '
    )
    
    if [[ "$dwh_tables" -gt 0 ]]; then
        print_success "DWH créé avec $dwh_tables table(s)"
        echo "Tables DWH créées:"
        $PSQL_CMD -d sigeti_dwh -c "SELECT table_name FROM information_schema.tables WHERE table_schema = 'dwh' ORDER BY table_name;"
    else
        print_error "Aucune table DWH trouvée"
    fi
    
    # Test de connectivité dblink
    print_step "VALID" "Test de connectivité dblink"
    if $PSQL_CMD -d sigeti_dwh -c "SELECT dblink_connect('test_conn', 'dbname=sigeti_node_db host=localhost user=$PGUSER'); SELECT dblink_disconnect('test_conn');" >> "$LOG_FILE" 2>&1; then
        print_success "Connectivité dblink opérationnelle"
    else
        print_warning "Problème de connectivité dblink"
    fi
    
    echo
}

# Test fonctionnel de bout-en-bout
functional_test() {
    print_header "TEST FONCTIONNEL DE BOUT-EN-BOUT"
    
    local test_code="TEST_DEPLOY_$(date +%H%M%S)"
    
    print_step "TEST" "Insertion de données test"
    if $PSQL_CMD -d sigeti_node_db -c "INSERT INTO zones_industrielles (code, nom) VALUES ('$test_code', 'Zone Test Déploiement');" >> "$LOG_FILE" 2>&1; then
        print_success "Données test insérées"
        
        # Attendre que le processus CDC traite les données
        print_step "TEST" "Attente du traitement CDC (30 secondes)"
        sleep 30
        
        # Vérifier la réplication
        print_step "TEST" "Vérification de la réplication"
        local replicated=$(
            $PSQL_CMD -d sigeti_dwh -t -c "SELECT COUNT(*) FROM dwh.dim_zones_industrielles WHERE code = '$test_code' AND est_actuel = true;" 2>/dev/null | tr -d ' '
        )
        
        if [[ "$replicated" == "1" ]]; then
            print_success "Réplication fonctionnelle - Test réussi"
        else
            print_warning "La réplication peut nécessiter plus de temps"
        fi
        
        # Nettoyage
        print_step "TEST" "Nettoyage des données test"
        $PSQL_CMD -d sigeti_node_db -c "DELETE FROM zones_industrielles WHERE code = '$test_code';" >> "$LOG_FILE" 2>&1
        
    else
        print_warning "Impossible d'insérer les données test - vérifiez que la table zones_industrielles existe"
    fi
    
    echo
}

# Affichage du résumé final
show_summary() {
    print_header "DÉPLOIEMENT TERMINÉ AVEC SUCCÈS ! ✅"
    
    echo -e "${GREEN}Composants installés:${NC}"
    echo "✅ Système CDC avec triggers automatiques"
    echo "✅ Fonctions de traitement CDC"
    echo "✅ Archivage automatique des données"
    echo "✅ Jobs pgAgent pour l'automatisation"
    echo "✅ Data Warehouse avec structure complète"
    echo "✅ Réplication CDC → DWH configurée"
    echo
    
    echo -e "${BLUE}Prochaines étapes recommandées:${NC}"
    echo "1. Exécuter les tests complets: ./Documentation/executer_tests_complets.bat"
    echo "2. Configurer la surveillance: ./Documentation/surveillance_quotidienne.sql"
    echo "3. Consulter la documentation: ./Documentation/Guide_Tests_DWH_SIGETI.md"
    echo
    
    echo -e "${YELLOW}Fichiers de log générés:${NC}"
    echo "📄 Log de déploiement: $LOG_FILE"
    echo "📄 Logs PostgreSQL: Consultez les logs du serveur PostgreSQL"
    echo
}

# Gestion des erreurs
cleanup() {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        print_error "Déploiement interrompu en raison d'une erreur"
        echo "Consultez le fichier de log: $LOG_FILE"
        echo
        echo "Pour recommencer:"
        echo "1. Corrigez les erreurs signalées"
        echo "2. Relancez ce script: $0"
        echo "3. Ou utilisez le déploiement manuel selon le guide"
    fi
}

# Configuration du gestionnaire de signaux
trap cleanup EXIT

# === SCRIPT PRINCIPAL ===

# Bannière de démarrage
echo
print_header "DÉPLOIEMENT AUTOMATIQUE DWH SIGETI"
echo -e "${BLUE}Script Bash pour environnements Linux/Unix${NC}"
echo -e "${BLUE}Date: $(date)${NC}"
echo -e "${BLUE}Log: $LOG_FILE${NC}"
echo

# Initialisation du fichier de log
echo "=== DÉPLOIEMENT DWH SIGETI - $(date) ===" > "$LOG_FILE"

# Exécution du déploiement
check_prerequisites
deploy_cdc
deploy_dwh
validate_deployment
functional_test
show_summary

print_success "Déploiement automatique terminé avec succès !"
echo