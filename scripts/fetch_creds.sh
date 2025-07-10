#!/usr/bin/env bash
# This script fetches credentials for a Google Cloud project and sets up Docker authentication for Google Container Registry (GCR).

PROJECT_ID="gke-cluster-458701"
REGION="us-central1"

gcloud container clusters get-credentials demo-cluster \
  --region "$REGION" \
  --project "$PROJECT_ID"