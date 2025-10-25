#!/bin/bash

# ===============================================
# 🧪 HELPER TESTS DWH SIGETI
# Utilitaire pour gérer les tests
# ===============================================

# Configuration des couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}===============================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}===============================================${NC}"
}

show_help() {
    print_header "🧪 HELPER TESTS DWH SIGETI"
    echo
    echo -e "${GREEN}UTILISATION:${NC}"
    echo "  $0 [OPTION]"
    echo
    echo -e "${GREEN}OPTIONS:${NC}"
    echo "  help, -h, --help    Afficher cette aide"
    echo "  all                 Exécuter tous les tests (défaut)"
    echo "  quick               Tests rapides seulement (1-3)"
    echo "  functional          Tests fonctionnels (4-7)"
    echo "  performance         Tests de performance (10)"
    echo "  single <num>        Exécuter un test spécifique (1-10)"
    echo "  setup               Préparer l'environnement de test"
    echo "  clean               Nettoyer les logs de test"
    echo
    echo -e "${GREEN}EXEMPLES:${NC}"
    echo "  $0                  # Tous les tests"
    echo "  $0 quick           # Tests rapides"  
    echo "  $0 single 5        # Test 5 seulement"
    echo "  $0 setup           # Préparation"
    echo
    echo -e "${GREEN}TESTS DISPONIBLES:${NC}"
    echo "  1. Prérequis système"
    echo "  2. Structure CDC"
    echo "  3. Structure DWH"
    echo "  4-7. Tests fonctionnels"
    echo "  8. Jobs pgAgent"
    echo "  9. Archivage CDC"
    echo "  10. Performance"
    echo
}

