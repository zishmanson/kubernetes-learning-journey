# Task Management API - Cloud-Native Kubernetes Application

A production-ready REST API for task management, demonstrating modern DevOps practices including containerization, Kubernetes orchestration, observability, and cloud deployment.

## 🎯 Project Overview

This project showcases:
- ✅ **Python Flask REST API** with full CRUD operations
- ✅ **Docker** containerization
- ✅ **Kubernetes** orchestration (local and AWS EKS)
- ✅ **DynamoDB** for persistent storage
- ✅ **Prometheus** metrics and monitoring
- ✅ **Grafana** dashboards
- ✅ **Horizontal Pod Autoscaling**
- ✅ **CI/CD** with GitHub Actions
- ✅ **Infrastructure as Code** with Terraform

## 🏗️ Architecture

```
┌─────────────────┐
│   Internet      │
└────────┬────────┘
         │
    ┌────▼────┐
    │   ALB   │  (AWS only)
    └────┬────┘
         │
    ┌────▼─────────────┐
    │  Task API Pods   │  (2-5 replicas)
    │  (Auto-scaling)  │
    └────┬─────────────┘
         │
    ┌────▼────┐
    │DynamoDB │
    └─────────┘
         │
    ┌────▼─────────┐
    │  Prometheus  │
    └────┬─────────┘
         │
    ┌────▼─────────┐
    │   Grafana    │
    └──────────────┘
```

## 📋 Prerequisites

### For Local Development:
- Docker Desktop (with Kubernetes enabled)
- Python 3.9+
- kubectl CLI
- Git

### For AWS Deployment:
- AWS Account
- AWS CLI configured
- Terraform 1.0+
- eksctl (optional, for easier EKS management)

## 🚀 Quick Start - Local Development (Day 1-2)

### Step 1: Clone and Setup

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/task-api-k8s.git
cd task-api-k8s

# Create Python virtual environment (optional, for local testing)
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
```

### Step 2: Test Locally with Docker Compose

```bash
# Build and run with Docker Compose
docker-compose up --build

# In another terminal, test the API
curl http://localhost:5000/health

# Create a task
curl -X POST http://localhost:5000/tasks \
  -H "Content-Type: application/json" \
  -d '{"title":"Learn Kubernetes","description":"Deploy to K8s cluster"}'

# Get all tasks
curl http://localhost:5000/tasks

# Stop the containers
docker-compose down
```

✅ **Checkpoint**: Your API works with Docker!

### Step 3: Enable Kubernetes in Docker Desktop

1. Open Docker Desktop
2. Go to Settings → Kubernetes
3. Check "Enable Kubernetes"
4. Click "Apply & Restart"
5. Wait 2-3 minutes

```bash
# Verify Kubernetes is running
kubectl version
kubectl cluster-info
```

### Step 4: Build Docker Image for Kubernetes

```bash
# Build the image
docker build -t task-api:latest .

# Verify image exists
docker images | grep task-api
```

### Step 5: Deploy to Local Kubernetes

```bash
# Deploy DynamoDB Local
kubectl apply -f k8s/local/dynamodb-deployment.yaml

# Wait for DynamoDB to be ready
kubectl get pods -w

# Deploy the Task API
kubectl apply -f k8s/local/api-deployment.yaml

# Deploy monitoring stack
kubectl apply -f k8s/local/monitoring.yaml

# Check all pods are running
kubectl get pods

# Check services
kubectl get services
```

### Step 6: Test Your Kubernetes Deployment

```bash
# Access the API (NodePort 30000)
curl http://localhost:30000/health

# Create a task
curl -X POST http://localhost:30000/tasks \
  -H "Content-Type: application/json" \
  -d '{"title":"Running in Kubernetes","description":"This is awesome!"}'

# Get all tasks
curl http://localhost:30000/tasks

# Get specific task (use ID from previous response)
curl http://localhost:30000/tasks/YOUR_TASK_ID

# Update task
curl -X PUT http://localhost:30000/tasks/YOUR_TASK_ID \
  -H "Content-Type: application/json" \
  -d '{"status":"completed"}'

