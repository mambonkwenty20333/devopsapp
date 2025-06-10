# Kubernetes Secrets Management Guide

## Your Current Secrets

The DevOps Hilltop application uses these actual database credentials from your Replit environment:

### Database Connection Details
- **Host**: ep-tight-night-ad7thfl1.c-2.us-east-1.aws.neon.tech
- **User**: neondb_owner
- **Database**: neondb
- **Port**: 5432
- **Connection**: SSL required (Neon database)

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
# Decode DATABASE_URL
echo "cG9zdGdyZXNxbDovL25lb25kYl9vd25lcjpucGdfWW9Gc1gwdGdOczh1c0JxeVoyNnVuenNMS0pKWkBlcC10aWdodC1uaWdodC1hZDd0aGZsMS5jLTIudXMtZWFzdC0xLmF3cy5uZW9uLnRlY2g6NTQzMi9uZW9uZGI/c3NsbW9kZT1yZXF1aXJl" | base64 -d

# Result: postgresql://neondb_owner:npg_YoFsX0tgNs8usBqyZ26unzsLKJJZ@ep-tight-night-ad7thfl1.c-2.us-east-1.aws.neon.tech:5432/neondb?sslmode=require
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
# Create new secret with literal values
kubectl create secret generic devops-hilltop-secret \
  --from-literal=DATABASE_URL="postgresql://user:pass@host:5432/db" \
  --from-literal=PGUSER="username" \
  --from-literal=PGPASSWORD="password" \
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
kubectl exec deployment/devops-hilltop-deployment -n devops-hilltop -- env | grep PG

# Check pod logs for connection errors
kubectl logs deployment/devops-hilltop-deployment -n devops-hilltop --tail=50

# Test database connection from pod
kubectl exec -it deployment/devops-hilltop-deployment -n devops-hilltop -- sh
# Inside pod: psql $DATABASE_URL -c "SELECT version();"
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

The deployment automatically references secrets:

```yaml
env:
- name: DATABASE_URL
  valueFrom:
    secretKeyRef:
      name: devops-hilltop-secret
      key: DATABASE_URL
- name: PGUSER
  valueFrom:
    secretKeyRef:
      name: devops-hilltop-secret
      key: PGUSER
```

This ensures sensitive data is not hardcoded in deployment manifests and can be managed separately from application code.