#!/bin/bash

echo "Fixing deployment issues..."

# Delete the existing problematic PVC and pods
echo "Cleaning up existing resources..."
kubectl delete pvc postgres-pvc -n devops-hilltop --ignore-not-found=true
kubectl delete pods --all -n devops-hilltop --ignore-not-found=true

# Build and push updated Docker image
echo "Building updated Docker image..."
docker build -t hilltopconsultancy/devops-hilltop:latest .
docker push hilltopconsultancy/devops-hilltop:latest

# Apply the fixed manifests
echo "Applying updated manifests..."
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/secret.yaml
kubectl apply -f k8s/postgres-secret.yaml
kubectl apply -f k8s/postgres-pvc.yaml
kubectl apply -f k8s/postgres-deployment.yaml
kubectl apply -f k8s/postgres-service.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml

# Force restart of the application deployment
kubectl rollout restart deployment/devops-hilltop-app -n devops-hilltop

echo "Waiting for deployments to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/postgres -n devops-hilltop
kubectl wait --for=condition=available --timeout=300s deployment/devops-hilltop-app -n devops-hilltop

echo "Initializing database..."
kubectl exec deployment/devops-hilltop-app -n devops-hilltop -- npm run db:push

echo "Checking deployment status..."
kubectl get pods -n devops-hilltop
kubectl get pvc -n devops-hilltop
kubectl get services -n devops-hilltop

echo "Testing API endpoints..."
APP_POD=$(kubectl get pods -n devops-hilltop -l app=devops-hilltop-app -o jsonpath='{.items[0].metadata.name}')
kubectl exec $APP_POD -n devops-hilltop -- curl -s http://localhost:5000/api/health || echo "Health check failed"

echo "Deployment fix complete!"