# Delete task
curl -X DELETE http://localhost:30000/tasks/YOUR_TASK_ID
```

### Step 7: Access Monitoring Tools

```bash
# Prometheus: http://localhost:30001
# - Check targets: Status → Targets
# - Query metrics: flask_http_request_total

# Grafana: http://localhost:30002
# - Login: admin / admin
# - Add Prometheus data source: http://prometheus:9090
# - Create dashboard with API metrics
```

### Step 8: Test Auto-Scaling

```bash
# Generate load (install Apache Bench)
# On Mac: brew install httpd
# On Ubuntu: sudo apt-get install apache2-utils

ab -n 10000 -c 100 http://localhost:30000/tasks

# Watch pods scale up
kubectl get hpa -w
kubectl get pods -w

# You should see pods scale from 2 to 3-5 based on load
```

### Step 9: View Logs and Debug

```bash
# Get pod names
kubectl get pods

# View API logs
kubectl logs -f deployment/task-api

# View Prometheus logs
kubectl logs -f deployment/prometheus

# Describe pod for troubleshooting
kubectl describe pod POD_NAME

# Execute commands in pod
kubectl exec -it POD_NAME -- /bin/sh
```

### Step 10: Clean Up Local Deployment

```bash
# Delete all resources
kubectl delete -f k8s/local/

# Or delete specific resources
kubectl delete deployment task-api
kubectl delete service task-api
kubectl delete hpa task-api-hpa

# Verify cleanup
kubectl get all
```

✅ **Day 1-2 Complete!** You have:
- ✅ Working API in Docker
- ✅ API running in Kubernetes
- ✅ Auto-scaling configured
- ✅ Prometheus metrics
- ✅ Grafana dashboards

---

## ☁️ AWS EKS Deployment (Day 3)

### Prerequisites

```bash
# Install AWS CLI
# Mac: brew install awscli
# Ubuntu: sudo apt-get install awscli

# Configure AWS credentials
aws configure
# Enter your AWS Access Key ID
# Enter your AWS Secret Access Key
# Region: us-east-1 (or your preferred region)

# Install eksctl (optional but recommended)
# Mac: brew install eksctl
# Linux: 
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin

# Install Terraform
# Mac: brew install terraform
# Linux: https://www.terraform.io/downloads
```

### AWS Deployment Steps

**IMPORTANT**: AWS EKS costs approximately $72/month for the control plane alone. Plan to:
1. Deploy and test everything
2. Take screenshots/videos for portfolio
3. Tear down within 1 week to minimize costs (~$20 total)

```bash
# Navigate to terraform directory
cd terraform/

# Review the terraform files
# - main.tf: EKS cluster, VPC, networking
# - dynamodb.tf: DynamoDB table
# - variables.tf: Configurable values
# - outputs.tf: Important values after deployment

# Initialize Terraform
terraform init

# Review what will be created
terraform plan

# Create the infrastructure (takes 15-20 minutes)
terraform apply -auto-approve

# Save the outputs
terraform output -json > ../aws-outputs.json

# Configure kubectl to use EKS
aws eks update-kubeconfig --region us-east-1 --name task-api-cluster

# Verify connection
kubectl get nodes
```

### Deploy Application to EKS

```bash
# Build and push image to ECR
cd ..

# Get ECR login token
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com

# Build and tag image
docker build -t task-api:latest .
docker tag task-api:latest YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/task-api:latest

# Push to ECR
docker push YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/task-api:latest

# Update k8s/aws/api-deployment.yaml with your ECR image URL
# Then deploy
kubectl apply -f k8s/aws/

# Wait for load balancer
kubectl get svc task-api-service -w

# Get the Load Balancer URL
kubectl get svc task-api-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

### Connect to Grafana Cloud

```bash
# In k8s/aws/monitoring.yaml, add your Grafana Cloud config
# Get credentials from grafana.com

# Deploy monitoring
kubectl apply -f k8s/aws/monitoring.yaml

# Prometheus will automatically send metrics to Grafana Cloud
```

### Test AWS Deployment

```bash
# Get Load Balancer URL
LB_URL=$(kubectl get svc task-api-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# Test API
curl http://$LB_URL/health

# Create task
curl -X POST http://$LB_URL/tasks \
  -H "Content-Type: application/json" \
  -d '{"title":"Running on AWS EKS!","description":"Production-ready deployment"}'

# Check Grafana Cloud for metrics
```

