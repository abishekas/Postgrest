#!/bin/bash

set -e

echo "Destroying Kubernetes resources..."

cd k8s-secret
terraform destroy -auto-approve

echo "Destroying cluster and database..."

cd ../cluster
terraform destroy -auto-approve

echo "Destroy complete."
