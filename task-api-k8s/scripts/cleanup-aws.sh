#!/bin/bash

# AWS EKS Cleanup Script
# IMPORTANT: This will delete all AWS resources and cannot be undone!

set -e

echo "🗑️  Task API - AWS Cleanup Script"
echo "=================================="
echo ""
echo "⚠️  WARNING: This will DELETE all AWS resources!"
echo "This includes:"
echo "  - EKS Cluster (~$72/month)"
echo "  - EC2 instances"
echo "  - Load Balancers (~$16/month)"
echo "  - NAT Gateways (~$32/month)"
echo "  - DynamoDB tables"
echo "  - VPC and networking"
echo ""

read -p "Are you ABSOLUTELY SURE you want to proceed? (type 'DELETE' to confirm): " CONFIRM

if [ "$CONFIRM" != "DELETE" ]; then
    echo "Cleanup cancelled - your resources are safe"
    exit 0
fi

echo ""
echo "Starting cleanup process..."

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Step 1: Delete Kubernetes resources
echo ""
echo "Step 1: Deleting Kubernetes resources..."
if kubectl get deployment task-api &>/dev/null; then
    kubectl delete -f k8s/aws/api-deployment.yaml || true
    kubectl delete -f k8s/aws/serviceaccount.yaml || true
    
    echo "Waiting for Load Balancer to be deleted..."
    for i in {1..20}; do
        if ! kubectl get svc task-api-service &>/dev/null; then
            break
        fi
        echo "Still waiting for Load Balancer deletion... ($i/20)"
        sleep 15
    done
    echo -e "${GREEN}✓ Kubernetes resources deleted${NC}"
else
    echo "No Kubernetes resources found"
fi

# Step 2: Destroy Terraform infrastructure
echo ""
echo "Step 2: Destroying Terraform infrastructure..."
cd terraform/

if [ -f "terraform.tfstate" ]; then
    echo "Running terraform destroy..."
    terraform destroy -auto-approve
    echo -e "${GREEN}✓ Infrastructure destroyed${NC}"
else
    echo "No Terraform state found"
fi

cd ..

# Step 3: Verify cleanup
echo ""
echo "Step 3: Verifying cleanup..."

AWS_REGION=${AWS_REGION:-us-east-1}

echo "Checking for remaining resources..."

# Check EKS clusters
CLUSTERS=$(aws eks list-clusters --region $AWS_REGION --query 'clusters[?contains(@, `task-api`)]' --output text 2>/dev/null || echo "")
if [ -n "$CLUSTERS" ]; then
    echo -e "${YELLOW}⚠ Warning: EKS clusters still exist: $CLUSTERS${NC}"
fi

# Check Load Balancers
LBS=$(aws elbv2 describe-load-balancers --region $AWS_REGION --query 'LoadBalancers[?contains(LoadBalancerName, `task-api`)].LoadBalancerArn' --output text 2>/dev/null || echo "")
if [ -n "$LBS" ]; then
    echo -e "${YELLOW}⚠ Warning: Load Balancers still exist${NC}"
fi

# Check NAT Gateways
NATS=$(aws ec2 describe-nat-gateways --region $AWS_REGION --filter "Name=tag:Project,Values=task-api" --query 'NatGateways[?State==`available`].NatGatewayId' --output text 2>/dev/null || echo "")
if [ -n "$NATS" ]; then
    echo -e "${YELLOW}⚠ Warning: NAT Gateways still exist${NC}"
fi

echo ""
echo "=========================================="
echo "🎉 Cleanup Process Complete!"
echo "=========================================="
echo ""
echo "Please verify in AWS Console that all resources are deleted:"
echo "  - EC2 → Load Balancers"
echo "  - EC2 → NAT Gateways"
echo "  - EKS → Clusters"
echo "  - VPC → Your VPCs"
echo "  - DynamoDB → Tables"
echo ""
echo "If any resources remain, delete them manually to avoid charges."
echo ""
echo -e "${GREEN}✓ Cleanup complete!${NC}"
