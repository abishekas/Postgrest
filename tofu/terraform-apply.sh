#!/bin/bash

set -e

echo "Creating cluster and database..."

cd cluster
terraform init
terraform apply -auto-approve

echo "Waiting for Kubernetes API..."

until kubectl get nodes >/dev/null 2>&1
do
  sleep 2
done

echo "Deploying Kubernetes resources..."

cd ../k8s-secret
terraform init
terraform apply -auto-approve

echo "Waiting 15 seconds before deploying PostgREST..."
sleep 15

echo "Running PostgREST deployment script..."

cd ../../postgrest
sh postgrest.sh

echo "Deployment complete."
