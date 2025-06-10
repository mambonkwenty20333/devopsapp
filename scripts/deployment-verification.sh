#!/bin/bash

# Comprehensive Deployment Verification Script
# Validates CircleCI, Kubernetes, and Terraform configurations

set -e

ERRORS=()
WARNINGS=()

echo "Starting comprehensive deployment verification..."

# Function to log errors and warnings
log_error() {
    ERRORS+=("❌ $1")
    echo "❌ ERROR: $1"
}

log_warning() {
    WARNINGS+=("⚠️  $1")
    echo "⚠️  WARNING: $1"
}

log_success() {
    echo "✅ $1"
}

# 1. CircleCI Configuration Validation
echo ""
echo "=== CircleCI Configuration Review ==="

# Check if CircleCI config exists and is valid YAML
if [ -f ".circleci/config.yml" ]; then
    log_success "CircleCI config file exists"
    
    # Validate YAML syntax
    if command -v yamllint >/dev/null 2>&1; then
        if yamllint .circleci/config.yml >/dev/null 2>&1; then
            log_success "CircleCI YAML syntax is valid"
        else
            log_error "CircleCI YAML syntax errors detected"
        fi
    else
        log_warning "yamllint not available for YAML validation"
    fi
    
    # Check for correct image references
    if grep -q "hilltopconsultancy/devops-hilltop:latest" .circleci/config.yml; then
        log_success "Correct Docker image reference found"
    else
        log_error "Docker image reference incorrect in CircleCI config"
    fi
    
    # Check for LoadBalancer health checks
    if grep -q "loadBalancer.ingress" .circleci/config.yml; then
        log_success "LoadBalancer health checks configured"
    else
        log_error "NodePort health checks found instead of LoadBalancer"
    fi
    
    # Check for PostgreSQL deployment configuration
    if grep -q "postgres-deployment" .circleci/config.yml; then
        log_success "PostgreSQL deployment properly configured"
    else
        log_error "PostgreSQL deployment missing from CircleCI config"
    fi
    
else
    log_error "CircleCI config file missing"
fi

# 2. Kubernetes Manifests Validation
echo ""
echo "=== Kubernetes Manifests Review ==="

K8S_DIR="k8s"

# Check namespace configuration
if [ -f "$K8S_DIR/namespace.yaml" ]; then
    log_success "Namespace manifest exists"
else
    log_error "Namespace manifest missing"
fi

# Check deployment configuration
if [ -f "$K8S_DIR/deployment.yaml" ]; then
    log_success "Deployment manifest exists"
    
    # Check image reference
    if grep -q "hilltopconsultancy/devops-hilltop:latest" "$K8S_DIR/deployment.yaml"; then
        log_success "Correct Docker image in deployment"
    else
        log_error "Incorrect Docker image reference in deployment"
    fi
    
    # Check resource limits
    if grep -q "resources:" "$K8S_DIR/deployment.yaml"; then
        log_success "Resource limits configured"
    else
        log_warning "No resource limits defined"
    fi
    
    # Check prometheus annotations
    if grep -q "prometheus.io/scrape" "$K8S_DIR/deployment.yaml"; then
        log_success "Prometheus monitoring annotations configured"
    else
        log_warning "Prometheus monitoring annotations missing"
    fi
else
    log_error "Deployment manifest missing"
fi

# Check service configuration
if [ -f "$K8S_DIR/service.yaml" ]; then
    log_success "Service manifest exists"
    
    # Check service type
    if grep -q "type: LoadBalancer" "$K8S_DIR/service.yaml"; then
        log_success "LoadBalancer service type configured"
    else
        log_error "Service type is not LoadBalancer"
    fi
    
    # Check LoadBalancer annotations
    if grep -q "aws-load-balancer-type: external" "$K8S_DIR/service.yaml"; then
        log_success "Modern AWS LoadBalancer annotations configured"
    else
        log_error "Missing or incorrect LoadBalancer annotations"
    fi
else
    log_error "Service manifest missing"
fi

