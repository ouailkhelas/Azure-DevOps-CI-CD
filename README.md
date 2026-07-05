# Azure Docker CI/CD Pipeline

A complete learning project demonstrating CI/CD automation with Docker, GitHub Actions, and Azure services.

## 🛡️Architecture

```
Developer Push → GitHub Actions → Docker Build → Azure ACR → Azure Web App
   (Code)      (Automation)      (Container)    (Registry)  (Deployment)
```

## Technologies

- **Docker** - Application containerization
- **GitHub Actions** - CI/CD automation pipeline
- **Azure Container Registry (ACR)** - Docker image storage
- **Azure Web App for Containers** - Container hosting
- **Flask** - Simple Python web application


## 🚀 Quick Start (5 Steps)

### 1. Prerequisites
```bash
# Install required tools
- Docker Desktop
- Azure CLI
- Git
- Python 3.8+
```

### 2. Build Locally
```bash
bash scripts/build.sh
docker run -p 5000:5000 docker-cicd-app:latest
# Open http://localhost:5000
```

### 3. Deploy to Azure
```bash
# Authenticate to Azure
az login

# Deploy infrastructure
bash scripts/deploy.sh

# Or use individual commands from docs/deployment-notes.md
```

### 4. Configure GitHub Actions
```bash
# Add repository secrets:
- REGISTRY_NAME (your ACR name)
- REGISTRY_USERNAME (ACR username)
- REGISTRY_PASSWORD (ACR password)
- WEBAPP_NAME (Web App name)
- AZURE_CREDENTIALS (Service principal JSON)
```

### 5. Push Code & Watch Pipeline
```bash
git add .
git commit -m "Initial commit"
git push origin main
# View GitHub Actions → Workflows tab
```

## What Each Component Does

**Docker** - Packages application and dependencies into portable container

**GitHub Actions** - Automatically builds, tests, and deploys on code push

**Azure Container Registry** - Stores Docker images securely in Azure

**Azure Web App** - Hosts containerized application with auto-scaling

## Pipeline Workflow

1. Developer commits and pushes code to GitHub
2. GitHub Actions pipeline automatically triggered
3. Docker image built from Dockerfile
4. Image tagged and pushed to Azure Container Registry
5. Azure Web App pulls latest image from ACR
6. Container started and application deployed
7. Users access updated application


## Key Features

✅ Automated CI/CD pipeline  
✅ Docker containerization  
✅ Azure integration  
✅ Multi-stage Docker builds  
✅ Health checks  
✅ Container logging  
✅ Auto-deployment  
✅ Scalable infrastructure  
