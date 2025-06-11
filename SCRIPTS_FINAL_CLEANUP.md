# Scripts Folder - Final Configuration

## CircleCI Integration Status
✅ **CircleCI does NOT require any scripts from the scripts/ folder**

Your CircleCI pipeline handles all operations inline:
- Build: Docker commands in pipeline
- Deploy: kubectl commands in pipeline  
- Test: Uses test.sh (not in scripts folder)

## Remaining Scripts (Manual Operations Only)

### Essential Operational Scripts
- `deploy-complete.sh` - Complete manual deployment with monitoring
- `fix-postgres.sh` - Fixes PostgreSQL volume mount CrashLoopBackOff
- `verify-deployment.sh` - Health checks and deployment verification

### Infrastructure Scripts  
- `fix-ebs-csi-permissions.sh` - EBS CSI driver setup for gp3 storage upgrade
- `manage-secrets.sh` - Kubernetes secret management utilities
- `init-db.sh` - Database initialization for manual setups

## Removed Scripts (No longer needed)
- `build-production.sh` - Dockerfile handles build inline
- `deployment-verification.sh` - Duplicate functionality
- `fix-deployment.sh` - Replaced by deploy-complete.sh
- `deploy-to-existing-cluster.sh` - Redundant functionality

## Usage Recommendations

### For Manual Deployments
```bash
./scripts/deploy-complete.sh
```

### For Troubleshooting
```bash
./scripts/fix-postgres.sh        # PostgreSQL issues
./scripts/verify-deployment.sh   # Health checks
```

### For Infrastructure Upgrades
```bash
./scripts/fix-ebs-csi-permissions.sh  # gp3 storage upgrade
```

The scripts folder is now optimized for manual operations and troubleshooting while CircleCI runs independently with inline commands.