# Check secrets configuration
if [ -f "$K8S_DIR/secret.yaml" ]; then
    log_success "Secret manifest exists"
    
    # Check for base64 encoded values
    if grep -q "DATABASE_URL:" "$K8S_DIR/secret.yaml" && grep -q "data:" "$K8S_DIR/secret.yaml"; then
        log_success "Database secrets properly configured"
    else
        log_error "Database secrets not properly configured"
    fi
else
    log_error "Secret manifest missing"
fi

# Check ConfigMap
if [ -f "$K8S_DIR/configmap.yaml" ]; then
    log_success "ConfigMap manifest exists"
else
    log_error "ConfigMap manifest missing"
fi

# Check HPA
if [ -f "$K8S_DIR/hpa.yaml" ]; then
    log_success "Horizontal Pod Autoscaler configured"
else
    log_warning "HPA not configured for auto-scaling"
fi

# Check storage class
if [ -f "$K8S_DIR/storageclass-gp3.yaml" ]; then
    log_success "GP3 storage class configured"
else
    log_error "GP3 storage class missing"
fi

# Check for PostgreSQL manifests
postgres_files=("$K8S_DIR/postgres-deployment.yaml" "$K8S_DIR/postgres-service.yaml" "$K8S_DIR/postgres-pvc.yaml" "$K8S_DIR/postgres-secret.yaml")
for file in "${postgres_files[@]}"; do
    if [ -f "$file" ]; then
        log_success "PostgreSQL manifest exists: $(basename $file)"
    else
        log_error "PostgreSQL manifest missing: $(basename $file)"
    fi
done

# 3. Terraform Configuration Validation
echo ""
echo "=== Terraform Configuration Review ==="

TERRAFORM_DIR="terraform"

if [ -f "$TERRAFORM_DIR/main.tf" ]; then
    log_success "Terraform main configuration exists"
    
    # Check for conditional resource creation
    if grep -q "var.use_existing_cluster" "$TERRAFORM_DIR/main.tf"; then
        log_success "Conditional resource creation configured"
    else
        log_warning "Resources not properly conditional for existing clusters"
    fi
    
    # Check for 3-tier architecture
    if grep -q "public_subnet" "$TERRAFORM_DIR/main.tf" && grep -q "private_subnet" "$TERRAFORM_DIR/main.tf" && grep -q "database_subnet" "$TERRAFORM_DIR/main.tf"; then
        log_success "3-tier subnet architecture configured"
    else
        log_error "3-tier subnet architecture not properly configured"
    fi
    
else
    log_error "Terraform main configuration missing"
fi

# Check variables file
if [ -f "$TERRAFORM_DIR/variables.tf" ]; then
    log_success "Terraform variables file exists"
    
    if grep -q "use_existing_cluster" "$TERRAFORM_DIR/variables.tf"; then
        log_success "Existing cluster variables configured"
    else
        log_error "Missing variables for existing cluster support"
    fi
else
    log_error "Terraform variables file missing"
fi

# Check outputs file
if [ -f "$TERRAFORM_DIR/outputs.tf" ]; then
    log_success "Terraform outputs file exists"
    
    # Check for conditional outputs
    if grep -q "var.use_existing_cluster" "$TERRAFORM_DIR/outputs.tf"; then
        log_success "Conditional outputs configured"
    else
        log_error "Outputs not properly conditional"
    fi
else
    log_error "Terraform outputs file missing"
fi

# Check data sources
if [ -f "$TERRAFORM_DIR/data-sources.tf" ]; then
    log_success "Data sources for existing cluster configured"
else
    log_warning "Data sources file missing for existing cluster support"
fi

# 4. Application Configuration Validation
echo ""
echo "=== Application Configuration Review ==="

# Check package.json scripts
if [ -f "package.json" ]; then
    log_success "Package.json exists"
    
    if grep -q "db:push" package.json; then
        log_success "Database migration script configured"
    else
        log_error "Database migration script missing"
    fi
    
    if grep -q "prom-client" package.json; then
        log_success "Prometheus metrics library included"
    else
        log_warning "Prometheus metrics library not found"
    fi
