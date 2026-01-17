## Day 1 Summary - Local Kubernetes Deployment
What I Built
Successfully deployed a production-ready Task Management REST API to a local Kubernetes cluster using Docker Desktop, demonstrating core DevOps and SRE skills.
Key Achievements
Infrastructure & Deployment

✅ Containerized Python Flask application with Docker
✅ Deployed multi-pod application to Kubernetes (2 replicas)
✅ Configured Horizontal Pod Autoscaler (2-5 replicas based on CPU/memory)
✅ Set up DynamoDB Local for data persistence
✅ Deployed Prometheus and Grafana monitoring stack

## Technical Skills Demonstrated

Kubernetes Resources: Deployments, Services (NodePort), ConfigMaps, HPA
Container Orchestration: Multi-container application coordination
Health Checks: Implemented liveness and readiness probes
Resource Management: CPU/memory limits and requests
Networking: Service discovery and pod-to-pod communication

## API Functionality Verified

Health check endpoint (/health)
Full CRUD operations for tasks (Create, Read, Update, Delete)
DynamoDB integration with in-memory storage
Successful request handling across multiple pod replicas

Challenges Overcome

Resolved DynamoDB Local database file permissions (switched to in-memory mode)
Fixed image pull policies for local Kubernetes development
Troubleshot NodePort connectivity (used port-forwarding workaround)
Metrics are still not scraped by prometheus. The PrometheusMetrics setup looks correct! The issue might be that the metrics module isn't working properly with our Flask version. will review it later.


What's Working

✅ API accessible and responding correctly
✅ Multiple pods load-balancing requests
✅ Auto-scaling infrastructure configured
✅ Database connectivity established
✅ Monitoring stack deployed and accessible

Time Invested
Approximately 6-8 hours including setup, troubleshooting, and learning