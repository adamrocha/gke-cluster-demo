#!/usr/bin/env bash
# This script updates the kubeconfig file to access the GKE cluster.

PROJECT_ID="gke-cluster-458701"
REGION="us-central1"

gcloud container clusters get-credentials demo-cluster \
  --region "$REGION" \
  --project "$PROJECT_ID"