#!/usr/bin/env bash
# This script builds a Docker image for the hello-world application and pushes it to Google Artifact Registry (GAR).
# If the Artifact Registry repo does not exist, it will be created automatically.
# It builds a multi-arch image (linux/amd64 and linux/arm64).

# Required inputs
PROJECT_ID="gke-cluster-458701"
REPO_NAME="hello-world-repo"
IMAGE_NAME="hello-world"
IMAGE_TAG="1.2.2"
LOCATION="us"

cd ../kube/ || exit 1

# Check for required tools
for cmd in docker gcloud; do
  if ! command -v "$cmd" &> /dev/null; then
    echo "❌ $cmd is not installed. Please install it to proceed."
    exit 1
  fi
done

if ! docker buildx version &> /dev/null; then
  echo "❌ Docker Buildx is not installed. Please install Docker Buildx to proceed."
  exit 1
fi

# Ensure a multi-platform capable buildx builder is active
if ! docker buildx inspect mybuilder &>/dev/null; then
  echo "🔧 Creating multi-platform builder..."
  docker buildx create --use --name mybuilder
  docker buildx inspect mybuilder --bootstrap
else
  echo "✅ Using existing multi-platform builder: mybuilder"
fi

# Full image path for GAR
IMAGE_PATH="${LOCATION}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}/${IMAGE_NAME}"

# Ensure the GAR repo exists, otherwise create it
echo "🔍 Checking if Artifact Registry repo ${REPO_NAME} exists..."
if ! gcloud artifacts repositories describe "${REPO_NAME}" \
  --project "${PROJECT_ID}" \
  --location "${LOCATION}" &>/dev/null; then
  echo "⚠️  Repo ${REPO_NAME} not found. Creating..."
  if ! gcloud artifacts repositories create "${REPO_NAME}" \
    --repository-format=docker \
    --location="${LOCATION}" \
    --project "${PROJECT_ID}" \
    --description="Docker repository for ${PROJECT_ID}"; then
    echo "❌ Failed to create Artifact Registry repo."
    exit 1
  fi
  echo "✅ Repo ${REPO_NAME} created."
else
  echo "✅ Repo ${REPO_NAME} already exists."
fi

# Ensure Docker is authenticated with GAR
gcloud auth configure-docker "${LOCATION}-docker.pkg.dev" -q

# Check if the image with the given tag exists
echo "🔍 Checking if ${IMAGE_PATH}:${IMAGE_TAG} exists in Artifact Registry..."
TAG_FOUND=$(gcloud artifacts docker images list "${IMAGE_PATH}" \
  --include-tags \
  --filter="tags=${IMAGE_TAG}" \
  --format="value(tags)" \
  --project "${PROJECT_ID}" 2>/dev/null)

if [[ -n "$TAG_FOUND" ]]; then
  echo "✅ Image ${IMAGE_PATH}:${IMAGE_TAG} already exists in Artifact Registry."
  exit 0
else
  echo "❌ Image ${IMAGE_PATH}:${IMAGE_TAG} not found. Building and pushing..."
  if ! docker buildx build \
    --platform linux/amd64,linux/arm64 \
    -t "${IMAGE_PATH}:${IMAGE_TAG}" \
    --push .; then
    echo "❌ Docker build failed."
    exit 1
  else
    echo "✅ Successfully built and pushed multi-arch ${IMAGE_PATH}:${IMAGE_TAG}."
    exit 0
  fi
fi
