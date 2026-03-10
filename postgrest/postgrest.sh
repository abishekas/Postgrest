#!/bin/bash

kubectl apply -f job.yaml
sleep 10
kubectl apply -f deployment.yaml
kubectl apply -f ingress.yaml
