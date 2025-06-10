#!/bin/bash

echo "Fixing deployment issues and forcing image updates..."

# Generate unique tag to force image pull
TIMESTAMP=$(date +%s)
SHORT_SHA=$(git rev-parse --short HEAD 2>/dev/null || echo "manual")
IMAGE_TAG="${SHORT_SHA}-${TIMESTAMP}"

echo "Building and pushing Docker image with tag: $IMAGE_TAG"
docker build -t hilltopconsultancy/devops-hilltop:$IMAGE_TAG .
docker push hilltopconsultancy/devops-hilltop:$IMAGE_TAG

# Also tag and push as latest
docker tag hilltopconsultancy/devops-hilltop:$IMAGE_TAG hilltopconsultancy/devops-hilltop:latest
docker push hilltopconsultancy/devops-hilltop:latest

# Delete problematic resources first
echo "Cleaning up existing resources..."
kubectl delete pvc postgres-pvc -n devops-hilltop --ignore-not-found=true
kubectl delete pods --all -n devops-hilltop --ignore-not-found=true --force --grace-period=0

# Update deployment manifest with unique image tag
echo "Updating deployment manifest with new image tag..."
sed -i "s|image: hilltopconsultancy/devops-hilltop:.*|image: hilltopconsultancy/devops-hilltop:$IMAGE_TAG|g" k8s/deployment.yaml

# Apply all manifests
echo "Applying updated manifests..."
kubectl apply -f k8s/

# Force restart application deployment to ensure new image is pulled
echo "Force restarting application deployment..."
kubectl rollout restart deployment/devops-hilltop-app -n devops-hilltop

# Wait for PostgreSQL first
echo "Waiting for PostgreSQL to be ready..."
kubectl wait --for=condition=available --timeout=600s deployment/postgres -n devops-hilltop || {
    echo "PostgreSQL deployment failed, checking status..."
    kubectl describe deployment postgres -n devops-hilltop
    kubectl get events -n devops-hilltop --sort-by='.lastTimestamp'
    exit 1
}

# Wait for application deployment
echo "Waiting for application to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/devops-hilltop-app -n devops-hilltop || {
    echo "Application deployment failed, checking status..."
    kubectl describe deployment devops-hilltop-app -n devops-hilltop
    kubectl logs -l app=devops-platform -n devops-hilltop --tail=50
    exit 1
}

echo "Initializing database..."
kubectl exec deployment/devops-hilltop-app -n devops-hilltop -- npm run db:push

echo "Checking final deployment status..."
kubectl get pods -n devops-hilltop
kubectl get pvc -n devops-hilltop
kubectl get services -n devops-hilltop

echo "Testing API endpoints..."
APP_POD=$(kubectl get pods -n devops-hilltop -l app=devops-platform -o jsonpath='{.items[0].metadata.name}')
if [ ! -z "$APP_POD" ]; then
    kubectl exec $APP_POD -n devops-hilltop -- curl -s http://localhost:5000/api/health || echo "Health check failed"
    kubectl exec $APP_POD -n devops-hilltop -- curl -s http://localhost:5000/api/categories | head -c 100 || echo "API test failed"
else
    echo "No application pods found"
fi

# Restore original deployment.yaml
echo "Restoring original deployment.yaml..."
sed -i "s|image: hilltopconsultancy/devops-hilltop:.*|image: hilltopconsultancy/devops-hilltop:latest|g" k8s/deployment.yaml

echo "Deployment fix complete! Image tag used: $IMAGE_TAG"