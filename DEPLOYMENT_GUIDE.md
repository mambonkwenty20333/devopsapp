# DevOps with Hilltop - AWS EKS Deployment Guide

This guide provides step-by-step instructions for deploying the DevOps with Hilltop application to AWS EKS with automated CI/CD via CircleCI.

## 🎯 Overview

The deployment uses:
- **AWS EKS** for Kubernetes cluster management
- **NodePort service** for external access (port 30080)
- **CircleCI** for automated CI/CD pipeline
- **Docker Hub** for container image registry

## 📋 Prerequisites Checklist

Before starting, ensure you have:

- [ ] AWS account with appropriate permissions
- [ ] Docker Hub account
- [ ] CircleCI account
- [ ] Git repository connected to CircleCI
- [ ] Local machine with AWS CLI, kubectl, and eksctl installed

## 🔧 Step 1: AWS Setup

### 1.1 Install Required Tools

```bash
# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Install eksctl
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
```

### 1.2 Configure AWS Credentials

```bash
aws configure
```

Enter your:
- AWS Access Key ID
- AWS Secret Access Key
- Default region: `us-west-2`
- Output format: `json`

### 1.3 Create EKS Cluster

```bash
eksctl create cluster \
  --name devops-hilltop-cluster \
  --region us-west-2 \
  --nodegroup-name workers \
  --node-type t3.medium \
  --nodes 3 \
  --nodes-min 2 \
  --nodes-max 5 \
  --managed
```

This process takes 15-20 minutes. The cluster will include:
- 3 worker nodes (t3.medium instances)
- Auto-scaling from 2-5 nodes
- Managed node group for easier maintenance

## 🐳 Step 2: Docker Hub Setup

### 2.1 Create Docker Hub Access Token

