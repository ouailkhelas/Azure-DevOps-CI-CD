# Docker CI/CD Pipeline Flow

## Overview
This document explains the complete CI/CD pipeline flow from code push to application deployment.

## Complete Workflow

```
┌─────────────────────────────────────────────────────────────────┐
│                    1. DEVELOPER PUSH                             │
│          Developer commits code and pushes to GitHub             │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│              2. GITHUB ACTIONS TRIGGERED                         │
│  Workflow file (.github/workflows/docker-deploy.yml) activated   │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│              3. CHECKOUT CODE                                    │
│        GitHub Actions pulls latest repository code              │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│           4. BUILD DOCKER IMAGE                                  │
│  Docker image built from Dockerfile with application code       │
│  - Multi-stage build                                             │
│  - Python dependencies installed                                 │
│  - Flask application configured                                  │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│      5. LOGIN TO AZURE CONTAINER REGISTRY                        │
│   GitHub Actions authenticates to ACR using credentials         │
│   (Stored in GitHub repository secrets)                         │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│         6. PUSH IMAGE TO ACR                                     │
│  Docker image pushed to Azure Container Registry                │
│  - Tagged with commit SHA and 'latest'                          │
│  - Stored for Azure Web App to pull                             │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│          7. AZURE LOGIN                                          │
│  GitHub Actions authenticates to Azure using service principal  │
│  (Stored in GitHub repository secrets)                          │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│        8. DEPLOY TO AZURE WEB APP                                │
│  Azure Web App receives deployment instruction                  │
│  - Pulls Docker image from ACR                                  │
│  - Starts new container with image                              │
│  - Routes traffic to new container                              │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│        9. VERIFICATION                                           │
│  GitHub Actions validates deployment success                    │
│  - Checks deployment status                                     │
│  - Logs success/failure                                         │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│      10. APPLICATION LIVE                                        │
│  Updated application available to users at:                     │
│  https://{webapp-name}.azurewebsites.net                        │
└─────────────────────────────────────────────────────────────────┘
