pipeline {
    agent any

    environment {
        // Docker Hub credentials stored in Jenkins
        DOCKER_CREDS = credentials('dockerhub-credentials')
        IMAGE_NAME = "mahmooood/sentiment-api"
        IMAGE_TAG = "${env.BUILD_ID}" // Automatically uses the Jenkins build number (e.g., v1, v2)
    }

    stages {
        stage('Checkout Code') {
            steps {
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "Building the AI Sentiment API Docker Image..."
                sh "docker build -t ${IMAGE_NAME}:${IMAGE_TAG} -t ${IMAGE_NAME}:latest ."
            }
        }

        stage('Push to Docker Hub') {
            steps {
                echo "Logging into Docker Hub..."
                sh "echo \$DOCKER_CREDS_PSW | docker login -u \$DOCKER_CREDS_USR --password-stdin"
                
                echo "Pushing Image to the cloud vault..."
                sh "docker push ${IMAGE_NAME}:${IMAGE_TAG}"
                sh "docker push ${IMAGE_NAME}:latest"
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                echo "Telling Kubernetes to pull and deploy the latest AI model..."
                // K3s stores its config file here, so we tell Jenkins to use it!
                sh "KUBECONFIG=/etc/rancher/k3s/k3s.yaml kubectl apply -f k8s/"
                
                // Force Kubernetes to pull the absolute newest image we just built
                sh "KUBECONFIG=/etc/rancher/k3s/k3s.yaml kubectl rollout restart deployment/sentiment-api-deployment"
            }
        }
    }
}