1. Login to [Docker Hub](https://hub.docker.com)
2. Go to **Account Settings** → **Security**
3. Click **New Access Token**
4. Name: `CircleCI-DevOps-Hilltop`
5. Permissions: **Read, Write, Delete**
6. Save the generated token securely

## 🔄 Step 3: CircleCI Configuration

### 3.1 Connect Repository to CircleCI

1. Go to [CircleCI](https://circleci.com)
2. Sign in with your GitHub/Bitbucket account
3. Click **Projects** → **Set Up Project**
4. Select your repository

### 3.2 Add Environment Variables

In your CircleCI project settings (**Project Settings** → **Environment Variables**), add:

| Variable Name | Value | Description |
|---------------|-------|-------------|
| `DOCKER_USERNAME` | your_dockerhub_username | Docker Hub username |
| `DOCKER_PASSWORD` | your_access_token | Docker Hub access token |
| `AWS_ACCESS_KEY_ID` | your_aws_key | AWS access key |
| `AWS_SECRET_ACCESS_KEY` | your_aws_secret | AWS secret key |
| `AWS_DEFAULT_REGION` | us-west-2 | AWS region |
| `EKS_CLUSTER_NAME` | devops-hilltop-cluster | EKS cluster name |

### 3.3 Required AWS IAM Permissions

Your AWS user needs these policies:
- `AmazonEKSClusterPolicy`
- `AmazonEKSWorkerNodePolicy`
- `AmazonEC2ContainerRegistryPowerUser`
- `AmazonEC2ReadOnlyAccess`

## 🚀 Step 4: Deployment Process

### 4.1 Branch Strategy

The CI/CD pipeline follows this workflow:

```
develop branch → Automatic staging deployment
main branch → Manual approval → Production deployment
```

### 4.2 Initial Deployment

1. **Push to develop branch:**
   ```bash
   git checkout develop
   git push origin develop
   ```
   
   This triggers:
   - Automated testing
   - Security scanning
   - Docker image build and push
   - Automatic deployment to staging

2. **Production deployment:**
   ```bash
   git checkout main
   git merge develop
   git push origin main
   ```
   
   This requires manual approval in CircleCI dashboard.

### 4.3 Monitor Deployment

Track your deployment in CircleCI:
1. Go to your project dashboard
2. Click on the running workflow
3. Monitor each job's progress
4. Approve production deployment when ready

## 🌐 Step 5: Access Your Application

### 5.1 Get Access Information

```bash
# Configure kubectl for your cluster
aws eks update-kubeconfig --region us-west-2 --name devops-hilltop-cluster

# Get service details
kubectl get service devops-hilltop-service -n devops-hilltop

# Get node external IPs
kubectl get nodes -o wide
```

### 5.2 Access URL

Your application will be accessible at:
```
http://<NODE_EXTERNAL_IP>:30080
```

Use any of the worker node external IPs with port 30080.

## 🔍 Step 6: Verification

### 6.1 Check Deployment Status

```bash
# Check pods
kubectl get pods -n devops-hilltop

# Check services
kubectl get services -n devops-hilltop

# Check deployment
kubectl get deployment -n devops-hilltop

# View application logs
kubectl logs deployment/devops-hilltop-deployment -n devops-hilltop
```

### 6.2 Health Check

Test the health endpoint:
```bash
curl http://<NODE_EXTERNAL_IP>:30080/health
```

Expected response:
```json
{
  "status": "healthy",
  "timestamp": "2024-01-01T12:00:00.000Z",
  "service": "DevOps with Hilltop"
}
```

## 🛠 Troubleshooting

### Common Issues

**1. CircleCI Authentication Errors**
- Verify Docker Hub credentials
- Ensure access token has proper permissions
- Check AWS credentials format

**2. EKS Connection Issues**
- Verify kubectl configuration: `kubectl config current-context`
- Check AWS credentials: `aws sts get-caller-identity`
- Ensure IAM permissions are correct

**3. Application Not Accessible**
- Check NodePort service: `kubectl get svc -n devops-hilltop`
- Verify security groups allow traffic on port 30080
- Check pod status: `kubectl get pods -n devops-hilltop`

**4. Database Connection Issues**
- Check secret configuration: `kubectl get secrets -n devops-hilltop`
- Verify PostgreSQL pod is running
- Check database logs

### Useful Commands

```bash
# Restart deployment
kubectl rollout restart deployment/devops-hilltop-deployment -n devops-hilltop

# Scale deployment
kubectl scale deployment devops-hilltop-deployment --replicas=5 -n devops-hilltop

# Delete and redeploy
kubectl delete -f k8s/
kubectl apply -f k8s/

# Check cluster events
kubectl get events -n devops-hilltop --sort-by=.metadata.creationTimestamp
```

## 🔒 Security Considerations

### Network Security
- NodePort 30080 is exposed on all worker nodes
- Consider using AWS Application Load Balancer for production
- Implement proper security groups and NACLs

### Container Security
- Images are scanned for vulnerabilities with Trivy
- Containers run as non-root user
- Read-only root filesystem enabled
- Security context configured

### Secrets Management
- Database credentials stored as Kubernetes secrets
- Environment variables properly configured
- Access tokens secured in CircleCI

## 📊 Monitoring and Maintenance

### Scaling
The application includes Horizontal Pod Autoscaler (HPA):
- Minimum replicas: 2
- Maximum replicas: 10
- CPU target: 70%
- Memory target: 80%

### Updates
To update the application:
1. Make changes to your code
2. Push to develop for testing
3. Merge to main for production
4. CircleCI handles the rest automatically

### Backup
Consider implementing:
- Database backups using AWS RDS automated backups
- Persistent volume snapshots
- GitOps for infrastructure as code

## 🎉 Success!

Your DevOps with Hilltop application is now running on AWS EKS with:
- High availability with multiple replicas
- Auto-scaling based on resource usage
- Automated CI/CD pipeline
- Container security best practices
- Production-ready infrastructure

Access your application at `http://<NODE_EXTERNAL_IP>:30080` and enjoy your fully deployed DevOps resource platform!