#!/bin/bash
INSTANCE_NAME="$1"
ZONE="$2"

gcloud compute ssh "$INSTANCE_NAME" \
  --zone "$ZONE" \
  --tunnel-through-iap \
  --dry-run \
  --quiet | tail -n 1
