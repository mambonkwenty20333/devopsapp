#!/bin/bash

# Deploy DEVOPS WITH HILLTOP to existing EKS cluster
# This script assumes you have kubectl configured for your existing cluster

set -e

echo "🚀 Deploying DEVOPS WITH HILLTOP to existing EKS cluster..."

# Check if kubectl is configured
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ kubectl is not configured or cluster is not accessible"
    echo "Please run: aws eks update-kubeconfig --region <region> --name <cluster-name>"
    exit 1
fi

CLUSTER_NAME=$(kubectl config current-context | cut -d'/' -f2)
echo "✅ Connected to cluster: $CLUSTER_NAME"

# Check if AWS Load Balancer Controller is installed
if ! kubectl get deployment aws-load-balancer-controller -n kube-system &> /dev/null; then
    echo "⚠️  AWS Load Balancer Controller not found"
    echo "Installing AWS Load Balancer Controller..."
    
    # Install via Helm (requires cluster name)
    helm repo add eks https://aws.github.io/eks-charts
    helm repo update
    
    echo "Please install AWS Load Balancer Controller manually:"
    echo "helm install aws-load-balancer-controller eks/aws-load-balancer-controller \\"
    echo "  -n kube-system \\"
    echo "  --set clusterName=$CLUSTER_NAME \\"
    echo "  --set serviceAccount.create=true"
    echo ""
    echo "Then re-run this script."
    exit 1
fi

echo "✅ AWS Load Balancer Controller is installed"

# Apply GP3 storage class
echo "📦 Applying GP3 storage class..."
kubectl apply -f k8s/storageclass-gp3.yaml

# Apply all manifests
echo "🔧 Deploying application manifests..."
kubectl apply -f k8s/

# Wait for deployment
echo "⏳ Waiting for deployment to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/devops-hilltop-deployment -n devops-hilltop

# Wait for LoadBalancer
echo "🌐 Waiting for LoadBalancer to be provisioned..."
echo "This may take 2-3 minutes..."

# Check LoadBalancer status
kubectl get service devops-hilltop-service -n devops-hilltop

# Wait for external IP/hostname
echo "⏳ Waiting for LoadBalancer external endpoint..."
for i in {1..60}; do
    EXTERNAL_IP=$(kubectl get service devops-hilltop-service -n devops-hilltop -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
    if [ -n "$EXTERNAL_IP" ]; then
        echo "✅ LoadBalancer provisioned successfully!"
        echo "🌍 Application URL: http://$EXTERNAL_IP"
        break
    fi
    echo "Waiting... ($i/60)"
    sleep 5
done

if [ -z "$EXTERNAL_IP" ]; then
    echo "⚠️  LoadBalancer still pending. Check logs:"
    echo "kubectl logs -n kube-system deployment/aws-load-balancer-controller"
    echo "kubectl describe service devops-hilltop-service -n devops-hilltop"
    exit 1
fi

# Test application
echo "🧪 Testing application accessibility..."
if curl -f -s "http://$EXTERNAL_IP" > /dev/null; then
    echo "✅ Application is accessible!"
else
    echo "⚠️  Application not yet accessible, may need a few more minutes"
fi

echo ""
echo "🎉 Deployment completed successfully!"
echo "📊 Dashboard URL: http://$EXTERNAL_IP/dashboard"
echo "📝 Contact Form: http://$EXTERNAL_IP"
echo ""
echo "💡 To check status:"
echo "kubectl get pods -n devops-hilltop"
echo "kubectl get service devops-hilltop-service -n devops-hilltop"