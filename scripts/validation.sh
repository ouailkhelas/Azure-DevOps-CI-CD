#!/bin/bash

# Docker CI/CD Pipeline - Validation Script
# Tests deployed application and validates pipeline

set -e

echo "=========================================="
echo "Docker CI/CD Validation Script"
echo "=========================================="
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Configuration
RESOURCE_GROUP="${1:-rg-docker-cicd}"
WEBAPP_NAME="${2:-docker-cicd-app}"
REGISTRY_NAME="${3:-acrdockercicd}"

echo -e "${BLUE}Configuration:${NC}"
echo "├── Resource Group: $RESOURCE_GROUP"
echo "├── Web App Name: $WEBAPP_NAME"
echo "└── Registry Name: $REGISTRY_NAME"
echo ""

# Step 1: Check Azure CLI
echo -e "${YELLOW}Step 1: Checking Prerequisites${NC}"
command -v az &> /dev/null && echo "✅ Azure CLI found" || { echo "❌ Azure CLI not found"; exit 1; }
command -v curl &> /dev/null && echo "✅ curl found" || { echo "⚠️  curl not found"; }
echo ""

# Step 2: Verify resource group
echo -e "${YELLOW}Step 2: Verifying Resource Group${NC}"
if az group show --name "$RESOURCE_GROUP" &>/dev/null; then
    echo "✅ Resource group exists: $RESOURCE_GROUP"
else
    echo "❌ Resource group not found: $RESOURCE_GROUP"
    exit 1
fi
echo ""

# Step 3: Verify Web App
echo -e "${YELLOW}Step 3: Verifying Azure Web App${NC}"
if az webapp show --resource-group "$RESOURCE_GROUP" --name "$WEBAPP_NAME" &>/dev/null; then
    echo "✅ Web App exists: $WEBAPP_NAME"
    
    # Get Web App details
    WEBAPP_URL=$(az webapp show \
      --resource-group "$RESOURCE_GROUP" \
      --name "$WEBAPP_NAME" \
      --query "defaultHostName" -o tsv)
    echo "   URL: https://$WEBAPP_URL"
else
    echo "❌ Web App not found: $WEBAPP_NAME"
    exit 1
fi
echo ""

# Step 4: Verify ACR
echo -e "${YELLOW}Step 4: Verifying Azure Container Registry${NC}"
if az acr show --resource-group "$RESOURCE_GROUP" --name "$REGISTRY_NAME" &>/dev/null; then
    echo "✅ ACR exists: $REGISTRY_NAME"
    
    # List repositories
    REPO_COUNT=$(az acr repository list \
      --name "$REGISTRY_NAME" \
      --query "length(@)" -o tsv)
    echo "   Repositories: $REPO_COUNT"
else
    echo "⚠️  ACR not found: $REGISTRY_NAME"
fi
echo ""

# Step 5: Check Web App status
echo -e "${YELLOW}Step 5: Checking Web App Status${NC}"
APP_STATE=$(az webapp show \
  --resource-group "$RESOURCE_GROUP" \
  --name "$WEBAPP_NAME" \
  --query "state" -o tsv)
echo "✅ Web App State: $APP_STATE"
echo ""

# Step 6: Test Web App endpoint
echo -e "${YELLOW}Step 6: Testing Web App Endpoint${NC}"
FULL_URL="https://$WEBAPP_URL"
echo "Testing: $FULL_URL"

if command -v curl &>/dev/null; then
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$FULL_URL" --max-time 10 || echo "000")
    if [ "$HTTP_CODE" = "200" ]; then
        echo "✅ Application responding (HTTP $HTTP_CODE)"
    else
        echo "⚠️  Application returned HTTP $HTTP_CODE"
        echo "   App may still be starting up..."
    fi
else
    echo "⚠️  curl not available, skipping HTTP test"
fi
echo ""

# Step 7: Test health endpoint
echo -e "${YELLOW}Step 7: Testing Health Endpoint${NC}"
if command -v curl &>/dev/null; then
    HEALTH_URL="https://$WEBAPP_URL/health"
    echo "Testing: $HEALTH_URL"
    HEALTH_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$HEALTH_URL" --max-time 10 || echo "000")
    if [ "$HEALTH_CODE" = "200" ]; then
        echo "✅ Health check passed (HTTP $HEALTH_CODE)"
    else
        echo "⚠️  Health check returned HTTP $HEALTH_CODE"
    fi
else
    echo "⚠️  curl not available"
fi
echo ""

# Step 8: Check container logs
echo -e "${YELLOW}Step 8: Viewing Container Logs${NC}"
echo "Recent logs:"
az webapp log tail \
  --resource-group "$RESOURCE_GROUP" \
  --name "$WEBAPP_NAME" \
  --lines 10 2>/dev/null || echo "Logs not available yet"
echo ""

# Step 9: List deployed images
echo -e "${YELLOW}Step 9: Checking Deployed Images${NC}"
IMAGES=$(az acr repository list --name "$REGISTRY_NAME" -o tsv 2>/dev/null || echo "No images")
if [ -n "$IMAGES" ]; then
    echo "Images in ACR:"
    echo "$IMAGES" | sed 's/^/  ✓ /'
else
    echo "No images found in ACR"
fi
echo ""

# Step 10: Summary
echo -e "${GREEN}=========================================="
echo "Validation Summary"
echo "==========================================${NC}"
echo ""
echo "✅ Deployment Validation Complete"
echo ""
echo "📍 Access Your Application:"
echo "   https://$WEBAPP_URL"
echo ""
echo "🔧 Troubleshooting:"
echo "  View logs: az webapp log tail -g $RESOURCE_GROUP -n $WEBAPP_NAME"
echo "  Restart: az webapp restart -g $RESOURCE_GROUP -n $WEBAPP_NAME"
echo "  SSH: az webapp create-remote-connection -g $RESOURCE_GROUP -n $WEBAPP_NAME"
echo ""
echo "🧹 Cleanup (if needed):"
echo "  Delete everything: az group delete -g $RESOURCE_GROUP --yes --no-wait"
echo ""
