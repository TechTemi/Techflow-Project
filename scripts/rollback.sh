#!/usr/bin/env bash

set -euo pipefail

IMAGE_REPO="${1:?Usage: rollback.sh IMAGE_REPO [CONTAINER_NAME] [HOST_PORT] [CONTAINER_PORT] [STABLE_TAG]}"
CONTAINER_NAME="${2:-techflow-app}"
HOST_PORT="${3:-80}"
CONTAINER_PORT="${4:-5000}"
STABLE_TAG="${5:-previous_stable}"

ROLLBACK_IMAGE="${IMAGE_REPO}:${STABLE_TAG}"

echo "=========================================="
echo "TechFlow rollback"
echo "Container: ${CONTAINER_NAME}"
echo "Rollback image: ${ROLLBACK_IMAGE}"
echo "=========================================="

echo "Removing failed deployment if present..."
docker rm -f "${CONTAINER_NAME}" 2>/dev/null || true

echo "Pulling rollback image..."
docker pull "${ROLLBACK_IMAGE}"

echo "Starting rollback container..."
docker run \
    --detach \
    --name "${CONTAINER_NAME}" \
    --restart unless-stopped \
    --publish "${HOST_PORT}:${CONTAINER_PORT}" \
    "${ROLLBACK_IMAGE}"

echo "Verifying rollback..."
if /home/ubuntu/health_check.sh "http://localhost/health"; then
    echo "PASS: rollback restored a healthy application."
    exit 0
fi

echo "FAIL: rollback image did not become healthy."
docker logs "${CONTAINER_NAME}" || true
exit 1