#!/bin/bash

echo "Fixing deployment issues..."

# Delete the existing problematic PVC and pods
echo "Cleaning up existing resources..."
kubectl delete pvc postgres-pvc -n devops-hilltop --ignore-not-found=true
kubectl delete pods --all -n devops-hilltop --ignore-not-found=true

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

echo "Waiting for deployments to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/postgres -n devops-hilltop
kubectl wait --for=condition=available --timeout=300s deployment/devops-hilltop-app -n devops-hilltop

echo "Checking deployment status..."
kubectl get pods -n devops-hilltop
kubectl get pvc -n devops-hilltop
kubectl get services -n devops-hilltop

echo "Deployment fix complete!"