#!/usr/bin/env bash
# Update Kubernetes manifest image tag

set -euo pipefail

REPO_NAME="${1:-hello-world-repo}"
IMAGE_TAG="${2:-latest}"
VARIANT="${3:-}"  # Optional: "blue", "green", or empty for regular deployment

PROJECT_ID="${GCP_PROJECT:-gke-cluster-458701}"
REGION="${LOCATION:-us-central1}"

IMAGE_PATH="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}/hello-world:${IMAGE_TAG}"

if [ -n "$VARIANT" ]; then
    MANIFEST_FILE="manifests/blue-green/hello-world-deployment-${VARIANT}.yaml"
else
    MANIFEST_FILE="manifests/hello-world-deployment.yaml"
fi

if [ ! -f "$MANIFEST_FILE" ]; then
    echo "❌ Manifest file not found: $MANIFEST_FILE"
    exit 1
fi

echo "📝 Updating manifest: $MANIFEST_FILE"
echo "🖼️  New image: $IMAGE_PATH"

# Use sed to update the image line (works on both macOS and Linux)
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i '' "s|image: .*-docker.pkg.dev/.*/hello-world:.*|image: $IMAGE_PATH|" "$MANIFEST_FILE"
else
    # Linux
    sed -i "s|image: .*-docker.pkg.dev/.*/hello-world:.*|image: $IMAGE_PATH|" "$MANIFEST_FILE"
fi

echo "✅ Manifest updated successfully"
echo ""
echo "To apply changes:"
echo "  kubectl apply -f $MANIFEST_FILE"
