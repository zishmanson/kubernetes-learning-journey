#!/bin/bash

# AWS EKS Deployment Script
# This script automates the deployment process

set -e

echo "🚀 Task API - AWS EKS Deployment Script"
echo "========================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check prerequisites
echo "Checking prerequisites..."

command -v aws >/dev/null 2>&1 || { echo -e "${RED}❌ AWS CLI is not installed${NC}" >&2; exit 1; }
command -v terraform >/dev/null 2>&1 || { echo -e "${RED}❌ Terraform is not installed${NC}" >&2; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo -e "${RED}❌ kubectl is not installed${NC}" >&2; exit 1; }
command -v docker >/dev/null 2>&1 || { echo -e "${RED}❌ Docker is not installed${NC}" >&2; exit 1; }

echo -e "${GREEN}✓ All prerequisites installed${NC}"

# Get AWS Account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=${AWS_REGION:-us-east-1}

echo "AWS Account ID: $AWS_ACCOUNT_ID"
echo "AWS Region: $AWS_REGION"

# Step 1: Deploy Infrastructure
echo ""
echo "Step 1: Deploying infrastructure with Terraform..."
cd terraform/

if [ ! -d ".terraform" ]; then
    echo "Initializing Terraform..."
    terraform init
fi

echo "Planning infrastructure..."
terraform plan

read -p "Do you want to apply this plan? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    echo "Deployment cancelled"
    exit 1
fi

echo "Applying infrastructure..."
terraform apply -auto-approve

# Get outputs
ECR_URL=$(terraform output -raw ecr_repository_url)
IAM_ROLE_ARN=$(terraform output -raw task_api_pod_role_arn)
CLUSTER_NAME=$(terraform output -raw cluster_name)

echo -e "${GREEN}✓ Infrastructure deployed${NC}"

# Step 2: Configure kubectl
echo ""
echo "Step 2: Configuring kubectl..."
aws eks update-kubeconfig --region $AWS_REGION --name $CLUSTER_NAME
echo -e "${GREEN}✓ kubectl configured${NC}"

# Step 3: Build and push Docker image
echo ""
echo "Step 3: Building and pushing Docker image..."
cd ..

# Login to ECR
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_URL

# Build image
echo "Building Docker image..."
docker build -t task-api:latest .

# Tag image
echo "Tagging image..."
docker tag task-api:latest $ECR_URL:latest
docker tag task-api:latest $ECR_URL:$(date +%Y%m%d-%H%M%S)

# Push image
echo "Pushing image to ECR..."
docker push $ECR_URL:latest

echo -e "${GREEN}✓ Image pushed to ECR${NC}"

# Step 4: Update Kubernetes manifests
echo ""
echo "Step 4: Updating Kubernetes manifests..."

# Update service account
sed -i.bak "s|REPLACE_WITH_IAM_ROLE_ARN|$IAM_ROLE_ARN|g" k8s/aws/serviceaccount.yaml

# Update deployment
sed -i.bak "s|REPLACE_WITH_ECR_IMAGE_URL|$ECR_URL|g" k8s/aws/api-deployment.yaml

echo -e "${GREEN}✓ Manifests updated${NC}"

# Step 5: Deploy to Kubernetes
echo ""
echo "Step 5: Deploying to Kubernetes..."

kubectl apply -f k8s/aws/serviceaccount.yaml
kubectl apply -f k8s/aws/api-deployment.yaml

echo "Waiting for pods to be ready..."
kubectl wait --for=condition=ready pod -l app=task-api --timeout=300s

echo -e "${GREEN}✓ Application deployed${NC}"

# Step 6: Get Load Balancer URL
echo ""
echo "Step 6: Getting Load Balancer URL..."
echo "Waiting for Load Balancer to be provisioned (this may take 2-3 minutes)..."

for i in {1..20}; do
    LB_URL=$(kubectl get svc task-api-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
    if [ -n "$LB_URL" ]; then
        break
    fi
    echo "Still waiting... ($i/20)"
    sleep 15
done

if [ -z "$LB_URL" ]; then
    echo -e "${YELLOW}⚠ Load Balancer URL not ready yet. Check with: kubectl get svc task-api-service${NC}"
else
    echo -e "${GREEN}✓ Load Balancer ready!${NC}"
    echo ""
    echo "=========================================="
    echo "🎉 Deployment Complete!"
    echo "=========================================="
    echo ""
    echo "Load Balancer URL: http://$LB_URL"
    echo ""
    echo "Test your API:"
    echo "  curl http://$LB_URL/health"
    echo ""
    echo "View pods:"
    echo "  kubectl get pods"
    echo ""
    echo "View logs:"
    echo "  kubectl logs -f deployment/task-api"
    echo ""
    echo "View HPA:"
    echo "  kubectl get hpa"
    echo ""
fi

echo ""
echo "IMPORTANT: Remember to destroy resources when done to avoid charges!"
echo "Run: cd terraform && terraform destroy"
