# Docker Deployment Notes

## Local Development Setup

### Prerequisites
- Docker Desktop installed and running
- Azure CLI installed
- Git installed
- Python 3.8+ (for local testing without Docker)

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

### Testing Application
- Home page: http://localhost:5000
- Health check: http://localhost:5000/health
- API version: http://localhost:5000/api/version

### Stopping Container
```bash
# Find running containers
docker ps

# Stop container
docker stop <container-id>

# Remove container
docker rm <container-id>
```

---

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

### Test Workflow

```bash
# Create test file
echo "test" > test.txt

# Commit and push
git add test.txt
git commit -m "Test GitHub Actions"
git push origin main

# View pipeline in GitHub Actions tab
# Check status and logs
```

---

## Monitoring & Troubleshooting

### View Application Logs

```bash
# Stream logs
az webapp log tail -g rg-docker-cicd -n docker-cicd-app

# View last N lines
az webapp log tail -g rg-docker-cicd -n docker-cicd-app --lines 50
```

### Common Issues

**Issue: 502 Bad Gateway**
- Solution: Container not started
- Check logs: `az webapp log tail`
- Restart app: `az webapp restart -g rg-docker-cicd -n docker-cicd-app`

**Issue: Image not found**
- Solution: Image not pushed to ACR correctly
- Verify: `az acr repository list -n acrdockercicd`
- Rebuild and push image

**Issue: Authentication error**
- Solution: Credentials incorrect
- Regenerate: `az acr credential renew -n acrdockercicd`

### Performance Optimization

1. **Reduce container startup time:**
   - Use lighter base image
   - Minimize dependencies
   - Pre-warm connections

2. **Optimize image size:**
   - Use multi-stage builds
   - Remove dev dependencies
   - Clean up package caches

3. **Scale application:**
   - Upgrade App Service Plan
   - Enable autoscaling
   - Use CDN for static content

---

## Cost Management

### Estimate Monthly Costs

| Service | Tier | Cost |
|---------|------|------|
| ACR | Basic | $5-10 |
| Web App | B1 | $10-15 |
| Storage | Minimal | $1-2 |
| **Total** | | **$16-27** |

### Cost Reduction Tips

1. Use Basic tier for development
2. Delete unused resources
3. Right-size container
4. Monitor bandwidth usage
5. Schedule auto-shutdown for non-prod

### Cleanup Resources

```bash
# Delete entire resource group (WARNING: Removes everything)
az group delete \
  --name rg-docker-cicd \
  --yes \
  --no-wait

# Or delete individual resources
az acr delete -n acrdockercicd
az webapp delete -g rg-docker-cicd -n docker-cicd-app
az appservice plan delete -g rg-docker-cicd -n plan-docker-cicd
```

---

## Best Practices

✅ **DO:**
- Use Docker for consistency
- Implement health checks
- Tag images with versions
- Monitor application logs
- Keep secrets in GitHub Secrets
- Test locally before push
- Use Azure CLI for automation

❌ **DON'T:**
- Store secrets in code
- Use latest tag in production
- Deploy without testing
- Skip log monitoring
- Ignore pipeline failures
- Leave test resources running
- Hardcode configuration values

---

## Useful Commands

```bash
# Build image
docker build -t docker-cicd-app:latest ./app

# Run locally
docker run -p 5000:5000 docker-cicd-app:latest

# Push to ACR
docker push acrdockercicd.azurecr.io/docker-cicd-app:latest

# View Web App logs
az webapp log tail -g rg-docker-cicd -n docker-cicd-app

# Restart Web App
az webapp restart -g rg-docker-cicd -n docker-cicd-app

# Update image in Web App
az webapp config container set \
  --name docker-cicd-app \
  --resource-group rg-docker-cicd \
  --docker-custom-image-name acrdockercicd.azurecr.io/docker-cicd-app:latest
```

---

## Summary

This guide covers the complete deployment process from local Docker build to Azure Web App deployment. Follow the steps carefully and refer to the troubleshooting section if issues arise.

Key takeaways:
- ✅ Local development with Docker
- ✅ Azure Container Registry for image storage
- ✅ Azure Web App for production hosting
- ✅ GitHub Actions for automation
- ✅ Monitoring and scaling