### Take Screenshots for Portfolio

1. AWS Console showing EKS cluster
2. kubectl get all output
3. Application Load Balancer in AWS console
4. DynamoDB table with data
5. Grafana Cloud dashboards with metrics
6. CloudWatch logs
7. Your terminal showing successful deployments

### Clean Up AWS Resources (IMPORTANT!)

```bash
# Delete Kubernetes resources first
kubectl delete -f k8s/aws/

# Wait for load balancer to be deleted (check AWS console)

# Destroy Terraform infrastructure
cd terraform/
terraform destroy -auto-approve

# Verify everything is deleted in AWS Console:
# - EKS cluster
# - Load Balancers
# - NAT Gateways
# - Elastic IPs
# - DynamoDB table (if you don't want to keep it)
```

---

## 📊 API Endpoints

### Health Check
```bash
GET /health
```

### Tasks

#### List all tasks
```bash
GET /tasks
```

#### Get specific task
```bash
GET /tasks/{task_id}
```

#### Create task
```bash
POST /tasks
Content-Type: application/json

{
  "title": "Task title",
  "description": "Task description",
  "status": "pending"
}
```

#### Update task
```bash
PUT /tasks/{task_id}
Content-Type: application/json

{
  "title": "Updated title",
  "status": "completed"
}
```

#### Delete task
```bash
DELETE /tasks/{task_id}
```

### Metrics
```bash
GET /metrics
# Returns Prometheus metrics
```

---

## 🔧 Troubleshooting

### Common Issues

**Pods not starting:**
```bash
kubectl describe pod POD_NAME
kubectl logs POD_NAME
```

**Can't connect to API:**
```bash
# Check if service is running
kubectl get svc

# Check if pods are ready
kubectl get pods

# Port forward for testing
kubectl port-forward svc/task-api 5000:5000
```

**DynamoDB connection issues:**
```bash
# Check DynamoDB pod
kubectl logs deployment/dynamodb-local

# Test connectivity from API pod
kubectl exec -it POD_NAME -- wget -O- http://dynamodb-local:8000
```

**Metrics not showing:**
```bash
# Check Prometheus targets
# Go to http://localhost:30001/targets
# task-api should be "UP"

# Test metrics endpoint
curl http://localhost:30000/metrics
```

---

## 📚 Learning Resources

- [Kubernetes Official Docs](https://kubernetes.io/docs/)
- [AWS EKS Workshop](https://www.eksworkshop.com/)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Tutorials](https://grafana.com/tutorials/)
- [DynamoDB Guide](https://docs.aws.amazon.com/dynamodb/)

---

## 🎓 What You've Learned

After completing this project, you can confidently discuss:

- ✅ Containerizing Python applications with Docker
- ✅ Kubernetes deployments, services, and config
- ✅ Horizontal Pod Autoscaling
- ✅ Resource limits and requests
- ✅ Liveness and readiness probes
- ✅ DynamoDB integration (local and AWS)
- ✅ Prometheus metrics and monitoring
- ✅ Grafana dashboards
- ✅ AWS EKS cluster management
- ✅ Infrastructure as Code with Terraform
- ✅ Container registries (ECR)
- ✅ Application Load Balancers
- ✅ CloudWatch integration

---

## 🚀 Next Steps

1. **Add CI/CD**: Implement GitHub Actions for automated deployments
2. **Add Ingress**: Set up Ingress controller for better routing
3. **Add Authentication**: Implement JWT or OAuth
4. **Add Tests**: Unit tests and integration tests
5. **Add Helm Charts**: Package for easier deployment
6. **Add Service Mesh**: Try Istio or Linkerd
7. **Multi-region**: Deploy to multiple AWS regions

---

## 📝 License

MIT License - Feel free to use this for learning and portfolio purposes.

---

## 🤝 Contributing

This is a learning project. Feel free to fork and modify!

---

## 📧 Contact

Built by [Your Name] as part of SRE/DevOps transition journey.

- GitHub: [your-github]
- LinkedIn: [your-linkedin]
- Portfolio: [your-portfolio]

---

**⭐ If this helped you, please star the repo!**
