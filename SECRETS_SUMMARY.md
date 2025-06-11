# Your Actual Database Secrets

## Current Configuration

Your DevOps Hilltop application uses these actual database credentials:

### Database Details
- **Provider**: Neon Database (PostgreSQL)
- **Host**: `ep-tight-night-ad7thfl1.c-2.us-east-1.aws.neon.tech`
- **User**: `neondb_owner`
- **Database**: `neondb`
- **Port**: `5432`
- **SSL**: Required

### Complete Connection String
```
postgresql://neondb_owner:npg_YoFsX0tgNs8usBqyZ26unzsLKJJZ@ep-tight-night-ad7thfl1.c-2.us-east-1.aws.neon.tech:5432/neondb?sslmode=require
```

## Kubernetes Secrets Management

### How Secrets Work
Kubernetes secrets are **base64 encoded** (not encrypted). Anyone with cluster access can decode them:

```bash
# Decode any secret value
echo "bmVvbmRiX293bmVy" | base64 -d
# Result: neondb_owner
```

### Your Secret Values (Base64 Encoded)
```yaml
PGUSER: bmVvbmRiX293bmVy
PGHOST: ZXAtdGlnaHQtbmlnaHQtYWQ3dGhmbDEuYy0yLnVzLWVhc3QtMS5hd3MubmVvbi50ZWNo
PGPORT: NTQzMg==
PGDATABASE: bmVvbmRi
DATABASE_URL: cG9zdGdyZXNxbDovL25lb25kYl9vd25lcjpucGdfWW9Gc1gwdGdOczh1c0JxeVoyNnVuenNMS0pKWkBlcC10aWdodC1uaWdodC1hZDd0aGZsMS5jLTIudXMtZWFzdC0xLmF3cy5uZW9uLnRlY2g6NTQzMi9uZW9uZGI/c3NsbW9kZT1yZXF1aXJl
```

## Practical Secret Management

### View Current Secrets
```bash
# List secrets in your namespace
kubectl get secrets -n devops-hilltop

# View specific secret
kubectl get secret devops-hilltop-secret -n devops-hilltop -o yaml

# Decode a specific value
kubectl get secret devops-hilltop-secret -n devops-hilltop -o jsonpath='{.data.PGUSER}' | base64 -d
```

### Using the Management Script
```bash
# View all secret keys
./scripts/manage-secrets.sh view

# Decode specific values
./scripts/manage-secrets.sh decode PGUSER
./scripts/manage-secrets.sh decode DATABASE_URL

# Show all actual values
./scripts/manage-secrets.sh values

# Encode new values
./scripts/manage-secrets.sh encode "new-password"
```

### Modifying Secrets

#### Method 1: Edit Directly
```bash
kubectl edit secret devops-hilltop-secret -n devops-hilltop
```

#### Method 2: Replace from File
```bash
# Update k8s/secrets.yaml with new base64 values
kubectl apply -f k8s/secrets.yaml
```

#### Method 3: Recreate from Command Line
```bash
kubectl delete secret devops-hilltop-secret -n devops-hilltop

kubectl create secret generic devops-hilltop-secret \
  --from-literal=DATABASE_URL="postgresql://newuser:newpass@newhost:5432/newdb" \
  --from-literal=PGUSER="newuser" \
  --namespace=devops-hilltop
```

### Apply Changes
After modifying secrets, restart the deployment:
```bash
kubectl rollout restart deployment/devops-hilltop-deployment -n devops-hilltop
```

## Security Considerations

### What You Need to Know
1. **Base64 is NOT encryption** - anyone with cluster access can decode secrets
2. **Store sensitive data elsewhere** for production (AWS Secrets Manager, Vault)
3. **Use RBAC** to limit who can access secrets
4. **Rotate secrets regularly** and update applications

### Current Security Status
- Your database password is visible to anyone with Kubernetes access
- Consider migrating to external secret management for production
- Current setup is acceptable for development/staging environments

## Files Created
- `k8s/secrets.yaml` - Kubernetes secret manifest with your actual credentials
- `k8s/SECRETS_GUIDE.md` - Comprehensive secrets management guide
- `scripts/manage-secrets.sh` - Practical script for secret operations
- `.env` - Local development environment file

Your secrets are properly configured and the deployment will use them when deployed to Kubernetes.