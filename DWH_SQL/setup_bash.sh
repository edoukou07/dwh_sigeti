#!/bin/bash

# ================================================
#     PRÉPARATION SCRIPTS BASH - DWH SIGETI
#     Script de configuration initiale
# ================================================

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}    PRÉPARATION ENVIRONNEMENT BASH - DWH SIGETI${NC}"
echo -e "${BLUE}================================================${NC}"
echo

# Rendre les scripts exécutables
echo -e "${YELLOW}Rendre les scripts exécutables...${NC}"
chmod +x deploiement_automatique.sh
chmod +x deploy_helper.sh
echo -e "${GREEN}✅ Scripts rendus exécutables${NC}"

# Vérifier la disponibilité de psql
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

# Créer un exemple de configuration
echo -e "${YELLOW}Création de l'exemple de configuration...${NC}"
cat > .env.example << 'EOF'
# Configuration PostgreSQL pour déploiement DWH SIGETI
# Copiez ce fichier vers .env et modifiez selon votre environnement

export PGUSER="postgres"
export PGPASSWORD="postgres"
export PGHOST="localhost"
export PGPORT="5432"

# Pour charger cette configuration:
# source .env
EOF
echo -e "${GREEN}✅ Fichier .env.example créé${NC}"

# Afficher les instructions d'utilisation
echo
echo -e "${BLUE}INSTRUCTIONS D'UTILISATION:${NC}"
echo
echo "1. Configuration (recommandée):"
echo "   ./deploy_helper.sh config"
echo
echo "2. Vérification des prérequis:"
echo "   ./deploy_helper.sh prereq"
echo
echo "3. Déploiement automatique complet:"
echo "   ./deploiement_automatique.sh"
echo
echo "4. Aide complète:"
echo "   ./deploy_helper.sh help"
echo
echo -e "${GREEN}Scripts bash prêts à utiliser ! 🚀${NC}"