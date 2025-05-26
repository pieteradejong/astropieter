#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Initializing Astro Blog Project...${NC}"

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "Node.js is not installed. Please install Node.js first."
    exit 1
fi

# Check if npm is installed
if ! command -v npm &> /dev/null; then
    echo "npm is not installed. Please install npm first."
    exit 1
fi

# Install dependencies
echo -e "${BLUE}Installing dependencies...${NC}"
npm install

# Make scripts executable
chmod +x deploy.sh

echo -e "${GREEN}Initialization complete!${NC}"
echo -e "To start development, run: ${BLUE}npm run dev${NC}"
echo -e "To build the site, run: ${BLUE}npm run build${NC}"
echo -e "To deploy the site, run: ${BLUE}./deploy.sh${NC}" 