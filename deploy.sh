#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration
SITE_URL="https://astropieter.com"
DEPLOY_HOST="your-hostname"  # Replace with your actual hostname
DEPLOY_PATH="/path/to/your/site"  # Replace with your actual deployment path

echo -e "${BLUE}Starting deployment process...${NC}"

# Check if the site builds successfully
echo -e "${BLUE}Building site...${NC}"
if ! npm run build; then
    echo -e "${RED}Build failed! Aborting deployment.${NC}"
    exit 1
fi

# Check if astrosync exists and is executable
if [ -f "./astrosync" ] && [ -x "./astrosync" ]; then
    echo -e "${BLUE}Running astrosync deployment...${NC}"
    ./astrosync
else
    echo -e "${BLUE}Using rsync for deployment...${NC}"
    # Using rsync for deployment
    rsync -avz --delete \
        --exclude 'node_modules' \
        --exclude '.git' \
        --exclude '.DS_Store' \
        ./dist/ "${DEPLOY_HOST}:${DEPLOY_PATH}"
fi

echo -e "${GREEN}Deployment complete!${NC}"
echo -e "Your site should be live at: ${BLUE}${SITE_URL}${NC}" 