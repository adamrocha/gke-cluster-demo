#!/usr/bin/env bash
# This script fetches credentials for a Google Cloud project and sets up Docker authentication for Google Container Registry (GCR).

gcloud container clusters get-credentials demo-cluster \
  --region=us-central1 \
  --project=gke-cluster-458701