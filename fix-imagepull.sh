#!/bin/bash

echo "🔧 Fixing ImagePullBackOff error..."

# Apply the updated Terraform configuration
cd terraform
terraform apply -auto-approve

# Restart the deployment to pick up new permissions
kubectl rollout restart deployment/weather-app -n weather-app

# Wait for rollout to complete
kubectl rollout status deployment/weather-app -n weather-app

echo "✅ Fix applied. Check pod status:"
kubectl get pods -n weather-app