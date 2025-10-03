#!/usr/bin/env bash
# Build and push hello-world Docker image to Google Artifact Registry (GAR)
# Supports multi-platform builds, auto-creates repo, installs/updates docker-credential-gcr

set -euo pipefail

# ------------------------------------------------------------
# Config
# ------------------------------------------------------------
PROJECT_ID="gke-cluster-458701"
REGION="us-central1"
REPO_NAME="hello-world-repo"
IMAGE_NAME="hello-world"
IMAGE_TAG="1.2.2"
PLATFORMS="linux/amd64,linux/arm64"

export PROJECT_ROOT="${PROJECT_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"

cd "${PROJECT_ROOT}/kube/" || exit 1

# ------------------------------------------------------------
# Ensure repo exists
# ------------------------------------------------------------
if ! gcloud artifacts repositories describe "$REPO_NAME" \
    --location="$REGION" \
    --project="$PROJECT_ID" >/dev/null 2>&1; then
  echo "📦 Creating Artifact Registry repo: $REPO_NAME..."
  gcloud artifacts repositories create "$REPO_NAME" \
    --location="$REGION" \
    --project="$PROJECT_ID" \
    --repository-format=docker \
    --description="Docker repository for $IMAGE_NAME"
  echo "✅ Artifact Registry repo $REPO_NAME created."
else
  echo "✅ Artifact Registry repo $REPO_NAME already exists."
fi

# ------------------------------------------------------------
# Image path
# ------------------------------------------------------------
IMAGE_PATH="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}/${IMAGE_NAME}:${IMAGE_TAG}"

# ------------------------------------------------------------
# Check if image tag exists in Artifact Registry using gcloud
# ------------------------------------------------------------
echo "🔎 Checking Artifact Registry for $IMAGE_PATH (gcloud)..."
if gcloud artifacts docker images describe "$IMAGE_PATH" >/dev/null 2>&1; then
  echo "✅ Image $IMAGE_PATH already exists in Artifact Registry."
  exit 0
else
  echo "ℹ️  Image not found in Artifact Registry via gcloud. Will build and push using Docker..."
fi

# ------------------------------------------------------------
# Ensure docker credential helper
# ------------------------------------------------------------
echo "🔑 Configuring docker credential helper for GAR..."
if ! command -v docker-credential-gcr >/dev/null 2>&1; then
  gcloud components install docker-credential-gcr --quiet
fi

gcloud auth configure-docker "${REGION}-docker.pkg.dev" --quiet

# ------------------------------------------------------------
# Verify Docker + Buildx
# ------------------------------------------------------------
if ! command -v docker &> /dev/null; then
  echo "❌ Docker not installed."
  exit 1
fi
if ! docker buildx version &> /dev/null; then
  echo "❌ Docker Buildx not installed."
  exit 1
fi

# Ensure buildx builder exists
if ! docker buildx inspect mybuilder >/dev/null 2>&1; then
  docker buildx create --name mybuilder --driver docker-container --use
else
  docker buildx use mybuilder
fi

# ------------------------------------------------------------
# Build + Push
# ------------------------------------------------------------
if ! docker buildx build \
  --platform "$PLATFORMS" \
  -t "$IMAGE_PATH" \
  --push .; then
  echo "❌ Docker build failed."
  exit 1
else
  echo "✅ Successfully built and pushed $IMAGE_PATH to Artifact Registry."
  exit 0
fi
