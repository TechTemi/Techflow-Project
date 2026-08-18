#!/usr/bin/env bash

set -euo pipefail

IMAGE_REPO="${1:?Usage: tag_stable.sh IMAGE_REPO [CONTAINER_NAME] [STABLE_TAG]}"
CONTAINER_NAME="${2:-techflow-app}"
STABLE_TAG="${3:-previous_stable}"

STABLE_IMAGE="${IMAGE_REPO}:${STABLE_TAG}"

echo "=========================================="
echo "TechFlow stable-image tagging"
echo "Container: ${CONTAINER_NAME}"
echo "Stable tag: ${STABLE_IMAGE}"
echo "=========================================="

if ! docker ps \
    --filter "name=^/${CONTAINER_NAME}$" \
    --filter "status=running" \
    --format '{{.Names}}' |
    grep --fixed-strings --line-regexp --quiet "${CONTAINER_NAME}"; then

    echo "No currently running ${CONTAINER_NAME} container was found."
    echo "This is expected during the first deployment."
    echo "Skipping stable-image tagging."
    exit 0
fi

CURRENT_IMAGE_ID="$(
    docker inspect \
        --format='{{.Image}}' \
        "${CONTAINER_NAME}"
)"

if [ -z "${CURRENT_IMAGE_ID}" ]; then
    echo "FAIL: unable to determine current container image."
    exit 1
fi

echo "Current image ID: ${CURRENT_IMAGE_ID}"
echo "Tagging running image as ${STABLE_IMAGE}..."
docker tag "${CURRENT_IMAGE_ID}" "${STABLE_IMAGE}"
echo "Pushing stable image to DockerHub..."
docker push "${STABLE_IMAGE}"

echo "PASS: previous stable image has been preserved."