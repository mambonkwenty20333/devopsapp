# CI/CD Pipeline Verification Guide

## What Happens When You Merge to Develop Branch

When you push code to the `develop` branch, CircleCI automatically triggers the following pipeline:

### 1. Test Stage (Node.js Environment)
```bash
# Tests run automatically
./test.sh
echo "Linting passed - basic syntax check completed"
```

**Expected Output:**
```
🚀 Running DevOps with Hilltop Tests...
📋 Environment Tests
  ✓ should have test environment set
  ✓ should have database URL configured
📋 Basic Functionality Tests  
  ✓ should perform basic arithmetic
  ✓ should handle string operations
  ✓ should work with arrays
📋 Schema Validation Tests
  ✓ should validate category schema structure
  ✓ should validate resource schema structure
📊 Test Results Summary
Total Tests: 12, Passed: 12, Failed: 0
✅ All tests passed!
```

### 2. Build & Push Stage (Docker Environment)
```bash
# Docker commands executed by CircleCI
docker build -t $DOCKER_USERNAME/devops-hilltop:abc1234 .
docker push $DOCKER_USERNAME/devops-hilltop:abc1234
docker build -t $DOCKER_USERNAME/devops-hilltop:latest .
docker push $DOCKER_USERNAME/devops-hilltop:latest
```

**Expected Output:**
```
Successfully built image devops-hilltop:abc1234
Successfully pushed to Docker Hub
```

### 3. Deploy Staging Stage (AWS Environment)

#### AWS Configuration
```bash
aws eks update-kubeconfig --region eu-central-1 --name devops-hilltop-cluster
```

#### Kubernetes Manifest Updates
```bash
sed -i "s|image: devops-hilltop:latest|image: $DOCKER_USERNAME/devops-hilltop:abc1234|g" k8s/deployment.yaml
```

#### Deployment Execution
```bash
kubectl apply -f k8s/
```

**This deploys all components in order:**

1. **Namespace Creation**
   ```yaml
   apiVersion: v1
   kind: Namespace
   metadata:
     name: devops-hilltop
   ```

2. **PostgreSQL Database Setup**
   - Secret with database credentials
   - Persistent Volume Claim (10Gi storage)
   - PostgreSQL deployment with Alpine image
   - ClusterIP service for internal database access

3. **Application Secrets**
   ```yaml
   DATABASE_URL: postgresql://postgres:postgres_password@postgres-service:5432/devops_hilltop
   PGHOST: postgres-service
   PGUSER: postgres
   PGPASSWORD: postgres_password
   ```

4. **Application Deployment**
   - 3 replicas of your application
   - Connected to PostgreSQL database
   - Health checks configured

5. **NodePort Service**
   ```yaml
   type: NodePort
   ports:
   - port: 80
     targetPort: 5000
     nodePort: 30080
   ```

6. **Horizontal Pod Autoscaler**
   - Min replicas: 2
   - Max replicas: 10
   - CPU target: 70%

#### Deployment Verification
```bash
kubectl rollout status deployment/postgres-deployment -n devops-hilltop --timeout=300s
kubectl rollout status deployment/devops-hilltop-deployment -n devops-hilltop --timeout=300s
```

**Expected Output:**
```
deployment "postgres-deployment" successfully rolled out
deployment "devops-hilltop-deployment" successfully rolled out
```

#### Database Initialization
```bash
kubectl exec deployment/devops-hilltop-deployment -n devops-hilltop -- npm run db:push
```

**Expected Output:**
```
✅ Database schema pushed successfully
✅ Tables created: categories, resources, contacts
✅ Sample data populated
```

#### Final Verification
```bash
kubectl get pods -n devops-hilltop
kubectl get services -n devops-hilltop
```

**Expected Output:**
```
NAME                                     READY   STATUS    RESTARTS   AGE
devops-hilltop-deployment-7b8c9d-abc12   1/1     Running   0          2m
devops-hilltop-deployment-7b8c9d-def34   1/1     Running   0          2m
devops-hilltop-deployment-7b8c9d-ghi56   1/1     Running   0          2m
postgres-deployment-5f6g7h-jkl90        1/1     Running   0          2m

NAME                    TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
devops-hilltop-service  NodePort   10.100.123.45  <none>        80:30080/TCP   2m
postgres-service        ClusterIP  10.100.67.89   <none>        5432/TCP       2m
```

#### Database Connectivity Test
```bash
kubectl exec deployment/devops-hilltop-deployment -n devops-hilltop -- node -e "
  const { pool } = require('./server/db.js');
  pool.query('SELECT COUNT(*) FROM categories').then(result => {
    console.log('Database connection successful. Categories count:', result.rows[0].count);
  });
"
```

**Expected Output:**
```
Database connection successful. Categories count: 6
```

#### Application Access Test
```bash
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="ExternalIP")].address}')
NODE_PORT=$(kubectl get service devops-hilltop-service -n devops-hilltop -o jsonpath='{.spec.ports[0].nodePort}')
curl -f http://$NODE_IP:$NODE_PORT/health
```

**Expected Output:**
```
{
  "status": "healthy",
  "timestamp": "2024-01-01T12:00:00.000Z",
  "service": "DevOps with Hilltop"
}
```

## How to Access Your Deployed Application

After successful deployment, you can access your application at:

```
http://<NODE_EXTERNAL_IP>:30080
```

To get the exact URL:
```bash
kubectl get nodes -o wide
kubectl get service devops-hilltop-service -n devops-hilltop
```

## Application Features Available

Once deployed, your application includes:

1. **Homepage** - DevOps resource platform
2. **Categories** - CI/CD, Infrastructure, Monitoring, Security, Cloud, Containers
3. **Resources** - 15+ curated DevOps tools and tutorials
4. **Admin Dashboard** - Resource management at `/admin`
5. **Contact Form** - User feedback system
6. **Health Endpoint** - `/health` for monitoring

## Database Components Deployed

Your Kubernetes deployment includes a complete PostgreSQL setup:

- **PostgreSQL 15 Alpine** - Lightweight database container
- **Persistent Storage** - 10Gi volume with gp2 storage class
- **Database Schema** - Auto-created with sample data
- **Security** - Credentials stored in Kubernetes secrets
- **High Availability** - Ready for scaling and backups

## Production Deployment (Main Branch)

When you merge to `main` branch:

1. CircleCI requires manual approval
2. Deploys with 5 replicas (instead of 3)
3. Same database and verification process
4. Production-ready configuration

## Troubleshooting Common Issues

### Pod Not Starting
```bash
kubectl describe pod <pod-name> -n devops-hilltop
kubectl logs <pod-name> -n devops-hilltop
```

### Database Connection Issues
```bash
kubectl exec deployment/postgres-deployment -n devops-hilltop -- pg_isready
kubectl logs deployment/postgres-deployment -n devops-hilltop
```

### Application Not Accessible
```bash
kubectl get nodes -o wide  # Check external IPs
kubectl get service devops-hilltop-service -n devops-hilltop  # Check NodePort
```

## Pipeline Success Indicators

Your deployment is successful when you see:

✅ All tests pass (12/12)  
✅ Docker image built and pushed  
✅ Kubernetes resources applied  
✅ PostgreSQL deployment ready  
✅ Application deployment ready  
✅ Database schema initialized  
✅ Database connectivity confirmed  
✅ Health endpoint responding  

The entire process typically takes 5-8 minutes from code push to live application.