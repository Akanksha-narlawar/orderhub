#!/bin/sh

set -eu

IMAGE="${1:-}"
BUILD_NUMBER="${2:-unknown}"
GIT_COMMIT="${3:-unknown}"

CONTAINER="orderhub"
PORT="8080"

if [ -z "$IMAGE" ]; then
    echo "ERROR: Docker image was not provided."
    exit 1
fi

echo "======================================"
echo "OrderHub Deployment"
echo "======================================"
echo "Image      : $IMAGE"
echo "Build      : $BUILD_NUMBER"
echo "Git Commit : $GIT_COMMIT"
echo "Container  : $CONTAINER"
echo "Port       : $PORT"
echo "======================================"

echo "Checking image..."

if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
    echo "Image not found locally. Pulling exact image..."

    if ! docker pull "$IMAGE"; then
        echo "ERROR: Failed to pull image: $IMAGE"
        exit 2
    fi
fi

echo "Stopping old container..."

if docker ps -q --filter "name=^${CONTAINER}$" | grep -q .; then
    docker stop "$CONTAINER" || true
fi

echo "Removing old container..."

if docker ps -aq --filter "name=^${CONTAINER}$" | grep -q .; then
    docker rm "$CONTAINER" || true
fi

echo "Starting new container..."

if ! docker run -d \
    --name "$CONTAINER" \
    -p "$PORT:8080" \
    -e APP_VERSION="1.0.0" \
    -e BUILD_NUMBER="$BUILD_NUMBER" \
    -e GIT_COMMIT="$GIT_COMMIT" \
    "$IMAGE"; then

    echo "ERROR: Container failed to start."
    exit 3
fi

echo "Waiting for health..."

i=1

while [ "$i" -le 30 ]; do

    if curl -fsS "http://localhost:$PORT/health" >/dev/null 2>&1; then
        echo "Health check PASSED."
        break
    fi

    echo "Waiting... attempt $i/30"
    sleep 2

    i=$((i + 1))
done

if ! curl -fsS "http://localhost:$PORT/health" >/dev/null 2>&1; then
    echo "ERROR: Health check FAILED."

    docker logs "$CONTAINER" || true

    docker stop "$CONTAINER" || true
    docker rm "$CONTAINER" || true

    exit 4
fi

echo "Running smoke test..."

if ! curl -fsS "http://localhost:$PORT/orders" >/dev/null; then
    echo "ERROR: Smoke test FAILED."
    exit 5
fi

echo "======================================"
echo "Deployment successful"
echo "======================================"

echo "Image:"
docker inspect "$CONTAINER" \
    --format '{{.Config.Image}}'

echo "Version:"
curl -fsS "http://localhost:$PORT/version"

echo

echo "Container user:"
docker exec "$CONTAINER" whoami

echo "======================================"