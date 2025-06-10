# DevOps Hilltop - Production Deployment Guide

## Critical Issues Resolved

### 1. Vite Dependency Error in Production
**Problem**: Production containers crashed with MODULE_NOT_FOUND errors for Vite dependencies.

**Solution**: Created separate production entry point (`server/production-entry.ts`) that excludes all Vite dependencies.

### 2. PostgreSQL Storage Provisioning
**Problem**: EBS CSI driver lacked proper permissions for gp3 storage class.

**Solution**: Reverted to stable gp2 storage class with EBS CSI permission scripts for future gp3 migration.

## Fixed Architecture

```
Production Build Process:
1. Frontend: Vite builds static assets → dist/
2. Backend: esbuild bundles production-entry.ts → dist/server.js
3. Docker: Serves static files + API from single container
```

## Deployment Scripts

### Quick Deploy
```bash
./scripts/deploy-complete.sh
```

### Manual Deploy
1. Build production image:
   ```bash
   ./scripts/build-production.sh
   docker build -t hilltopconsultancy/devops-hilltop:$(git rev-parse --short HEAD) .
   ```

2. Deploy to Kubernetes:
   ```bash
   kubectl apply -f k8s/
   kubectl rollout restart deployment/devops-hilltop-app -n devops-hilltop
   ```

## Key Configuration Changes

### Dockerfile
- Uses `scripts/build-production.sh` for clean production builds
- Starts with `node dist/server.js` (no Vite dependencies)

### CircleCI Pipeline
- Fixed build process with proper script permissions
- Uses Git SHA tags for reliable deployment updates
- Comprehensive test reporting with JUnit XML

### Kubernetes Storage
- PostgreSQL uses gp2 storage class (stable)
- EBS CSI permissions script available for gp3 upgrade

## Monitoring & Health Checks

### Application Health
```bash
kubectl get pods -n devops-hilltop
kubectl logs -l app=devops-hilltop-app -n devops-hilltop
```

### Database Status
```bash
kubectl exec deployment/postgres -n devops-hilltop -- pg_isready
```

### LoadBalancer Access
```bash
kubectl get svc devops-hilltop-loadbalancer -n devops-hilltop
```

## Production URLs
- Application: Available via AWS LoadBalancer DNS
- Monitoring: Prometheus/Grafana stack deployed
- Database: PostgreSQL with persistent storage

## Troubleshooting

### Container Crashes
1. Check production build excludes Vite: `docker run --entrypoint sh hilltopconsultancy/devops-hilltop:latest -c "node -e 'console.log(process.versions)'"`
2. Verify server entry point: Container should start `dist/server.js`

### Storage Issues
1. Use gp2 storage class for reliability
2. Run `scripts/fix-ebs-csi-permissions.sh` for gp3 migration

### Deployment Updates
1. Force pod restart: `kubectl rollout restart deployment/devops-hilltop-app -n devops-hilltop`
2. Use unique image tags to ensure updates

## Security Notes
- Production server excludes development dependencies
- Database uses Kubernetes secrets for credentials
- LoadBalancer configured with proper security groups