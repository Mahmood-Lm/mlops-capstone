# End-to-End MLOps Pipeline: AI Sentiment Analysis

## 📌 Project Overview
This project demonstrates a fully automated, production-ready MLOps pipeline and infrastructure for a Machine Learning application. It features a custom AI Sentiment Analysis API with a web frontend, deployed to a Kubernetes cluster hosted on AWS. 

The entire cloud infrastructure is provisioned using **Terraform** (Infrastructure as Code), and application updates are handled via a strict **GitOps CI/CD pipeline** using **Jenkins** and **Docker**.



## 🚀 Tech Stack & Architecture
* **Cloud Provider:** AWS (EC2, VPC, Security Groups)
* **Infrastructure as Code (IaC):** Terraform
* **CI/CD:** Jenkins (Automated via GitHub Webhooks)
* **Containerization:** Docker & Docker Hub
* **Container Orchestration:** Kubernetes (K3s)
* **Application:** Python (FastAPI/Flask), HTML, CSS, JavaScript
* **Observability:** Prometheus & Grafana

## ⚙️ CI/CD Pipeline Flow
This project implements true Continuous Deployment. Human intervention is completely removed from the release process.
1. **Code Commit:** Developer pushes Python/HTML code to the `main` branch.
2. **Webhook Trigger:** GitHub instantly fires a webhook to the Jenkins server.
3. **Build & Package:** Jenkins checks out the code and builds a new, immutable Docker image tagged with the build ID.
4. **Artifact Storage:** Jenkins authenticates and pushes the new image to Docker Hub.
5. **K8s Deployment:** Jenkins updates the Kubernetes deployment using `kubectl`, triggering a rolling update of the AI pods with zero downtime.

## 📊 Observability & Monitoring
To ensure high availability and track API usage, **Prometheus** is deployed within the Kubernetes cluster to scrape custom application metrics (e.g., `sentiment_api_requests_total`). **Grafana** is exposed via a NodePort Service to visualize these metrics in real-time, allowing for instant traffic analysis and performance monitoring.

## 🏗️ Infrastructure & Setup
The infrastructure is defined in the `terraform/` directory. 
* Uses a `c7i-flex.large` compute-optimized instance.
* Bootstraps the server automatically using `user_data` to install Docker, Jenkins, Java, and K3s on startup.
* Configures strict AWS Security Groups to allow specific ingress traffic (e.g., Ports `8080` for Jenkins, `30000` for the App, `30080` for Grafana).

## 💡 Production Readiness & Future Enhancements
While this project runs a consolidated architecture for cost-efficiency, a real-world enterprise deployment would separate these concerns:
* **Remote State:** Migrate Terraform `.tfstate` from local storage to an encrypted AWS S3 bucket with DynamoDB state locking.
* **Registry:** Transition from public Docker Hub to a private AWS ECR vault.
* **Separation of Concerns:** Move Jenkins to a dedicated CI/CD build server, isolated from the production Kubernetes (EKS) cluster to prevent resource starvation.
* **Networking:** Implement AWS Route 53 and Elastic IPs to handle ephemeral server reboots and provide clean DNS routing instead of direct IP access.