setup_environment() {
    print_header "🔧 PRÉPARATION ENVIRONNEMENT TESTS"
    echo
    
    local script_dir="$(dirname "$0")"
    
    # Rendre les scripts exécutables
    echo -e "${YELLOW}Rendre les scripts de test exécutables...${NC}"
    chmod +x "$script_dir"/executer_tests_complets.sh 2>/dev/null || true
    chmod +x "$script_dir"/../*.sh 2>/dev/null || true
    echo -e "${GREEN}✅ Scripts rendus exécutables${NC}"
    
    # Vérifier PostgreSQL
    echo -e "${YELLOW}Vérification de PostgreSQL...${NC}"
    if command -v psql &> /dev/null; then
        echo -e "${GREEN}✅ psql disponible${NC}"
        if psql -d postgres -c "SELECT version();" &> /dev/null 2>&1; then
            echo -e "${GREEN}✅ PostgreSQL accessible${NC}"
        else
            echo -e "${RED}❌ PostgreSQL non accessible${NC}"
        fi
    else
        echo -e "${RED}❌ psql non trouvé${NC}"
        echo "Installez PostgreSQL client ou ajustez le PATH"
    fi
    
    # Vérifier les bases
    echo -e "${YELLOW}Vérification des bases de données...${NC}"
    for db in sigeti_node_db sigeti_dwh; do
        if psql -d "$db" -c "SELECT 1;" &> /dev/null 2>&1; then
            echo -e "${GREEN}✅ Base '$db' accessible${NC}"
        else
            echo -e "${RED}❌ Base '$db' non accessible${NC}"
        fi
    done
    
    # Vérifier les scripts de test
    echo -e "${YELLOW}Vérification des scripts de test...${NC}"
    local scripts_dir="$script_dir/Scripts_Tests"
    if [[ -d "$scripts_dir" ]]; then
        local count=$(find "$scripts_dir" -name "*.sql" | wc -l)
        echo -e "${GREEN}✅ $count script(s) de test trouvé(s)${NC}"
    else
        echo -e "${RED}❌ Dossier Scripts_Tests non trouvé${NC}"
    fi
    
    echo
    echo -e "${CYAN}Environnement prêt pour les tests !${NC}"
}

run_quick_tests() {
    print_header "⚡ TESTS RAPIDES (1-3)"
    echo
    
    local script_dir="$(dirname "$0")"
    export PGPASSWORD="postgres"
    
    echo -e "${CYAN}Exécution des tests essentiels...${NC}"
    
    # Tests 1-3 seulement
    for test_num in 1 2 3; do
        case $test_num in
            1) 
                echo -e "${YELLOW}Test 1: Prérequis...${NC}"
                psql -U postgres -d sigeti_node_db -f "$script_dir/Scripts_Tests/test_1_prerequis.sql"
                ;;
            2)
                echo -e "${YELLOW}Test 2: Structure CDC...${NC}" 
                psql -U postgres -d sigeti_node_db -f "$script_dir/Scripts_Tests/test_2_structure_cdc.sql"
                ;;
            3)
                echo -e "${YELLOW}Test 3: Structure DWH...${NC}"
                psql -U postgres -d sigeti_dwh -f "$script_dir/Scripts_Tests/test_3_structure_dwh.sql"
                ;;
        esac
        
        if [[ $? -eq 0 ]]; then
            echo -e "${GREEN}✅ Test $test_num réussi${NC}"
        else
            echo -e "${RED}❌ Test $test_num échoué${NC}"
            exit 1
        fi
        echo
    done
    
    echo -e "${GREEN}🎉 Tests rapides terminés avec succès !${NC}"
}

run_single_test() {
    local test_num=$1
    print_header "🔍 TEST INDIVIDUEL $test_num"
    echo
    
    if [[ ! "$test_num" =~ ^[1-9]|10$ ]]; then
        echo -e "${RED}❌ Numéro de test invalide: $test_num${NC}"
        echo "Utilisez un numéro entre 1 et 10"
        exit 1
    fi
    
    local script_dir="$(dirname "$0")"
    export PGPASSWORD="postgres"
    
    echo -e "${CYAN}Exécution du test $test_num...${NC}"
    
    case $test_num in
        1) psql -U postgres -d sigeti_node_db -f "$script_dir/Scripts_Tests/test_1_prerequis.sql" ;;
        2) psql -U postgres -d sigeti_node_db -f "$script_dir/Scripts_Tests/test_2_structure_cdc.sql" ;;
        3) psql -U postgres -d sigeti_dwh -f "$script_dir/Scripts_Tests/test_3_structure_dwh.sql" ;;
        4|5|6|7) psql -U postgres -d sigeti_node_db -f "$script_dir/Scripts_Tests/test_4_7_fonctionnels.sql" ;;
        8) psql -U postgres -d sigeti_node_db -f "$script_dir/Scripts_Tests/test_8_jobs.sql" ;;
        9) psql -U postgres -d sigeti_node_db -f "$script_dir/Scripts_Tests/test_9_archivage.sql" ;;
        10) psql -U postgres -d sigeti_node_db -f "$script_dir/Scripts_Tests/test_10_performance.sql" ;;
    esac
    
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}✅ Test $test_num réussi !${NC}"
    else
        echo -e "${RED}❌ Test $test_num échoué${NC}"
        exit 1
    fi
}

clean_logs() {
    print_header "🧹 NETTOYAGE DES LOGS"
    echo
    
    local script_dir="$(dirname "$0")"
    local count=0
    
    # Supprimer les anciens logs de test
    for log in "$script_dir"/tests_complets_*.log; do
        if [[ -f "$log" ]]; then
            rm "$log"
            ((count++))
        fi
    done
    
    if [[ $count -gt 0 ]]; then
        echo -e "${GREEN}✅ $count fichier(s) de log supprimé(s)${NC}"
    else
        echo -e "${YELLOW}ℹ️  Aucun log à nettoyer${NC}"
    fi
}

# Script principal
case "${1:-all}" in
    "help"|"-h"|"--help")
        show_help
        ;;
    "all"|"")
        echo -e "${BLUE}Lancement des tests complets...${NC}"
        exec "$(dirname "$0")/executer_tests_complets.sh"
        ;;
    "quick")
        run_quick_tests
        ;;
    "functional")
        echo -e "${BLUE}Tests fonctionnels (4-7)...${NC}"
        run_single_test 4
        ;;
    "performance")
        echo -e "${BLUE}Tests de performance (10)...${NC}"
        run_single_test 10
        ;;
    "single")
        if [[ -z "$2" ]]; then
            echo -e "${RED}❌ Numéro de test requis${NC}"
            echo "Usage: $0 single <num>"
            exit 1
        fi
        run_single_test "$2"
        ;;
    "setup")
        setup_environment
        ;;
    "clean")
        clean_logs
        ;;
    *)
        echo -e "${RED}Option inconnue: $1${NC}"
        echo "Utilisez '$0 help' pour voir les options disponibles"
        exit 1
        ;;
esac