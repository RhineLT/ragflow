#!/bin/bash
# Script to verify ARM64 RagFlow images
# Usage: ./verify-arm64-images.sh

set -e

REGISTRY="ghcr.io"
REPO="rhinelt/ragflow"

echo "======================================"
echo "ARM64 Image Verification Script"
echo "======================================"
echo ""

# Function to verify single image
verify_image() {
    local image_name=$1
    local image_tag="${REGISTRY}/${REPO}${image_name}:arm64-latest"

    echo "Verifying: ${image_tag}"
    echo "--------------------------------------"

    # Pull image
    echo "1. Pulling image..."
    if docker pull --platform linux/arm64 "${image_tag}"; then
        echo "✓ Pull successful"
    else
        echo "✗ Pull failed"
        return 1
    fi

    # Inspect architecture
    echo "2. Checking architecture..."
    ARCH=$(docker inspect "${image_tag}" | jq -r '.[0].Architecture')
    echo "   Architecture: ${ARCH}"

    if [ "${ARCH}" != "arm64" ]; then
        echo "✗ Expected arm64 but got ${ARCH}"
        return 1
    else
        echo "✓ Architecture verified as arm64"
    fi

    # Get image size
    SIZE=$(docker inspect "${image_tag}" | jq -r '.[0].Size' | numfmt --to=iec-i --suffix=B)
    echo "   Size: ${SIZE}"

    # Get creation date
    CREATED=$(docker inspect "${image_tag}" | jq -r '.[0].Created')
    echo "   Created: ${CREATED}"

    echo "✓ Image verified successfully"
    echo ""
    return 0
}

# Main verification
echo "Checking if Docker is running..."
if ! docker info > /dev/null 2>&1; then
    echo "✗ Docker is not running. Please start Docker first."
    exit 1
fi
echo "✓ Docker is running"
echo ""

echo "Checking if jq is installed..."
if ! command -v jq &> /dev/null; then
    echo "✗ jq is not installed. Please install it first:"
    echo "  - Ubuntu/Debian: sudo apt install jq"
    echo "  - macOS: brew install jq"
    exit 1
fi
echo "✓ jq is installed"
echo ""

# Verify main RagFlow image
echo "========================================"
echo "Verifying Main RagFlow Image"
echo "========================================"
echo ""
verify_image ""

# Verify sandbox images
echo "========================================"
echo "Verifying Sandbox Base Python Image"
echo "========================================"
echo ""
verify_image "-sandbox-base-python"

echo "========================================"
echo "Verifying Sandbox Base Node.js Image"
echo "========================================"
echo ""
verify_image "-sandbox-base-nodejs"

echo "========================================"
echo "Verifying Sandbox Executor Manager"
echo "========================================"
echo ""
verify_image "-sandbox-executor-manager"

echo "======================================"
echo "All images verified successfully! ✓"
echo "======================================"
echo ""
echo "Next steps:"
echo "1. Update docker/.env with: RAGFLOW_IMAGE=${REGISTRY}/${REPO}:arm64-latest"
echo "2. Run: cd docker && docker-compose --profile cpu up -d"
echo "3. Check logs: docker-compose logs -f ragflow-cpu"
