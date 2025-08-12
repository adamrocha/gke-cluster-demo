#!/usr/bin/env bash
# This script builds a Docker image for the hello-world application and pushes it to Google Container Registry (GCR).

# Required inputs
PROJECT_ID="gke-cluster-458701"
IMAGE_NAME="hello-world"
IMAGE_TAG="1.2.2"
PLATFORM_ARCH="linux/amd64"

cd ../kube/ || exit 1

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
  echo "❌ Docker is not installed. Please install Docker to proceed."
  exit 1
fi

# Check if Docker Buildx is installed
if ! docker buildx version &> /dev/null; then
  echo "❌ Docker Buildx is not installed. Please install Docker Buildx to proceed."
  exit 1
fi

# Full image path
IMAGE_PATH="gcr.io/${PROJECT_ID}/${IMAGE_NAME}"

# Check if the image with the given tag exists
TAG_FOUND=$(gcloud container images list-tags "$IMAGE_PATH" \
  --filter="tags:${IMAGE_TAG}" \
  --format="get(tags)" 2>/dev/null)

if [[ "$TAG_FOUND" == *"$IMAGE_TAG"* ]]; then
  echo "✅ Image ${IMAGE_PATH}:${IMAGE_TAG} exists."
  exit 0
else
  echo "❌ Image ${IMAGE_PATH}:${IMAGE_TAG} not found. Building and pushing..."

  # Build the Docker image
  if ! docker buildx build \
    --platform ${PLATFORM_ARCH} \
    -t "${IMAGE_PATH}:${IMAGE_TAG}" \
    --push .; then
    echo "❌ Docker build failed."
    exit 1
  else
    echo "✅ Successfully built ${IMAGE_PATH}:${IMAGE_TAG}."
  fi

  # Push the Docker image to GAR
  if ! docker push "${IMAGE_PATH}:${IMAGE_TAG}"; then
    echo "❌ Failed to push image to GAR."
    exit 1
  else
    echo "✅ Successfully pushed ${IMAGE_PATH}:${IMAGE_TAG} to GAR."
    exit 0
  fi
fi