#!/bin/bash
set -e

terraform apply --auto-approve
terraform -chdir=k8s apply --auto-approve
