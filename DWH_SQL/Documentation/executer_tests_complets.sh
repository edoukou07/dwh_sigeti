#!/bin/bash

# ===============================================
# 🧪 TESTS ENTREPOT DE DONNEES SIGETI
# Script bash équivalent à executer_tests_complets.bat
# ===============================================

set -e  # Arrêter en cas d'erreur

# Configuration des couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
export PGPASSWORD="postgres"
PSQL_CMD="psql"
PGUSER="postgres"
SOURCE_DB="sigeti_node_db"
DWH_DB="sigeti_dwh"
SCRIPTS_DIR="$(dirname "$0")/Scripts_Tests"
LOG_FILE="tests_complets_$(date +%Y%m%d_%H%M%S).log"

# Export des variables PostgreSQL
export PGUSER

# Fonctions utilitaires
print_header() {
    echo -e "${BLUE}===============================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}===============================================${NC}"
    echo
}

print_test() {
    echo -e "${CYAN}✅ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1 RÉUSSI${NC}"
    echo
}

print_error() {
    echo -e "${RED}❌ ÉCHEC $1${NC}"
    echo -e "${RED}Consultez le log: $LOG_FILE${NC}"
    echo "Dernières lignes du log:"
    tail -10 "$LOG_FILE" 2>/dev/null || echo "Pas de log disponible"
    exit 1
}

print_step() {
    echo -e "${YELLOW}  - $1${NC}"
}

# Fonction d'exécution sécurisée des scripts SQL
execute_test() {
    local test_name="$1"
    local database="$2"
    local script_path="$3"
    
    if [[ ! -f "$script_path" ]]; then
        echo -e "${RED}❌ Script non trouvé: $script_path${NC}"
        exit 1
    fi
    
    if $PSQL_CMD -d "$database" -f "$script_path" >> "$LOG_FILE" 2>&1; then
        print_success "$test_name"
        return 0
    else
        print_error "$test_name"
        return 1
    fi
}

# Bannière de démarrage
print_header "🧪 TESTS ENTREPOT DE DONNEES SIGETI"

# Initialisation du log
echo "=== TESTS COMPLETS DWH SIGETI - $(date) ===" > "$LOG_FILE"

# Vérification des prérequis
echo -e "${PURPLE}🔧 Configuration:${NC}"
echo "- Base source: $SOURCE_DB"
echo "- Base DWH: $DWH_DB"  
echo "- Scripts: $SCRIPTS_DIR"
echo "- Log: $LOG_FILE"
echo

# Vérifier que PostgreSQL est accessible
if ! command -v psql &> /dev/null; then
    echo -e "${RED}❌ PostgreSQL (psql) non trouvé !${NC}"
    exit 1
fi

if ! $PSQL_CMD -d postgres -c "SELECT version();" &> /dev/null; then
    echo -e "${RED}❌ Impossible de se connecter à PostgreSQL !${NC}"
    echo "Vérifiez que le service PostgreSQL est démarré"
    exit 1
fi

# Vérifier que le dossier de scripts existe
if [[ ! -d "$SCRIPTS_DIR" ]]; then
    echo -e "${RED}❌ ERREUR: Dossier Scripts_Tests non trouvé${NC}"
    echo "Chemin attendu: $SCRIPTS_DIR"
    exit 1
fi

# Vérifier l'accès aux bases de données
for db in "$SOURCE_DB" "$DWH_DB"; do
    if ! $PSQL_CMD -d "$db" -c "SELECT 1;" &> /dev/null; then
        echo -e "${RED}❌ Base de données '$db' non accessible !${NC}"
        exit 1
    fi
done

echo -e "${GREEN}✅ Prérequis validés${NC}"
echo

# === EXÉCUTION DES TESTS ===

# Test 1: Prérequis
print_test "Test 1: Vérification des prérequis..."
execute_test "Test 1" "$SOURCE_DB" "$SCRIPTS_DIR/test_1_prerequis.sql"

# Test 2: Structure CDC  
print_test "Test 2: Structure CDC..."
execute_test "Test 2" "$SOURCE_DB" "$SCRIPTS_DIR/test_2_structure_cdc.sql"

# Test 3: Structure DWH
print_test "Test 3: Structure DWH..."
execute_test "Test 3" "$DWH_DB" "$SCRIPTS_DIR/test_3_structure_dwh.sql"

# Tests 4-7: Tests fonctionnels
print_test "Tests 4-7: Tests fonctionnels..."
print_step "Exécution dans la base source..."
execute_test "Tests 4-7 (partie source)" "$SOURCE_DB" "$SCRIPTS_DIR/test_4_7_fonctionnels.sql"

print_step "Exécution dans le DWH..."
execute_test "Tests 4-7 (partie DWH)" "$DWH_DB" "$SCRIPTS_DIR/test_5_traitement_dwh.sql"

# Test 8: Jobs pgAgent
print_test "Test 8: Jobs pgAgent..."
execute_test "Test 8" "$SOURCE_DB" "$SCRIPTS_DIR/test_8_jobs.sql"

# Test 9: Archivage
print_test "Test 9: Archivage CDC..."
execute_test "Test 9" "$SOURCE_DB" "$SCRIPTS_DIR/test_9_archivage.sql"

# Test 10: Performance
print_test "Test 10: Performance..."
print_step "Partie source..."
execute_test "Test 10 (partie source)" "$SOURCE_DB" "$SCRIPTS_DIR/test_10_performance.sql"

print_step "Partie DWH..."
execute_test "Test 10 (partie DWH)" "$DWH_DB" "$SCRIPTS_DIR/test_10_performance_dwh.sql"

# === RÉSUMÉ FINAL ===

print_header "🎉 TOUS LES TESTS SONT RÉUSSIS !"

echo -e "${PURPLE}📊 Résumé:${NC}"
echo -e "${GREEN}✅ Test 1 - Prérequis${NC}"
echo -e "${GREEN}✅ Test 2 - Structure CDC${NC}"  
echo -e "${GREEN}✅ Test 3 - Structure DWH${NC}"
echo -e "${GREEN}✅ Test 4-7 - Tests fonctionnels${NC}"
echo -e "${GREEN}✅ Test 8 - Jobs pgAgent${NC}"
echo -e "${GREEN}✅ Test 9 - Archivage CDC${NC}"
echo -e "${GREEN}✅ Test 10 - Performance${NC}"
echo

echo -e "${CYAN}🚀 L'entrepôt de données SIGETI est opérationnel !${NC}"
echo

echo -e "${YELLOW}📄 Logs générés:${NC}"
echo "- Log des tests: $LOG_FILE"
echo "- Logs PostgreSQL: Consultez les logs du serveur"
echo

# Statistiques finales
echo -e "${PURPLE}📈 Statistiques:${NC}"
echo "- Durée des tests: $((SECONDS/60)) minute(s) $((SECONDS%60)) seconde(s)"
echo "- Tests exécutés: 10/10"
echo "- Taux de réussite: 100%"
echo

echo -e "${BLUE}Appuyez sur Entrée pour continuer...${NC}"
read -r