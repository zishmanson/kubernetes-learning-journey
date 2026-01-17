# 🚀 QUICK START GUIDE - 2-3 Day Sprint

This guide will get you from zero to a production-ready Kubernetes application in 2-3 days.

## 📅 Day 1: Local Development (4-6 hours)

### Morning (2-3 hours): Setup & Docker

1. **Clone and setup**
   ```bash
   cd task-api-k8s
   ```

2. **Test with Docker Compose**
   ```bash
   docker-compose up --build
   
   # In another terminal
   curl http://localhost:5000/health
   curl -X POST http://localhost:5000/tasks \
     -H "Content-Type: application/json" \
     -d '{"title":"First task","description":"Testing API"}'
   curl http://localhost:5000/tasks
   
   # Stop
   docker-compose down
   ```
   
   ✅ **Checkpoint**: API works with Docker!

### Afternoon (2-3 hours): Local Kubernetes

3. **Enable Kubernetes in Docker Desktop**
   - Docker Desktop → Settings → Kubernetes → Enable
   - Wait 2-3 minutes
   
   ```bash
   kubectl version
   ```

4. **Build image for Kubernetes**
   ```bash
   docker build -t task-api:latest .
   ```

5. **Deploy to local Kubernetes**
   ```bash
   kubectl apply -f k8s/local/dynamodb-deployment.yaml
   kubectl apply -f k8s/local/api-deployment.yaml
   kubectl apply -f k8s/local/monitoring.yaml
   
   # Wait for pods
   kubectl get pods -w
   ```

6. **Test Kubernetes deployment**
   ```bash
   # API
   curl http://localhost:30000/health
   curl -X POST http://localhost:30000/tasks \
     -H "Content-Type: application/json" \
     -d '{"title":"In Kubernetes!","description":"Auto-scaling ready"}'
   
   # Prometheus
   open http://localhost:30001
   
   # Grafana (admin/admin)
   open http://localhost:30002
   ```

7. **Configure Grafana**
   - Login: admin/admin
   - Add Data Source → Prometheus
   - URL: http://prometheus:9090
   - Save & Test
   - Create Dashboard
   - Add panel with query: `flask_http_request_total`

8. **Test auto-scaling**
   ```bash
   # Generate load (install ab first if needed)
   ab -n 5000 -c 50 http://localhost:30000/tasks
   
   # Watch scaling
   kubectl get hpa -w
   kubectl get pods -w
   ```

✅ **Day 1 Complete!**
- Working API
- Running in Kubernetes
- Auto-scaling
- Monitoring with Prometheus & Grafana

---

## 📅 Day 2: Git & Portfolio (2-3 hours)

### Morning: Git Setup

1. **Initialize Git**
   ```bash
   git init
   git add .
   git commit -m "Initial commit: Task API with K8s and monitoring"
   ```

2. **Create GitHub repo**
   - Go to github.com
   - Create new repository: `task-api-k8s`
   - Don't initialize with README (we have one)

3. **Push to GitHub**
   ```bash
   git remote add origin https://github.com/YOUR_USERNAME/task-api-k8s.git
   git branch -M main
   git push -u origin main
   ```

4. **Update README**
   - Replace YOUR_USERNAME with your GitHub username
   - Add your name and LinkedIn
   - Commit and push

### Afternoon: Documentation & Screenshots

5. **Take screenshots**
   - kubectl get all output
   - Prometheus metrics page
   - Grafana dashboard
   - API response in browser/Postman

6. **Create architecture diagram**
   - Use draw.io or any tool
   - Show: API → DynamoDB → Prometheus → Grafana
   - Save as `architecture.png`
   - Add to repo

7. **Update LinkedIn**
   - Add project to LinkedIn
   - Post about what you built
   - Link to GitHub repo

✅ **Day 2 Complete!**
- Code on GitHub
- Professional documentation
- Ready to show recruiters

---

## 📅 Day 3: AWS Deployment (6-8 hours)

### Prerequisites Check

```bash
# Install AWS CLI (if not installed)
# Mac: brew install awscli
# Ubuntu: sudo apt-get install awscli

# Install Terraform
# Mac: brew install terraform
# Ubuntu: snap install terraform

# Configure AWS
aws configure
# Enter Access Key, Secret Key, Region (us-east-1)
```

### Deploy to AWS EKS

