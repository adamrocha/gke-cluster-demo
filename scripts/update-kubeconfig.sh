#!/usr/bin/env bash
# This script updates the kubeconfig file to access the GKE cluster.

PROJECT_ID="gke-cluster-458701"
REGION="us-central1"
CLUSTER_NAME="gke-cluster-demo"

gcloud container clusters get-credentials "$CLUSTER_NAME" \
  --region "$REGION" \
  --project "$PROJECT_ID"