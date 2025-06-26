# Weather App EKS Deployment

This repository contains Terraform configuration to deploy the Weather App to AWS EKS.

## Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform >= 1.0
- Docker
- kubectl

## Quick Start

1. **Configure variables** (optional):
   ```bash
   cp terraform/terraform.tfvars.example terraform/terraform.tfvars
   # Edit terraform.tfvars with your preferred settings
   ```

2. **Deploy everything**:
   ```bash
   chmod +x deploy.sh
   ./deploy.sh
   ```

## Manual Deployment Steps

### 1. Deploy Infrastructure

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### 2. Build and Push Docker Image

```bash
# Get ECR repository URL
ECR_REPO=$(cd terraform && terraform output -raw ecr_repository_url)

# Build and tag image
docker build -t weather-app:latest .
docker tag weather-app:latest $ECR_REPO:latest

# Login to ECR and push
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin $ECR_REPO
docker push $ECR_REPO:latest
```

### 3. Configure kubectl

```bash
CLUSTER_NAME=$(cd terraform && terraform output -raw cluster_name)
aws eks --region us-west-2 update-kubeconfig --name $CLUSTER_NAME
```

### 4. Install AWS Load Balancer Controller

```bash
kubectl apply -f https://github.com/kubernetes-sigs/aws-load-balancer-controller/releases/download/v2.7.2/v2_7_2_full.yaml
```

## Accessing the Application

After deployment, get the application URL:

```bash
kubectl get ingress -n weather-app
```

## Monitoring

Check deployment status:

```bash
kubectl get pods -n weather-app
kubectl get services -n weather-app
kubectl logs -f deployment/weather-app -n weather-app
```

## Cleanup

To destroy all resources:

```bash
cd terraform
terraform destroy
```

## Architecture

- **EKS Cluster**: Managed Kubernetes cluster
- **ECR Repository**: Container registry for Docker images  
- **VPC**: Dedicated network with public/private subnets
- **Application Load Balancer**: Internet-facing load balancer
- **Auto Scaling**: Node group with 1-4 instances

## Configuration

Key variables in `terraform/variables.tf`:

- `aws_region`: AWS region (default: us-west-2)
- `cluster_version`: Kubernetes version (default: 1.28)
- `node_instance_type`: EC2 instance type (default: t3.medium)
- `desired_capacity`: Number of worker nodes (default: 2)