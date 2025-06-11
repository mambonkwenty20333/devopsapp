# PostgreSQL Init Container Permission Fix

## Problem Analysis
PostgreSQL containers fail with permission errors when trying to initialize the database on persistent volumes due to:
1. Volume mount ownership conflicts
2. PostgreSQL requiring specific directory permissions (700)
3. User ID mismatches between container and volume

## Solution: Init Container Approach

### How It Works
1. **Init Container** runs as root (UID 0) with full permissions
2. Creates the pgdata directory structure
3. Sets proper ownership (999:999 for postgres user)
4. Sets correct permissions (700 for data directory)
5. **Main Container** starts after init container completes successfully

### Implementation

#### k8s Manifest (postgres-deployment.yaml)
```yaml
initContainers:
- name: postgres-init
  image: busybox:1.35
  command: ['sh', '-c']
  args:
  - |
    mkdir -p /var/lib/postgresql/data/pgdata
    chown -R 999:999 /var/lib/postgresql/data
    chmod 700 /var/lib/postgresql/data/pgdata
  securityContext:
    runAsUser: 0
  volumeMounts:
  - name: postgres-storage
    mountPath: /var/lib/postgresql/data
```

### Benefits
- Resolves permission conflicts before PostgreSQL starts
- Handles both lost+found directory and ownership issues
- Works with any persistent volume storage class
- Provides clean separation of permission setup and database initialization

### Apply the Fix
```bash
./scripts/postgres-permission-fix.sh
```

This approach ensures PostgreSQL can initialize successfully on any Kubernetes persistent volume configuration.