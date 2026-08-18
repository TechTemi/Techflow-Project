#!/usr/bin/env bash

set -u

HEALTH_URL="${1:-http://localhost/health}"
MAX_ATTEMPTS="${MAX_ATTEMPTS:-5}"
SLEEP_SECONDS="${SLEEP_SECONDS:-5}"

echo "=========================================="
echo "TechFlow deployment health check"
echo "URL: ${HEALTH_URL}"
echo "Maximum attempts: ${MAX_ATTEMPTS}"
echo "=========================================="

for attempt in $(seq 1 "${MAX_ATTEMPTS}"); do
    echo "Health-check attempt ${attempt}/${MAX_ATTEMPTS}..."

    HTTP_STATUS="$(
        curl \
            --silent \
            --show-error \
            --output /tmp/techflow-health-response \
            --write-out "%{http_code}" \
            --max-time 10 \
            "${HEALTH_URL}" \
        || true
    )"

    if [ "${HTTP_STATUS}" = "200" ]; then
        echo "PASS: application returned HTTP 200."

        if [ -f /tmp/techflow-health-response ]; then
            echo "Response:"
            cat /tmp/techflow-health-response
            echo
        fi

        exit 0
    fi

    echo "Application is not healthy yet. HTTP status: ${HTTP_STATUS:-unavailable}"

    if [ "${attempt}" -lt "${MAX_ATTEMPTS}" ]; then
        echo "Waiting ${SLEEP_SECONDS} seconds before retry..."
        sleep "${SLEEP_SECONDS}"
    fi
done

echo "FAIL: application did not become healthy after ${MAX_ATTEMPTS} attempts."
exit 1