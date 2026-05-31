# Docker CI/CD Pipeline Flow

## Overview
This document explains the complete CI/CD pipeline flow from code push to application deployment.

---

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
```

---

## Pipeline Jobs

### Job 1: Build and Push
**Purpose:** Build Docker image and push to ACR

**Steps:**
1. Checkout repository
2. Set up Docker Buildx
3. Login to ACR
4. Build and push Docker image
5. Logout from ACR

**Triggers:** Push to main/develop, Pull request

**Duration:** ~5-10 minutes

---

### Job 2: Deploy
**Purpose:** Deploy container image to Azure Web App

**Steps:**
1. Checkout repository
2. Azure Login
3. Deploy to Azure Web App
4. Verify deployment
5. Azure Logout

**Dependencies:** Needs build-and-push job to succeed

**Duration:** ~3-5 minutes

---

### Job 3: Notify
**Purpose:** Report pipeline status

**Steps:**
1. Check build status
2. Check deploy status
3. Report overall success/failure

**Triggered:** Always (regardless of status)

---

## Environment Variables

| Variable | Source | Usage |
|----------|--------|-------|
| `REGISTRY` | Env | ACR login server |
| `REPOSITORY` | Env | Docker image name |
| `IMAGE_TAG` | Env | GitHub commit SHA |
| `REGISTRY_NAME` | Secrets | ACR resource name |
| `REGISTRY_USERNAME` | Secrets | ACR credentials |
| `REGISTRY_PASSWORD` | Secrets | ACR credentials |
| `WEBAPP_NAME` | Secrets | Azure Web App name |
| `AZURE_CREDENTIALS` | Secrets | Azure service principal |

---

## GitHub Secrets Required

Set these secrets in your GitHub repository settings:

1. **REGISTRY_NAME** - Azure Container Registry name
2. **REGISTRY_USERNAME** - ACR username
3. **REGISTRY_PASSWORD** - ACR password
4. **WEBAPP_NAME** - Azure Web App name
5. **AZURE_CREDENTIALS** - Azure service principal (JSON)

---

## Triggers

### When Pipeline Runs

**Automatic Triggers:**
- Push to `main` branch
- Push to `develop` branch
- Pull request to `main` branch

**Manual Trigger:**
- Can be manually triggered from Actions tab

---

## Pipeline Caching

**What is cached:**
- Docker build layers
- Build dependencies

**Benefits:**
- Faster builds on subsequent runs
- Only changed layers rebuilt
- Reduces ACR storage usage

---

## Failure Handling

**If build fails:**
- Pipeline stops at build job
- No deployment attempted
- Developers notified
- Fix required before next deployment

**If deploy fails:**
- Web App remains on previous version
- Deployment logs available for troubleshooting
- Can retry after fixing issue

---

## Security

**Credentials:**
- Never stored in code
- Stored as GitHub Secrets
- Not logged or exposed
- Only used during pipeline execution

**Best Practices:**
- Rotate credentials regularly
- Use service principals
- Limit ACR access
- Monitor deployments

---

## Monitoring Pipeline

**View pipeline runs:**
1. GitHub → Actions tab
2. Select "Docker CI/CD Pipeline" workflow
3. View latest runs with status

**View logs:**
1. Click specific run
2. Expand job logs
3. Expand step logs for details

**Pipeline statistics:**
- Success rate
- Average duration
- Last 30 days history

---

## Local Testing

**Before committing code:**
1. Build locally: `bash scripts/build.sh`
2. Run container: `docker run -p 5000:5000 docker-cicd-app`
3. Test application: Open `http://localhost:5000`
4. Commit and push when tests pass

---

## Rollback Procedure

**If deployment has issues:**
1. Go to Azure Web App → Container settings
2. Change image tag to previous version
3. Click Save
4. Container automatically updated
5. Application reverts to previous version

**Alternative:**
1. Re-run pipeline with previous commit
2. Will build and deploy previous version

---

## Performance Tips

1. **Reduce build time:**
   - Use Docker layer caching
   - Minimize Dockerfile steps
   - Remove unused dependencies

2. **Optimize deployment:**
   - Use container warm-up
   - Pre-pull images
   - Enable Continuous Deployment

3. **Monitor costs:**
   - Clean old images from ACR
   - Right-size Web App plan
   - Monitor bandwidth usage

---

## Summary

The Docker CI/CD pipeline automates the entire process from code commit to production deployment, ensuring fast, reliable, and consistent application releases.

Key benefits:
- ✅ Automatic testing and building
- ✅ Continuous deployment
- ✅ Reduced manual errors
- ✅ Fast feedback loop
- ✅ Scalable and reliable
