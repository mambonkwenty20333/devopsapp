#!/bin/bash

set -e

echo "Applying comprehensive PostgreSQL permission fix..."

# Clean up existing resources completely
kubectl delete deployment postgres -n devops-hilltop --ignore-not-found=true
kubectl delete pvc postgres-pvc -n devops-hilltop --ignore-not-found=true

echo "Waiting for complete resource cleanup..."
sleep 20

# Apply corrected manifests
kubectl apply -f k8s/postgres-pvc.yaml
kubectl apply -f k8s/postgres-secret.yaml
kubectl apply -f k8s/postgres-deployment.yaml
kubectl apply -f k8s/postgres-service.yaml

echo "Waiting for PostgreSQL to initialize..."
kubectl rollout status deployment/postgres -n devops-hilltop --timeout=300s

# Verify deployment
kubectl get pods -n devops-hilltop -l app=postgres
kubectl logs -n devops-hilltop -l app=postgres --tail=10

echo "PostgreSQL deployment completed successfully!"