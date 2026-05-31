#!/bin/bash

# Docker CI/CD Pipeline - Azure Deployment Script
# Pushes Docker image to ACR and deploys to Azure Web App

set -e

echo "=========================================="
echo "Azure Docker Deployment Script"
echo "=========================================="
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Configuration (Update these)
RESOURCE_GROUP="${1:-rg-docker-cicd}"
REGISTRY_NAME="${2:-acrdockercicd}"
WEBAPP_NAME="${3:-docker-cicd-app}"
IMAGE_NAME="docker-cicd-app"
IMAGE_TAG="latest"
LOCATION="eastus"

echo -e "${BLUE}Configuration:${NC}"
echo "├── Resource Group: $RESOURCE_GROUP"
echo "├── Registry Name: $REGISTRY_NAME"
echo "├── Web App Name: $WEBAPP_NAME"
echo "├── Image: $IMAGE_NAME:$IMAGE_TAG"
echo "└── Location: $LOCATION"
echo ""

# Step 1: Check prerequisites
echo -e "${YELLOW}Step 1: Checking Prerequisites${NC}"
command -v az &> /dev/null && echo "✅ Azure CLI installed" || { echo "❌ Azure CLI not found"; exit 1; }
command -v docker &> /dev/null && echo "✅ Docker installed" || { echo "❌ Docker not found"; exit 1; }
echo ""

# Step 2: Azure Login
echo -e "${YELLOW}Step 2: Azure Authentication${NC}"
az login --output none 2>/dev/null || echo "Already logged in"
echo "✅ Azure authenticated"
echo ""

# Step 3: Create Resource Group (if not exists)
echo -e "${YELLOW}Step 3: Setting up Resource Group${NC}"
if az group exists --name "$RESOURCE_GROUP" | grep -q true; then
    echo "✅ Resource group exists: $RESOURCE_GROUP"
else
    echo "Creating resource group: $RESOURCE_GROUP"
    az group create \
      --name "$RESOURCE_GROUP" \
      --location "$LOCATION"
    echo "✅ Resource group created"
fi
echo ""

# Step 4: Create ACR (if not exists)
echo -e "${YELLOW}Step 4: Setting up Azure Container Registry${NC}"
if az acr show --resource-group "$RESOURCE_GROUP" --name "$REGISTRY_NAME" &>/dev/null; then
    echo "✅ ACR exists: $REGISTRY_NAME"
else
    echo "Creating ACR: $REGISTRY_NAME"
    az acr create \
      --resource-group "$RESOURCE_GROUP" \
      --name "$REGISTRY_NAME" \
      --sku Basic
    echo "✅ ACR created"
fi
echo ""

# Step 5: Get ACR login credentials
echo -e "${YELLOW}Step 5: Getting ACR Credentials${NC}"
ACR_LOGIN_SERVER=$(az acr show \
  --resource-group "$RESOURCE_GROUP" \
  --name "$REGISTRY_NAME" \
  --query loginServer -o tsv)
echo "✅ ACR Login Server: $ACR_LOGIN_SERVER"
echo ""

# Step 6: Login to ACR
echo -e "${YELLOW}Step 6: Logging in to ACR${NC}"
az acr login --name "$REGISTRY_NAME"
echo "✅ Logged in to ACR"
echo ""

# Step 7: Tag Docker image for ACR
echo -e "${YELLOW}Step 7: Tagging Docker Image${NC}"
docker tag "$IMAGE_NAME:$IMAGE_TAG" "$ACR_LOGIN_SERVER/$IMAGE_NAME:$IMAGE_TAG"
docker tag "$IMAGE_NAME:$IMAGE_TAG" "$ACR_LOGIN_SERVER/$IMAGE_NAME:latest"
echo "✅ Image tagged for ACR"
echo ""

# Step 8: Push image to ACR
echo -e "${YELLOW}Step 8: Pushing Image to ACR${NC}"
docker push "$ACR_LOGIN_SERVER/$IMAGE_NAME:$IMAGE_TAG"
docker push "$ACR_LOGIN_SERVER/$IMAGE_NAME:latest"
echo "✅ Image pushed to ACR"
echo ""

