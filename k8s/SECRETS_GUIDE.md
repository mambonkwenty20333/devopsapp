# Kubernetes Secrets Management Guide

## Current Configuration

The DevOps Hilltop application now uses Neon (managed PostgreSQL) instead of self-hosted PostgreSQL.

### Database Setup
- **Provider**: Neon (managed PostgreSQL service)
- **Connection**: Single DATABASE_URL environment variable
- **SSL**: Required for Neon connections
- **No separate PostgreSQL pods**: Removed postgres-deployment.yaml, postgres-service.yaml, etc.

## How Kubernetes Secrets Work

Kubernetes secrets are base64 encoded (NOT encrypted) and can be easily decoded:

### Viewing Current Secrets
```bash
# List all secrets in namespace
kubectl get secrets -n devops-hilltop

# View secret details (base64 encoded)
kubectl get secret devops-hilltop-secret -n devops-hilltop -o yaml

# Decode a specific secret value
kubectl get secret devops-hilltop-secret -n devops-hilltop -o jsonpath='{.data.DATABASE_URL}' | base64 -d
```

### Decoding Secret Values
```bash
# Decode DATABASE_URL (current Neon connection)
kubectl get secret devops-hilltop-secret -n devops-hilltop -o jsonpath='{.data.DATABASE_URL}' | base64 -d

# Shows: postgresql://neondb_owner:npg_jrk2GdwbV5Ay@ep-tight-night-ad7thfl1.c-2.us-east-1.aws.neon.tech/neondb?sslmode=require
```

### Encoding New Values
```bash
# Encode a new password
echo "your-new-password" | base64 -w 0
# Result: eW91ci1uZXctcGFzc3dvcmQ=

# Encode a new database URL
echo "postgresql://newuser:newpass@newhost:5432/newdb" | base64 -w 0
```

## Modifying Secrets

### Method 1: Update Existing Secret
```bash
# Edit secret directly
kubectl edit secret devops-hilltop-secret -n devops-hilltop

# This opens the secret in your editor - modify base64 values and save
```

### Method 2: Replace Secret from File
```bash
# Delete existing secret
kubectl delete secret devops-hilltop-secret -n devops-hilltop

# Apply new secret from file
kubectl apply -f k8s/secrets.yaml
```

### Method 3: Create Secret from Command Line
```bash
# Create new secret with Neon DATABASE_URL only
kubectl create secret generic devops-hilltop-secret \
  --from-literal=DATABASE_URL="postgresql://neondb_owner:your_password@ep-tight-night-ad7thfl1.c-2.us-east-1.aws.neon.tech/neondb?sslmode=require" \
  --namespace=devops-hilltop
```

## Security Best Practices

### Secret Protection
- Secrets are base64 encoded, NOT encrypted
- Anyone with cluster access can decode secrets
- Use RBAC to limit secret access
- Consider external secret management (AWS Secrets Manager, HashiCorp Vault)

### Rotation Strategy
```bash
# 1. Create new secret with updated values
kubectl apply -f k8s/secrets-updated.yaml

# 2. Restart deployment to pick up new secrets
kubectl rollout restart deployment/devops-hilltop-deployment -n devops-hilltop

# 3. Verify application is working with new secrets
kubectl logs deployment/devops-hilltop-deployment -n devops-hilltop
```

## Environment-Specific Secrets

### Development Environment
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: devops-hilltop-secret
  namespace: devops-hilltop
data:
  DATABASE_URL: cG9zdGdyZXNxbDovL2xvY2FsaG9zdDo1NDMyL2RldmRi  # postgresql://localhost:5432/devdb
  NODE_ENV: ZGV2ZWxvcG1lbnQ=  # development
```

### Production Environment
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: devops-hilltop-secret
  namespace: devops-hilltop
data:
  DATABASE_URL: <your-production-db-url-base64>
  NODE_ENV: cHJvZHVjdGlvbg==  # production
```

## Troubleshooting

### Common Issues
1. **Pod can't start**: Check if secret exists and has correct keys
2. **Connection failed**: Verify decoded DATABASE_URL is correct
3. **Permission denied**: Check RBAC permissions for service account

### Debug Commands
```bash
# Check if secret exists
kubectl get secret devops-hilltop-secret -n devops-hilltop

# View pod environment variables
kubectl exec deployment/devops-hilltop-app -n devops-hilltop -- env | grep DATABASE

# Check pod logs for connection errors
kubectl logs deployment/devops-hilltop-app -n devops-hilltop --tail=50

# Test database connection from pod
kubectl exec -it deployment/devops-hilltop-app -n devops-hilltop -- sh
# Inside pod: node -e "console.log(process.env.DATABASE_URL)"
```

## External Secret Management

### AWS Secrets Manager Integration
```yaml
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: aws-secrets-manager
  namespace: devops-hilltop
spec:
  provider:
    aws:
      service: SecretsManager
      region: eu-central-1
---
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: devops-hilltop-external-secret
  namespace: devops-hilltop
spec:
  secretStoreRef:
    name: aws-secrets-manager
    kind: SecretStore
  target:
    name: devops-hilltop-secret
  data:
  - secretKey: DATABASE_URL
    remoteRef:
      key: devops-hilltop/database-url
```

## Deployment Integration

The deployment now uses only the DATABASE_URL secret:

```yaml
env:
- name: DATABASE_URL
  valueFrom:
    secretKeyRef:
      name: devops-hilltop-secret
      key: DATABASE_URL
```

## What Changed

### Removed Files
- `postgres-deployment.yaml` - No longer needed (using Neon instead)
- `postgres-service.yaml` - No longer needed 
- `postgres-secret.yaml` - No longer needed
- `postgres-pvc.yaml` - No longer needed

### Updated Files
- `deployment.yaml` - Now only uses DATABASE_URL environment variable
- `secret.yaml` - Updated to contain Neon DATABASE_URL instead of local PostgreSQL credentials

### Benefits of Neon Integration
- No PostgreSQL pod management required
- Automatic backups and scaling handled by Neon
- SSL encryption built-in
- Reduced Kubernetes resource usage
- Simplified deployment configuration