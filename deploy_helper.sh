#!/bin/bash

# ================================================
#     CONFIGURATION ET AIDE - DÉPLOIEMENT DWH
#     Script utilitaire pour le déploiement
# ================================================

# Configuration des couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================================${NC}"
}

show_help() {
    print_header "AIDE - DÉPLOIEMENT DWH SIGETI"
    echo
    echo -e "${GREEN}UTILISATION:${NC}"
    echo "  $0 [OPTION]"
    echo
    echo -e "${GREEN}OPTIONS:${NC}"
    echo "  help, -h, --help    Afficher cette aide"
    echo "  config              Configuration interactive"
    echo "  prereq              Vérifier les prérequis seulement"
    echo "  deploy              Lancer le déploiement complet"
    echo "  test                Tests post-déploiement seulement"
    echo "  clean               Nettoyer/réinitialiser le système"
    echo
    echo -e "${GREEN}EXEMPLES:${NC}"
    echo "  $0 config           # Configuration interactive"
    echo "  $0 prereq           # Vérification des prérequis"
    echo "  $0 deploy           # Déploiement automatique complet"
    echo
    echo -e "${GREEN}FICHIERS REQUIS:${NC}"
    echo "  Scripts/cdc/CDC_01_configuration_initiale.sql"
    echo "  Scripts/cdc/CDC_02_fonctions_essentielles.sql"
    echo "  Scripts/cdc/CDC_03_archivage_automatique.sql"
    echo "  Scripts/cdc/CDC_04_jobs_pgagent.sql"
    echo "  Scripts/schema/DWH_01_structure_warehouse.sql"
    echo "  Scripts/etl/DWH_02_creation_complete.sql"
    echo "  Scripts/cdc/CDC_05_replication_dwh.sql"
    echo
}

interactive_config() {
    print_header "CONFIGURATION INTERACTIVE"
    echo
    
    # Configuration PostgreSQL
    echo -e "${CYAN}Configuration PostgreSQL:${NC}"
    read -p "Utilisateur PostgreSQL [postgres]: " pg_user
    pg_user=${pg_user:-postgres}
    
    read -s -p "Mot de passe PostgreSQL [postgres]: " pg_password
    pg_password=${pg_password:-postgres}
    echo
    
    read -p "Hôte PostgreSQL [localhost]: " pg_host
    pg_host=${pg_host:-localhost}
    
    read -p "Port PostgreSQL [5432]: " pg_port
    pg_port=${pg_port:-5432}
    echo
    
    # Test de connexion
    echo -e "${YELLOW}Test de connexion...${NC}"
    export PGUSER="$pg_user"
    export PGPASSWORD="$pg_password"
    export PGHOST="$pg_host"
    export PGPORT="$pg_port"
    
    if psql -d postgres -c "SELECT version();" &>/dev/null; then
        echo -e "${GREEN}✅ Connexion PostgreSQL réussie${NC}"
    else
        echo -e "${RED}❌ Échec de connexion PostgreSQL${NC}"
        echo "Vérifiez vos paramètres et réessayez"
        return 1
    fi
    
    # Sauvegarde de la configuration
    cat > .env << EOF
# Configuration PostgreSQL pour déploiement DWH SIGETI
export PGUSER="$pg_user"
export PGPASSWORD="$pg_password"
export PGHOST="$pg_host"
export PGPORT="$pg_port"
EOF
    
    echo -e "${GREEN}✅ Configuration sauvegardée dans .env${NC}"
    echo "Pour charger la configuration: source .env"
    echo
}

