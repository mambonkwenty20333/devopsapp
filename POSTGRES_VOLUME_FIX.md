# PostgreSQL Volume Mount Fix

## Issue Description
PostgreSQL pods crash with CrashLoopBackOff due to `lost+found` directory in the persistent volume mount point. This is a common issue when mounting persistent volumes directly as the PostgreSQL data directory.

## Root Cause
```
initdb: error: directory "/var/lib/postgresql/data" exists but is not empty
initdb: detail: It contains a lost+found directory, perhaps due to it being a mount point.
initdb: hint: Using a mount point directly as the data directory is not recommended.
Create a subdirectory under the mount point.
```

## Solution Applied

### k8s Manifests
Updated `k8s/postgres-deployment.yaml`:
- Added `subPath: pgdata` to volume mount
- Set `PGDATA=/var/lib/postgresql/data/pgdata` environment variable

### Helm Configuration
Updated `helm/devops-hilltop/values.yaml`:
- Added `subPath: "pgdata"` to persistence configuration
- Added `PGDATA` environment variable via extraEnvVars

### Quick Fix Script
Created `scripts/fix-postgres.sh` for immediate resolution:
```bash
./scripts/fix-postgres.sh
```

## Technical Details

The fix works by:
1. Mounting the persistent volume to `/var/lib/postgresql/data`
2. Using `subPath: pgdata` to create a subdirectory
3. Setting `PGDATA` to point to the subdirectory
4. This avoids the `lost+found` directory conflict

## Verification Commands

Check PostgreSQL status:
```bash
kubectl get pods -n devops-hilltop -l app=postgres
kubectl logs -n devops-hilltop -l app=postgres
```

Test database connectivity:
```bash
kubectl exec -n devops-hilltop deployment/postgres -- pg_isready -U postgres
```

## Prevention

This fix is now included in all deployment scripts:
- `scripts/deploy-complete.sh`
- `scripts/fix-postgres.sh`
- CircleCI pipeline configurations

Both k8s manifests and Helm charts handle this scenario correctly.