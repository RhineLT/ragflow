#!/bin/bash
# Script to configure docker compose to use ARM64 images
# Usage: ./setup-arm64-compose.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_DIR="${SCRIPT_DIR}/../docker"
ENV_FILE="${DOCKER_DIR}/.env"
ENV_BACKUP="${DOCKER_DIR}/.env.backup.$(date +%Y%m%d-%H%M%S)"

REGISTRY="ghcr.io"
REPO="rhinelt/ragflow"

echo "======================================"
echo "ARM64 Docker Compose Setup"
echo "======================================"
echo ""

# Check if docker directory exists
if [ ! -d "${DOCKER_DIR}" ]; then
    echo "✗ Docker directory not found: ${DOCKER_DIR}"
    exit 1
fi

# Check if .env file exists
if [ ! -f "${ENV_FILE}" ]; then
    echo "✗ .env file not found: ${ENV_FILE}"
    echo "  Please copy .env.example to .env first"
    exit 1
fi

# Backup existing .env file
echo "Creating backup of .env file..."
cp "${ENV_FILE}" "${ENV_BACKUP}"
echo "✓ Backup created: ${ENV_BACKUP}"
echo ""

# Update RAGFLOW_IMAGE
echo "Updating RAGFLOW_IMAGE to ARM64 version..."
sed -i.tmp "s|RAGFLOW_IMAGE=.*|RAGFLOW_IMAGE=${REGISTRY}/${REPO}:arm64-latest|g" "${ENV_FILE}"
rm -f "${ENV_FILE}.tmp"
echo "✓ Updated RAGFLOW_IMAGE"
echo ""

# Update sandbox images if present
echo "Updating Sandbox images (if configured)..."
if grep -q "SANDBOX_BASE_PYTHON_IMAGE" "${ENV_FILE}"; then
    sed -i.tmp "s|SANDBOX_BASE_PYTHON_IMAGE=.*|SANDBOX_BASE_PYTHON_IMAGE=${REGISTRY}/${REPO}-sandbox-base-python:arm64-latest|g" "${ENV_FILE}"
    rm -f "${ENV_FILE}.tmp"
    echo "✓ Updated SANDBOX_BASE_PYTHON_IMAGE"
fi

if grep -q "SANDBOX_BASE_NODEJS_IMAGE" "${ENV_FILE}"; then
    sed -i.tmp "s|SANDBOX_BASE_NODEJS_IMAGE=.*|SANDBOX_BASE_NODEJS_IMAGE=${REGISTRY}/${REPO}-sandbox-base-nodejs:arm64-latest|g" "${ENV_FILE}"
    rm -f "${ENV_FILE}.tmp"
    echo "✓ Updated SANDBOX_BASE_NODEJS_IMAGE"
fi

if grep -q "SANDBOX_EXECUTOR_MANAGER_IMAGE" "${ENV_FILE}"; then
    sed -i.tmp "s|SANDBOX_EXECUTOR_MANAGER_IMAGE=.*|SANDBOX_EXECUTOR_MANAGER_IMAGE=${REGISTRY}/${REPO}-sandbox-executor-manager:arm64-latest|g" "${ENV_FILE}"
    rm -f "${ENV_FILE}.tmp"
    echo "✓ Updated SANDBOX_EXECUTOR_MANAGER_IMAGE"
fi
echo ""

# Show changes
echo "======================================"
echo "Configuration Changes"
echo "======================================"
echo ""
echo "RAGFLOW_IMAGE:"
grep "RAGFLOW_IMAGE=" "${ENV_FILE}" | head -1
echo ""

if grep -q "SANDBOX_BASE_PYTHON_IMAGE" "${ENV_FILE}"; then
    echo "Sandbox Images (if enabled):"
    grep "SANDBOX_BASE_PYTHON_IMAGE=" "${ENV_FILE}" | head -1 || true
    grep "SANDBOX_BASE_NODEJS_IMAGE=" "${ENV_FILE}" | head -1 || true
    grep "SANDBOX_EXECUTOR_MANAGER_IMAGE=" "${ENV_FILE}" | head -1 || true
    echo ""
fi

echo "======================================"
echo "Setup Complete! ✓"
echo "======================================"
echo ""
echo "Next steps:"
echo "1. Pull ARM64 images:"
echo "   docker pull --platform linux/arm64 ${REGISTRY}/${REPO}:arm64-latest"
echo ""
echo "2. Start services:"
echo "   cd ${DOCKER_DIR}"
echo "   docker compose --profile cpu up -d"
echo ""
echo "3. Check status:"
echo "   docker compose ps"
echo "   docker compose logs -f ragflow-cpu"
echo ""
echo "To restore previous configuration:"
echo "   cp ${ENV_BACKUP} ${ENV_FILE}"
