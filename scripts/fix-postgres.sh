#!/bin/bash

set -e

echo "Fixing PostgreSQL CrashLoopBackOff issue..."

# Delete the existing deployment to force recreation
echo "Stopping existing PostgreSQL deployment..."
kubectl delete deployment postgres -n devops-hilltop --ignore-not-found=true

# Wait for pods to terminate
echo "Waiting for pods to terminate..."
sleep 10

# Redeploy PostgreSQL with fixed configuration
echo "Deploying PostgreSQL with corrected data directory..."
kubectl apply -f k8s/postgres-deployment.yaml

# Wait for deployment to be ready
echo "Waiting for PostgreSQL to be ready..."
kubectl rollout status deployment/postgres -n devops-hilltop --timeout=300s

# Verify the deployment
echo "Verifying PostgreSQL deployment..."
kubectl get pods -n devops-hilltop -l app=postgres

# Check PostgreSQL logs
echo "PostgreSQL logs:"
kubectl logs -n devops-hilltop -l app=postgres --tail=10

echo "PostgreSQL fix complete!"