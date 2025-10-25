#!/bin/bash

# ===============================================
# 🔧 PRÉPARATION SCRIPTS BASH - TESTS DWH
# Rend tous les scripts exécutables et prêts
# ===============================================

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}===============================================${NC}"
echo -e "${BLUE}🔧 PRÉPARATION SCRIPTS BASH - TESTS DWH${NC}"
echo -e "${BLUE}===============================================${NC}"
echo

# Répertoire courant
current_dir="$(dirname "$0")"

# Rendre les scripts de test exécutables
echo -e "${YELLOW}Rendre les scripts de test exécutables...${NC}"
chmod +x "$current_dir"/executer_tests_complets.sh
chmod +x "$current_dir"/tests_helper.sh
echo -e "${GREEN}✅ Scripts de test rendus exécutables${NC}"

# Rendre les scripts de déploiement exécutables
echo -e "${YELLOW}Rendre les scripts de déploiement exécutables...${NC}"
chmod +x "$current_dir"/../deploiement_automatique.sh 2>/dev/null || true
chmod +x "$current_dir"/../deploy_helper.sh 2>/dev/null || true
chmod +x "$current_dir"/../setup_bash.sh 2>/dev/null || true
echo -e "${GREEN}✅ Scripts de déploiement rendus exécutables${NC}"

# Vérifier PostgreSQL
echo -e "${YELLOW}Vérification de PostgreSQL...${NC}"
if command -v psql &> /dev/null; then
    echo -e "${GREEN}✅ psql disponible${NC}"
    psql_version=$(psql --version | head -1)
    echo "   $psql_version"
else
    echo -e "\033[0;31m❌ psql non trouvé${NC}"
    echo "Installez PostgreSQL client:"
    echo "  Ubuntu/Debian: sudo apt install postgresql-client"
    echo "  CentOS/RHEL: sudo yum install postgresql"
    echo "  macOS: brew install postgresql"
fi

# Créer les variables d'environnement d'exemple
echo -e "${YELLOW}Création de l'exemple de configuration...${NC}"
cat > "$current_dir"/.env.example << 'EOF'
# Configuration PostgreSQL pour tests DWH SIGETI
# Copiez vers .env et modifiez selon votre environnement

export PGUSER="postgres"
export PGPASSWORD="postgres"
export PGHOST="localhost"
export PGPORT="5432"

# Pour charger:
# source .env
EOF
echo -e "${GREEN}✅ Fichier .env.example créé${NC}"

# Instructions d'utilisation
echo
echo -e "${BLUE}INSTRUCTIONS D'UTILISATION:${NC}"
echo
echo "1. Tests complets automatiques:"
echo "   ./executer_tests_complets.sh"
echo
echo "2. Helper de tests avec options:"
echo "   ./tests_helper.sh help"
echo
echo "3. Tests rapides seulement:"
echo "   ./tests_helper.sh quick"
echo
echo "4. Test individuel:"
echo "   ./tests_helper.sh single 5"
echo
echo "5. Configuration:"
echo "   ./tests_helper.sh setup"
echo

echo -e "${GREEN}Scripts bash de tests prêts à utiliser ! 🚀${NC}"