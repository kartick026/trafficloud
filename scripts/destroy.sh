#!/bin/bash

# AWS Traffic Prediction System Destruction Script
# This script destroys the entire infrastructure

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${RED}⚠️  WARNING: This will destroy all AWS resources!${NC}"
echo "This action cannot be undone."
echo ""
read -p "Are you sure you want to continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo -e "${YELLOW}❌ Destruction cancelled${NC}"
    exit 0
fi

echo -e "${YELLOW}🗑️  Starting infrastructure destruction...${NC}"

# Change to terraform directory
cd terraform

# Destroy infrastructure
echo -e "${YELLOW}🏗️  Destroying Terraform infrastructure...${NC}"
terraform destroy -auto-approve

echo -e "${GREEN}✅ Infrastructure destroyed successfully${NC}"

# Clean up local files
echo -e "${YELLOW}🧹 Cleaning up local files...${NC}"
cd ..
rm -rf lambda_packages
rm -rf sagemaker_packages
rm -f deployment-config.json
rm -f frontend/.env

echo -e "${GREEN}🎉 Cleanup completed successfully!${NC}"
echo "All AWS resources have been destroyed and local files cleaned up."
