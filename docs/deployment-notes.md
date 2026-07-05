# Docker Deployment Notes

## Local Development Setup

### Building Locally
```bash
# Build Docker image
bash scripts/build.sh

# Or manually
docker build -t docker-cicd-app:latest ./app

# Run container locally
docker run -p 5000:5000 docker-cicd-app:latest

# Test application
curl http://localhost:5000
```

## Azure Deployment Steps

### 1. Prepare Azure Resources

```bash
# Login to Azure
az login

# Set default subscription
az account set --subscription "Your Subscription ID"

# Create resource group
az group create \
  --name rg-docker-cicd \
  --location eastus
```

### 2. Create Azure Container Registry

```bash
# Create ACR
az acr create \
  --resource-group rg-docker-cicd \
  --name acrdockercicd \
  --sku Basic

# Enable admin user
az acr update -n acrdockercicd --admin-enabled true

# Get login credentials
az acr credential show \
  --resource-group rg-docker-cicd \
  --name acrdockercicd
```

### 3. Push Docker Image to ACR

```bash
# Login to ACR
az acr login --name acrdockercicd

# Tag image
docker tag docker-cicd-app:latest acrdockercicd.azurecr.io/docker-cicd-app:latest

# Push image
docker push acrdockercicd.azurecr.io/docker-cicd-app:latest

# Verify push
az acr repository list -n acrdockercicd
```

### 4. Create Azure Web App for Containers

```bash
# Create App Service Plan (Linux)
az appservice plan create \
  --name plan-docker-cicd \
  --resource-group rg-docker-cicd \
  --sku B1 \
  --is-linux

# Create Web App
az webapp create \
  --resource-group rg-docker-cicd \
  --plan plan-docker-cicd \
  --name docker-cicd-app \
  --deployment-container-image-name-user acrdockercicd \
  --deployment-container-image-name docker-cicd-app:latest
```

### 5. Configure Web App with ACR

```bash
# Get ACR credentials
REGISTRY_USERNAME=$(az acr credential show \
  --resource-group rg-docker-cicd \
  --name acrdockercicd \
  --query username -o tsv)

REGISTRY_PASSWORD=$(az acr credential show \
  --resource-group rg-docker-cicd \
  --name acrdockercicd \
  --query "passwords[0].value" -o tsv)

# Configure Web App
az webapp config container set \
  --name docker-cicd-app \
  --resource-group rg-docker-cicd \
  --docker-custom-image-name acrdockercicd.azurecr.io/docker-cicd-app:latest \
  --docker-registry-server-url https://acrdockercicd.azurecr.io \
  --docker-registry-server-user "$REGISTRY_USERNAME" \
  --docker-registry-server-password "$REGISTRY_PASSWORD"
```

### 6. Configure Application Settings

```bash
# Set environment variables
az webapp config appsettings set \
  --resource-group rg-docker-cicd \
  --name docker-cicd-app \
  --settings WEBSITES_ENABLE_APP_SERVICE_STORAGE=false \
             ENVIRONMENT=production \
             PORT=8000
```

### 7. Verify Deployment

```bash
# View application status
az webapp show \
  --resource-group rg-docker-cicd \
  --name docker-cicd-app \
  --query "state"

# View logs
az webapp log tail \
  --resource-group rg-docker-cicd \
  --name docker-cicd-app

# Test application
curl https://docker-cicd-app.azurewebsites.net
```

---

## GitHub Actions Setup

### Create Service Principal for Azure

```bash
# Create service principal
az ad sp create-for-rbac \
  --name "docker-cicd-github" \
  --role contributor \
  --scopes /subscriptions/{subscription-id} \
  --json-auth
```

### Add GitHub Secrets

1. Go to GitHub Repository → Settings → Secrets
2. Add the following secrets:

| Secret Name | Value |
|-------------|-------|
| REGISTRY_NAME | acrdockercicd |
| REGISTRY_USERNAME | (from ACR) |
| REGISTRY_PASSWORD | (from ACR) |
| WEBAPP_NAME | docker-cicd-app |
| AZURE_CREDENTIALS | (service principal JSON) |