# Step 9: Create App Service Plan (if not exists)
echo -e "${YELLOW}Step 9: Setting up App Service Plan${NC}"
PLAN_NAME="plan-docker-cicd"
if az appservice plan show --resource-group "$RESOURCE_GROUP" --name "$PLAN_NAME" &>/dev/null; then
    echo "✅ App Service Plan exists: $PLAN_NAME"
else
    echo "Creating App Service Plan: $PLAN_NAME"
    az appservice plan create \
      --name "$PLAN_NAME" \
      --resource-group "$RESOURCE_GROUP" \
      --sku B1 \
      --is-linux
    echo "✅ App Service Plan created"
fi
echo ""

# Step 10: Create Web App for Containers (if not exists)
echo -e "${YELLOW}Step 10: Setting up Azure Web App${NC}"
if az webapp show --resource-group "$RESOURCE_GROUP" --name "$WEBAPP_NAME" &>/dev/null; then
    echo "✅ Web App exists: $WEBAPP_NAME"
else
    echo "Creating Web App: $WEBAPP_NAME"
    az webapp create \
      --resource-group "$RESOURCE_GROUP" \
      --plan "$PLAN_NAME" \
      --name "$WEBAPP_NAME" \
      --deployment-container-image-name-user "$REGISTRY_NAME" \
      --deployment-container-image-name "$ACR_LOGIN_SERVER/$IMAGE_NAME:latest"
    echo "✅ Web App created"
fi
echo ""

# Step 11: Configure Web App with ACR credentials
echo -e "${YELLOW}Step 11: Configuring Web App ACR Access${NC}"
REGISTRY_USERNAME=$(az acr credential show \
  --resource-group "$RESOURCE_GROUP" \
  --name "$REGISTRY_NAME" \
  --query username -o tsv)
REGISTRY_PASSWORD=$(az acr credential show \
  --resource-group "$RESOURCE_GROUP" \
  --name "$REGISTRY_NAME" \
  --query "passwords[0].value" -o tsv)

az webapp config container set \
  --name "$WEBAPP_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --docker-custom-image-name "$ACR_LOGIN_SERVER/$IMAGE_NAME:latest" \
  --docker-registry-server-url "https://$ACR_LOGIN_SERVER" \
  --docker-registry-server-user "$REGISTRY_USERNAME" \
  --docker-registry-server-password "$REGISTRY_PASSWORD"
echo "✅ Web App configured"
echo ""

# Step 12: Configure Web App settings
echo -e "${YELLOW}Step 12: Configuring Web App Settings${NC}"
az webapp config appsettings set \
  --resource-group "$RESOURCE_GROUP" \
  --name "$WEBAPP_NAME" \
  --settings WEBSITES_ENABLE_APP_SERVICE_STORAGE=false \
             ENVIRONMENT=production \
             PORT=8000
echo "✅ App settings configured"
echo ""

# Step 13: Deployment complete
echo -e "${GREEN}=========================================="
echo "Deployment Complete!"
echo "==========================================${NC}"
echo ""
echo "📊 Deployment Summary:"
echo "├── Resource Group: $RESOURCE_GROUP"
echo "├── ACR: $REGISTRY_NAME"
echo "├── Web App: $WEBAPP_NAME"
echo "├── Image: $ACR_LOGIN_SERVER/$IMAGE_NAME:$IMAGE_TAG"
echo ""
echo "🌐 Access Application:"
echo "   https://$WEBAPP_NAME.azurewebsites.net"
echo ""
echo "📋 Useful Commands:"
echo "  View logs: az webapp log tail -g $RESOURCE_GROUP -n $WEBAPP_NAME"
echo "  Restart: az webapp restart -g $RESOURCE_GROUP -n $WEBAPP_NAME"
echo "  Validate: bash scripts/validation.sh"
echo ""
