#!/bin/bash

# Docker CI/CD Pipeline - Build Script
# Builds Docker image locally for testing

set -e

echo "=========================================="
echo "Docker Build Script"
echo "=========================================="
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
IMAGE_NAME="docker-cicd-app"
IMAGE_TAG="${1:-latest}"
DOCKERFILE_PATH="./app/Dockerfile"
APP_PATH="./app"

echo -e "${BLUE}Configuration:${NC}"
echo "├── Image Name: $IMAGE_NAME"
echo "├── Image Tag: $IMAGE_TAG"
echo "├── Dockerfile: $DOCKERFILE_PATH"
echo "└── App Path: $APP_PATH"
echo ""

# Step 1: Check if Dockerfile exists
echo -e "${YELLOW}Step 1: Verifying Dockerfile${NC}"
if [ ! -f "$DOCKERFILE_PATH" ]; then
    echo "❌ Dockerfile not found at $DOCKERFILE_PATH"
    exit 1
fi
echo "✅ Dockerfile found"
echo ""

# Step 2: Build Docker image
echo -e "${YELLOW}Step 2: Building Docker image${NC}"
docker build \
  -t "$IMAGE_NAME:$IMAGE_TAG" \
  -t "$IMAGE_NAME:latest" \
  -f "$DOCKERFILE_PATH" \
  "$APP_PATH"
echo "✅ Docker image built successfully"
echo ""

# Step 3: Display image info
echo -e "${YELLOW}Step 3: Image Information${NC}"
docker images | grep "$IMAGE_NAME"
echo ""

# Step 4: Display build completion
echo -e "${GREEN}=========================================="
echo "Build Complete!"
echo "==========================================${NC}"
echo ""
echo "📦 Docker Image Built:"
echo "├── Name: $IMAGE_NAME"
echo "├── Tags: $IMAGE_TAG, latest"
echo ""
echo "🚀 Next Steps:"
echo "1. Test locally: bash scripts/build.sh && docker run -p 5000:5000 docker-cicd-app"
echo "2. Deploy to Azure: bash scripts/deploy.sh"
echo "3. Validate: bash scripts/validation.sh"
echo ""
