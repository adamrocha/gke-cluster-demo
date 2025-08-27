#!/usr/bin/env bash
# Build and push hello-world Docker image to Google Artifact Registry (GAR)
# Supports multi-platform builds, auto-creates repo, installs/updates docker-credential-gcr,
# and checks image existence using docker pull (works for multi-arch)

set -euo pipefail

# ------------------------------------------------------------
# Config
# ------------------------------------------------------------
PROJECT_ID="gke-cluster-458701"
REGION="us"
REPO="hello-world-repo"
IMAGE_NAME="hello-world"
IMAGE_TAG="1.2.2"
PLATFORMS="linux/amd64,linux/arm64"
# PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
# export PROJECT_ROOT

cd "${PROJECT_ROOT}/kube/" || exit 1

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
if ! docker buildx inspect multiarch >/dev/null 2>&1; then
  docker buildx create --name multiarch --use
else
  docker buildx use multiarch
fi

# ------------------------------------------------------------
# Ensure docker credential helper
# ------------------------------------------------------------
if ! command -v docker-credential-gcr &> /dev/null; then
  echo "🔧 Installing docker-credential-gcr..."
  sudo apt-get update -qq
  sudo apt-get install -y google-cloud-cli-docker-credential-gcr
fi

echo "🔑 Configuring docker credential helper for GAR..."
gcloud auth configure-docker "${REGION}-docker.pkg.dev" --quiet

# ------------------------------------------------------------
# Ensure repo exists
# ------------------------------------------------------------
if ! gcloud artifacts repositories describe "$REPO" \
  --location="$REGION" --project="$PROJECT_ID" >/dev/null 2>&1; then
  echo "📦 Creating Artifact Registry repo: $REPO..."
  gcloud artifacts repositories create "$REPO" \
    --repository-format=docker \
    --location="$REGION" \
    --project="$PROJECT_ID"
else
  echo "✅ Artifact Registry repo $REPO exists."
fi

# ------------------------------------------------------------
# Image path
# ------------------------------------------------------------
IMAGE_PATH="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO}/${IMAGE_NAME}"
IMAGE_FULL="${IMAGE_PATH}:${IMAGE_TAG}"

# ------------------------------------------------------------
# Check if image tag exists using docker pull (multi-arch safe)
# ------------------------------------------------------------
if docker pull "$IMAGE_FULL" &>/dev/null; then
  echo "✅ Image $IMAGE_FULL already exists in Artifact Registry."
  exit 0
else
  echo "❌ Image $IMAGE_FULL not found. Building and pushing..."
fi

# ------------------------------------------------------------
# Build + Push
# ------------------------------------------------------------
if ! docker buildx build \
  --platform "$PLATFORMS" \
  -t "$IMAGE_FULL" \
  --push .; then
  echo "❌ Docker build failed."
  exit 1
else
  echo "✅ Successfully built and pushed $IMAGE_FULL."
  exit 0
fi
