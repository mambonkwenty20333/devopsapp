# Terraform EKS Infrastructure

This Terraform configuration creates a complete AWS EKS cluster infrastructure for the DevOps with Hilltop application.

## Architecture

### Network Infrastructure
- **VPC**: Custom VPC with CIDR 10.0.0.0/16
- **Subnets**: 2 public and 2 private subnets across multiple AZs
- **NAT Gateways**: 2 NAT gateways for high availability
- **Internet Gateway**: For public subnet internet access
- **Route Tables**: Separate routing for public and private subnets

### EKS Cluster
- **Cluster Name**: devops-hilltop-cluster
- **Kubernetes Version**: 1.28
- **Node Group**: 2 t3.medium instances (desired), scales 1-3
- **Location**: eu-central-1 region
- **Networking**: Private worker nodes, public API endpoint

### Security
- **Cluster Security Group**: Controls access to EKS control plane
- **Node Security Group**: Controls worker node traffic
- **NodePort Access**: Opens ports 30000-32767 for application access
- **IAM Roles**: Separate roles for cluster and worker nodes

## Prerequisites

1. **AWS CLI configured** with appropriate credentials
2. **Terraform installed** (version >= 1.0)
3. **kubectl installed** for cluster management
4. **Sufficient AWS permissions** for:
   - VPC and networking resources
   - EKS cluster and node groups
   - IAM roles and policies
   - CloudWatch log groups

## Usage

### 1. Initialize Terraform
```bash
cd terraform
terraform init
```

### 2. Plan Infrastructure
```bash
terraform plan
```

### 3. Apply Configuration
```bash
terraform apply
```

### 4. Configure kubectl
```bash
aws eks update-kubeconfig --region eu-central-1 --name devops-hilltop-cluster
```

### 5. Verify Cluster
```bash
kubectl get nodes
kubectl get pods -A
```

## Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `aws_region` | AWS region | eu-central-1 |
| `cluster_name` | EKS cluster name | devops-hilltop-cluster |
| `kubernetes_version` | Kubernetes version | 1.28 |
| `node_instance_type` | EC2 instance type | t3.medium |
| `node_group_desired_size` | Desired number of nodes | 2 |
| `vpc_cidr` | VPC CIDR block | 10.0.0.0/16 |

## Outputs

The configuration provides these outputs:
- `cluster_endpoint`: EKS API server endpoint
- `cluster_certificate_authority_data`: CA certificate for cluster access
- `vpc_id`: VPC identifier
- `kubeconfig_command`: Command to configure kubectl

## Cost Considerations

**Estimated Monthly Costs (eu-central-1):**
- EKS Control Plane: ~$73/month
- 2x t3.medium instances: ~$60/month
- NAT Gateways: ~$32/month
- **Total: ~$165/month**

**Cost Optimization Tips:**
- Use Spot instances for non-production workloads
- Consider single NAT gateway for development environments
- Enable cluster autoscaler to scale down during low usage

## Security Best Practices

1. **Network Security**
   - Worker nodes in private subnets
   - Security groups with minimal required access
   - VPC endpoints for AWS services (optional)

2. **Access Control**
   - Use IAM roles for service accounts (IRSA)
   - Enable audit logging
   - Regular security updates

3. **Monitoring**
   - CloudWatch logging enabled
   - Monitor cluster and node metrics
   - Set up alerts for unusual activity

## Deployment Integration

This infrastructure works with the application's CI/CD pipeline:

1. **CircleCI Pipeline** deploys applications to this cluster
2. **Kubernetes Manifests** in `/k8s` directory target this infrastructure
3. **NodePort Service** exposes application on port 30080

## Cleanup

To destroy the infrastructure:
```bash
terraform destroy
```

**Warning**: This will delete all resources including data. Ensure you have backups if needed.

## Troubleshooting

### Common Issues

1. **Permission Denied**
   - Verify AWS credentials and permissions
   - Check IAM user has EKS and EC2 full access

2. **Cluster Creation Timeout**
   - Check subnet configurations
   - Verify internet connectivity for private subnets

3. **Node Group Issues**
   - Ensure subnets have available IP addresses
   - Check security group configurations

### Useful Commands

```bash
# Check cluster status
aws eks describe-cluster --name devops-hilltop-cluster --region eu-central-1

# View worker nodes
kubectl get nodes -o wide

# Check system pods
kubectl get pods -n kube-system

# View cluster events
kubectl get events --sort-by=.metadata.creationTimestamp
```

## Integration with Application

After cluster creation, deploy the application:

```bash
# Apply Kubernetes manifests
kubectl apply -f k8s/

# Check deployment status
kubectl get deployments -n devops-hilltop

# Get application URL
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="ExternalIP")].address}')
echo "Application URL: http://$NODE_IP:30080"
```

The application will be accessible via any worker node's public IP on port 30080.