check_prerequisites_only() {
    print_header "VÉRIFICATION DES PRÉREQUIS UNIQUEMENT"
    echo
    
    # Charger la configuration si elle existe
    [[ -f .env ]] && source .env
    
    local errors=0
    
    # Vérifier PostgreSQL
    echo -e "${CYAN}Vérification PostgreSQL...${NC}"
    if command -v psql &>/dev/null; then
        echo -e "${GREEN}✅ psql installé${NC}"
    else
        echo -e "${RED}❌ psql non trouvé${NC}"
        ((errors++))
    fi
    
    if psql -d postgres -c "SELECT version();" &>/dev/null; then
        local version=$(psql -d postgres -t -c "SELECT version();" | head -1)
        echo -e "${GREEN}✅ PostgreSQL accessible: $version${NC}"
    else
        echo -e "${RED}❌ PostgreSQL non accessible${NC}"
        ((errors++))
    fi
    
    # Vérifier les bases de données
    echo -e "${CYAN}Vérification des bases de données...${NC}"
    for db in sigeti_node_db sigeti_dwh; do
        if psql -d "$db" -c "SELECT 1;" &>/dev/null; then
            echo -e "${GREEN}✅ Base '$db' accessible${NC}"
        else
            echo -e "${RED}❌ Base '$db' non accessible${NC}"
            ((errors++))
        fi
    done
    
    # Vérifier pgAgent
    echo -e "${CYAN}Vérification pgAgent...${NC}"
    if psql -d sigeti_node_db -c "SELECT * FROM pgagent.pga_job LIMIT 1;" &>/dev/null; then
        echo -e "${GREEN}✅ pgAgent disponible${NC}"
    else
        echo -e "${YELLOW}⚠️  pgAgent non disponible${NC}"
    fi
    
    # Vérifier dblink
    echo -e "${CYAN}Vérification dblink...${NC}"
    if psql -d sigeti_dwh -c "SELECT * FROM pg_extension WHERE extname='dblink';" | grep -q dblink; then
        echo -e "${GREEN}✅ Extension dblink installée${NC}"
    else
        echo -e "${YELLOW}⚠️  Extension dblink non installée${NC}"
    fi
    
    # Vérifier les scripts
    echo -e "${CYAN}Vérification des scripts...${NC}"
    local script_dir="$(dirname "$0")/Scripts"
    local scripts=(
        "cdc/CDC_01_configuration_initiale.sql"
        "cdc/CDC_02_fonctions_essentielles.sql"
        "cdc/CDC_03_archivage_automatique.sql"
        "cdc/CDC_04_jobs_pgagent.sql"
        "schema/DWH_01_structure_warehouse.sql"
        "etl/DWH_02_creation_complete.sql"
        "cdc/CDC_05_replication_dwh.sql"
    )
    
    local missing_scripts=0
    for script in "${scripts[@]}"; do
        if [[ -f "$script_dir/$script" ]]; then
            echo -e "${GREEN}✅ $script${NC}"
        else
            echo -e "${RED}❌ $script manquant${NC}"
            ((missing_scripts++))
        fi
    done
    
    echo
    if [[ $errors -eq 0 && $missing_scripts -eq 0 ]]; then
        echo -e "${GREEN}🎉 Tous les prérequis sont satisfaits !${NC}"
        echo -e "${GREEN}Vous pouvez lancer le déploiement avec: $0 deploy${NC}"
        return 0
    else
        echo -e "${RED}❌ $errors erreur(s) et $missing_scripts script(s) manquant(s)${NC}"
        echo -e "${YELLOW}Corrigez les problèmes avant de continuer${NC}"
        return 1
    fi
}

run_tests_only() {
    print_header "TESTS POST-DÉPLOIEMENT UNIQUEMENT"
    echo
    
    [[ -f .env ]] && source .env
    
    # Tests rapides
    echo -e "${CYAN}Tests rapides...${NC}"
    
    # Test CDC
    if psql -d sigeti_node_db -c "SELECT * FROM cdc.get_cdc_stats();" &>/dev/null; then
        echo -e "${GREEN}✅ CDC opérationnel${NC}"
        psql -d sigeti_node_db -c "SELECT * FROM cdc.get_cdc_stats();"
    else
        echo -e "${RED}❌ CDC non opérationnel${NC}"
    fi
    
    # Test DWH
    local dwh_tables=$(psql -d sigeti_dwh -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'dwh';" 2>/dev/null | tr -d ' ')
    if [[ "$dwh_tables" -gt 0 ]]; then
        echo -e "${GREEN}✅ DWH créé avec $dwh_tables table(s)${NC}"
    else
        echo -e "${RED}❌ Aucune table DWH trouvée${NC}"
    fi
    
    # Test jobs pgAgent
    echo -e "${CYAN}Jobs pgAgent:${NC}"
    psql -d sigeti_node_db -c "SELECT jobname, jobenabled FROM pgagent.pga_job WHERE jobname LIKE '%CDC%';" 2>/dev/null || echo "Aucun job trouvé"
    
    echo
}

clean_system() {
    print_header "NETTOYAGE/RÉINITIALISATION DU SYSTÈME"
    echo
    echo -e "${RED}⚠️  ATTENTION: Cette opération va supprimer toutes les données CDC et DWH !${NC}"
    echo
    read -p "Êtes-vous sûr de vouloir continuer? [y/N]: " confirm
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        [[ -f .env ]] && source .env
        
        echo -e "${YELLOW}Nettoyage en cours...${NC}"
        
        # Nettoyage sigeti_node_db
        psql -d sigeti_node_db -c "
            DROP SCHEMA IF EXISTS cdc CASCADE;
            DELETE FROM pgagent.pga_job WHERE jobname LIKE '%CDC%';
        " 2>/dev/null
        
        # Nettoyage sigeti_dwh
        psql -d sigeti_dwh -c "DROP SCHEMA IF EXISTS dwh CASCADE;" 2>/dev/null
        
        echo -e "${GREEN}✅ Nettoyage terminé${NC}"
        echo "Vous pouvez maintenant relancer le déploiement"
    else
        echo "Nettoyage annulé"
    fi
}

# Script principal
case "${1:-}" in
    "help"|"-h"|"--help")
        show_help
        ;;
    "config")
        interactive_config
        ;;
    "prereq")
        check_prerequisites_only
        ;;
    "deploy")
        echo "Lancement du déploiement complet..."
        exec "$(dirname "$0")/deploiement_automatique.sh"
        ;;
    "test")
        run_tests_only
        ;;
    "clean")
        clean_system
        ;;
    "")
        show_help
        ;;
    *)
        echo -e "${RED}Option inconnue: $1${NC}"
        echo "Utilisez '$0 help' pour voir les options disponibles"
        exit 1
        ;;
esac