# LoadBalancer Configuration for Existing EKS Cluster

## Service Configuration

The Kubernetes service now uses modern AWS Load Balancer Controller annotations that automatically discover subnets without hardcoded references:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: devops-hilltop-service
  namespace: devops-hilltop
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: external
    service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: ip
    service.beta.kubernetes.io/aws-load-balancer-scheme: internet-facing
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 5000
    protocol: TCP
  selector:
    app: devops-platform
```

## Key Benefits

### 1. No Hardcoded Subnet References
- Automatically discovers public subnets tagged with `kubernetes.io/role/elb=1`
- Works with any properly configured EKS cluster
- No need to modify Terraform or Kubernetes manifests for different environments

### 2. Modern Load Balancer Controller
- Uses `external` type for AWS Load Balancer Controller v2.0+
- Targets pod IPs directly with `nlb-target-type: ip`
- Creates Network Load Balancer for optimal performance

### 3. Flexible Deployment
- Works with existing EKS clusters
- Compatible with Terraform-managed infrastructure
- Supports both new and existing VPC configurations

## Required Prerequisites

### 1. AWS Load Balancer Controller
Must be installed in your EKS cluster:
```bash
helm repo add eks https://aws.github.io/eks-charts
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=YOUR_CLUSTER_NAME
```

### 2. Subnet Tagging
Public subnets must be tagged for LoadBalancer discovery:
```bash
# Tag public subnets
aws ec2 create-tags --resources subnet-xxxxxxxxx --tags \
  Key=kubernetes.io/role/elb,Value=1 \
  Key=kubernetes.io/cluster/YOUR_CLUSTER_NAME,Value=shared
```

### 3. IAM Permissions
AWS Load Balancer Controller requires specific IAM permissions:
- ElasticLoadBalancingFullAccess
- EC2 permissions for subnet and security group management
- Route53 permissions for DNS management (if using)

## Deployment Process

### 1. Quick Deployment
```bash
# Automated deployment script
./scripts/deploy-to-existing-cluster.sh
```

### 2. Manual Deployment
```bash
# Apply storage class
kubectl apply -f k8s/storageclass-gp3.yaml

# Apply all manifests
kubectl apply -f k8s/

# Monitor LoadBalancer creation
kubectl get service devops-hilltop-service -n devops-hilltop -w
```

### 3. Verification
```bash
# Get LoadBalancer URL
LB_URL=$(kubectl get service devops-hilltop-service -n devops-hilltop -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# Test application
curl -f http://$LB_URL

# Access dashboard
curl -f http://$LB_URL/dashboard
```

## Terraform Integration

### For Existing Clusters
```hcl
# terraform.tfvars
use_existing_cluster = true
existing_cluster_name = "your-cluster-name"
existing_vpc_name = "your-vpc-name"
aws_region = "eu-central-1"
```

### For New Clusters
```hcl
# terraform.tfvars
use_existing_cluster = false
aws_region = "eu-central-1"
cluster_name = "devops-hilltop-cluster"
```

## Cost Considerations

### LoadBalancer Costs (eu-central-1)
- Network Load Balancer: ~$18/month
- Data processing: $0.006 per GB
- Cross-AZ traffic: $0.01 per GB

### Compared to NodePort
- NodePort: No additional AWS costs
- LoadBalancer: Enterprise-grade with AWS-managed endpoint
- Security: LoadBalancer provides better security isolation

## Troubleshooting

### LoadBalancer Pending
```bash
# Check controller logs
kubectl logs -n kube-system deployment/aws-load-balancer-controller

# Verify subnet tags
aws ec2 describe-subnets --filters "Name=tag:kubernetes.io/role/elb,Values=1"

# Check service events
kubectl describe service devops-hilltop-service -n devops-hilltop
```

### Common Issues
1. **Missing subnet tags**: Ensure `kubernetes.io/role/elb=1` on public subnets
2. **Controller not installed**: Install AWS Load Balancer Controller
3. **Insufficient permissions**: Verify IAM roles and policies
4. **Security groups**: Ensure proper ingress rules for ports 80/443

## Production Considerations

### High Availability
- LoadBalancer automatically distributes across multiple AZs
- Health checks ensure traffic only goes to healthy pods
- Automatic failover between availability zones

### Security
- Network Load Balancer provides L4 load balancing
- Security groups control access at instance level
- No direct pod IP exposure to internet

### Monitoring
```bash
# Monitor LoadBalancer health
kubectl get events -n devops-hilltop --sort-by=.lastTimestamp

# Check pod distribution
kubectl get pods -n devops-hilltop -o wide

# View service details
kubectl describe service devops-hilltop-service -n devops-hilltop
```

This configuration provides enterprise-grade load balancing without hardcoded dependencies, making it suitable for deployment to any properly configured EKS cluster.