else
    log_error "Package.json missing"
fi

# Check Dockerfile
if [ -f "Dockerfile" ]; then
    log_success "Dockerfile exists"
    
    if grep -q "EXPOSE 5000" Dockerfile; then
        log_success "Correct port exposed in Dockerfile"
    else
        log_error "Port 5000 not exposed in Dockerfile"
    fi
else
    log_error "Dockerfile missing"
fi

# Check environment file
if [ -f ".env" ]; then
    log_success "Environment file exists"
else
    log_warning "Environment file missing (optional for Replit)"
fi

# Check database configuration
if [ -f "server/db.ts" ]; then
    log_success "Database configuration file exists"
    
    if grep -q "DATABASE_URL" server/db.ts; then
        log_success "Database URL environment variable used"
    else
        log_error "Database URL not properly configured"
    fi
else
    log_error "Database configuration missing"
fi

# Check metrics configuration
if [ -f "server/metrics.ts" ]; then
    log_success "Metrics configuration exists"
    
    if grep -q "contact_form_submissions_total" server/metrics.ts; then
        log_success "Custom application metrics configured"
    else
        log_warning "Custom metrics not fully configured"
    fi
else
    log_warning "Metrics configuration missing"
fi

# 5. Monitoring Stack Validation
echo ""
echo "=== Monitoring Stack Review ==="

if [ -d "monitoring" ]; then
    log_success "Monitoring directory exists"
    
    monitoring_files=("prometheus-deployment.yaml" "grafana-deployment.yaml" "node-exporter.yaml")
    for file in "${monitoring_files[@]}"; do
        if [ -f "monitoring/$file" ]; then
            log_success "Monitoring component: $file"
        else
            log_warning "Missing monitoring component: $file"
        fi
    done
    
    if [ -f "monitoring/deploy-monitoring.sh" ]; then
        log_success "Monitoring deployment script exists"
    else
        log_warning "Monitoring deployment script missing"
    fi
else
    log_warning "Monitoring stack not configured"
fi

# 6. Security and Best Practices
echo ""
echo "=== Security and Best Practices Review ==="

# Check for hardcoded secrets (exclude proper Kubernetes secret data format)
if grep -r "password.*:" k8s/ --exclude="*.md" | grep -v "secretKeyRef" | grep -v "data:" | grep -v "# " | grep -q "password"; then
    log_error "Hardcoded passwords found in manifests"
else
    log_success "No hardcoded passwords detected"
fi

# Check resource limits
if grep -q "resources:" k8s/deployment.yaml; then
    log_success "Resource limits configured"
else
    log_warning "Resource limits not configured"
fi

# Check security context
if grep -q "securityContext:" k8s/deployment.yaml; then
    log_success "Security context configured"
else
    log_warning "Security context not configured"
fi

# 7. Summary Report
echo ""
echo "=== Deployment Verification Summary ==="

if [ ${#ERRORS[@]} -eq 0 ]; then
    echo "🎉 No critical errors found! Deployment should succeed."
else
    echo "💥 Critical errors found that will prevent deployment:"
    for error in "${ERRORS[@]}"; do
        echo "  $error"
    done
fi

if [ ${#WARNINGS[@]} -gt 0 ]; then
    echo ""
    echo "⚠️  Warnings (should be addressed for production):"
    for warning in "${WARNINGS[@]}"; do
        echo "  $warning"
    done
fi

echo ""
echo "=== Next Steps ==="
if [ ${#ERRORS[@]} -eq 0 ]; then
    echo "✅ Ready for deployment!"
    echo "1. Ensure AWS credentials are configured in CircleCI"
    echo "2. Set Docker Hub credentials in CircleCI"
    echo "3. Configure EKS cluster name in CircleCI environment"
    echo "4. Push to develop branch for staging deployment"
    echo "5. Push to main branch for production deployment (requires approval)"
else
    echo "🔧 Fix the critical errors above before deployment"
fi

# Exit with error code if critical issues found
if [ ${#ERRORS[@]} -gt 0 ]; then
    exit 1
else
    exit 0
fi