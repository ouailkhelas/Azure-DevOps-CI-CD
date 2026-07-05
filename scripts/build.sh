#!/bin/bash
set -e

echo "=========================================="
echo "Docker Build Script"
echo "=========================================="
echo ""

IMAGE_NAME="docker-cicd-app"
IMAGE_TAG="${1:-latest}"
DOCKERFILE_PATH="./app/Dockerfile"
APP_PATH="./app"

echo -e "${BLUE}Configuration:${NC}"
echo "├── Image Name: $IMAGE_NAME"
echo "├── Image Tag: $IMAGE_TAG"
echo "├── Dockerfile: $DOCKERFILE_PATH"
echo "└── App Path: $APP_PATH"

echo -e "${YELLOW}Step 1: Verifying Dockerfile${NC}"
if [ ! -f "$DOCKERFILE_PATH" ]; then
    echo " Dockerfile not found at $DOCKERFILE_PATH"
    exit 1
fi
echo " Dockerfile found"
echo ""

echo -e "${YELLOW}Step 2: Building Docker image${NC}"
docker build \
  -t "$IMAGE_NAME:$IMAGE_TAG" \
  -t "$IMAGE_NAME:latest" \
  -f "$DOCKERFILE_PATH" \
  "$APP_PATH"
echo "Docker image built successfully"
echo ""

echo -e "${YELLOW}Step 3: Image Information${NC}"
docker images | grep "$IMAGE_NAME"
echo ""

echo "Build Complete!"
echo "==========================================${NC}"
echo ""
echo " Docker Image Built:"
echo "├── Name: $IMAGE_NAME"
echo "├── Tags: $IMAGE_TAG, latest"
echo ""
echo "Next Steps:"
echo "1. Test locally: bash scripts/build.sh && docker run -p 5000:5000 docker-cicd-app"
echo "2. Deploy to Azure: bash scripts/deploy.sh"
echo "3. Validate: bash scripts/validation.sh"
echo ""