1. **Automated deployment**
   ```bash
   ./scripts/deploy-aws.sh
   ```
   
   This script will:
   - Create EKS cluster (15-20 minutes)
   - Create DynamoDB table
   - Build & push Docker image to ECR
   - Deploy to Kubernetes
   - Provision Load Balancer
   
   ⏰ **Grab coffee - this takes 20-30 minutes**

2. **Test AWS deployment**
   ```bash
   # Get Load Balancer URL
   kubectl get svc task-api-service
   
   # Test API
   LB_URL=<your-lb-url>
   curl http://$LB_URL/health
   curl -X POST http://$LB_URL/tasks \
     -H "Content-Type: application/json" \
     -d '{"title":"Running on AWS!","description":"Production ready"}'
   ```

3. **Configure Grafana Cloud** (if you have account)
   - Edit k8s/aws/monitoring.yaml with your Grafana Cloud config
   - Apply: `kubectl apply -f k8s/aws/monitoring.yaml`

4. **Take Portfolio Screenshots**
   - AWS Console → EKS cluster
   - AWS Console → DynamoDB tables
   - AWS Console → Load Balancers
   - kubectl get all
   - Working API calls
   - Grafana dashboards (if configured)
   - Save all screenshots!

5. **Load Testing**
   ```bash
   # Test auto-scaling on AWS
   ab -n 10000 -c 100 http://$LB_URL/tasks
   
   # Watch pods scale
   kubectl get hpa -w
   ```

6. **Clean Up** (IMPORTANT!)
   ```bash
   ./scripts/cleanup-aws.sh
   ```
   
   ⚠️ **Do this within 1 week to minimize costs (~$20)**
   
   The script will:
   - Delete Kubernetes resources
   - Delete Load Balancer
   - Destroy EKS cluster
   - Remove all AWS infrastructure

✅ **Day 3 Complete!**
- Real AWS EKS experience
- Portfolio screenshots
- $20 well spent on learning

---

## 🎯 What You've Achieved

After 2-3 days, you have:

✅ **Technical Skills**
- Docker containerization
- Kubernetes deployment & management
- DynamoDB integration
- Prometheus monitoring
- Grafana dashboards
- Horizontal Pod Autoscaling
- AWS EKS deployment
- Terraform infrastructure as code
- Load balancer configuration

✅ **Portfolio**
- Professional GitHub repo
- Working code with documentation
- Architecture diagrams
- Screenshots of live deployment
- Evidence of cloud deployment

✅ **Interview Ready**
You can now confidently say:
> "I built a production-ready REST API deployed to AWS EKS with auto-scaling, monitoring via Prometheus and Grafana, and infrastructure managed with Terraform. Here's my GitHub repo with full documentation."

---

## 💰 Cost Summary

**Local Development**: $0
**AWS Deployment (1 week)**: ~$20-30
**Total Investment**: ~$25

This is **excellent ROI** for real cloud-native experience!

---

## 🎤 Interview Talking Points

When discussing this project in interviews:

1. **Problem Solving**
   - "I wanted to transition to SRE so I built a production-grade application"
   - "Implemented observability from day one with Prometheus and Grafana"

2. **Cloud Native**
   - "Deployed to AWS EKS with proper IAM roles and DynamoDB integration"
   - "Used Terraform for infrastructure as code"

3. **Scalability**
   - "Implemented horizontal pod autoscaling based on CPU and memory"
   - "Tested under load and watched it scale from 2 to 5 pods automatically"

4. **Monitoring**
   - "Added Prometheus metrics to track requests, latency, and errors"
   - "Built Grafana dashboards to visualize application health"

5. **Best Practices**
   - "Implemented health checks, resource limits, and proper logging"
   - "Used Docker for consistent environments from dev to production"

---

## 📚 Next Steps

After completing this project, consider:

1. **Add CI/CD**
   - GitHub Actions to auto-deploy on push
   - Automated testing

2. **Add Security**
   - JWT authentication
   - SSL/TLS certificates
   - Secrets management with AWS Secrets Manager

3. **Add More Features**
   - User authentication
   - Task assignments
   - Notifications

4. **Try Another Project**
   - Different tech stack (Node.js, Go)
   - Different database (PostgreSQL, MongoDB)
   - Different cloud (GCP, Azure)

---

## 🆘 Need Help?

If you get stuck:
1. Check the detailed README.md
2. Review logs: `kubectl logs deployment/task-api`
3. Check pod status: `kubectl describe pod <pod-name>`
4. Google the error message
5. Ask on Reddit r/devops or r/kubernetes

---

**You've got this! 🚀**

Remember: Thousands of people have made this transition successfully. You're building real skills that companies need right now.
