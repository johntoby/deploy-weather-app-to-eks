#!/bin/bash

# Weather App EKS Deployment Script

set -e

echo "🚀 Starting Weather App deployment to EKS..."

# Variables
AWS_REGION=${AWS_REGION:-us-west-2}
IMAGE_TAG=${IMAGE_TAG:-latest}

# Get AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo "📋 Using AWS Account: $AWS_ACCOUNT_ID"
echo "📋 Using AWS Region: $AWS_REGION"

# Initialize and apply Terraform
echo "🏗️  Initializing Terraform..."
cd terraform
terraform init

echo "🏗️  Planning Terraform deployment..."
terraform plan

echo "🏗️  Applying Terraform configuration..."
terraform apply -auto-approve

# Get ECR repository URL
ECR_REPO=$(terraform output -raw ecr_repository_url)
CLUSTER_NAME=$(terraform output -raw cluster_name)

echo "📦 ECR Repository: $ECR_REPO"
echo "🎯 EKS Cluster: $CLUSTER_NAME"

# Build and push Docker image
echo "🐳 Building Docker image..."
cd ..
docker build -t weather-app:$IMAGE_TAG .

echo "🐳 Tagging image for ECR..."
docker tag weather-app:$IMAGE_TAG $ECR_REPO:$IMAGE_TAG

echo "🔐 Logging into ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPO

echo "📤 Pushing image to ECR..."
docker push $ECR_REPO:$IMAGE_TAG

# Configure kubectl
echo "⚙️  Configuring kubectl..."
aws eks --region $AWS_REGION update-kubeconfig --name $CLUSTER_NAME

# Install AWS Load Balancer Controller
echo "🔧 Installing AWS Load Balancer Controller..."
kubectl apply -f https://github.com/kubernetes-sigs/aws-load-balancer-controller/releases/download/v2.7.2/v2_7_2_full.yaml

# Wait for deployment
echo "⏳ Waiting for deployment to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/weather-app -n weather-app

# Get service URL
echo "🌐 Getting service information..."
kubectl get ingress -n weather-app

echo "✅ Deployment completed successfully!"
echo "📝 Run 'kubectl get pods -n weather-app' to check pod status"
echo "📝 Run 'kubectl get ingress -n weather-app' to get the application URL"