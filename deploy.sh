#!/bin/sh

set -eu

IMAGE="${1:-}"
BUILD_NUMBER="${2:-unknown}"
GIT_COMMIT="${3:-unknown}"

CONTAINER="orderhub"
PORT="8080"
APP_VERSION="1.0.1"

if [ -z "$IMAGE" ]; then
    echo "ERROR: Docker image was not provided."
    echo "Usage: ./deploy.sh <image> <build_number> <git_commit>"
    exit 1
fi

echo "======================================"
echo "OrderHub Deployment"
echo "======================================"
echo "Image      : $IMAGE"
echo "Build      : $BUILD_NUMBER"
echo "Git Commit : $GIT_COMMIT"
echo "App Version: $APP_VERSION"
echo "Container  : $CONTAINER"
echo "Port       : $PORT"
echo "======================================"

echo "Checking exact image..."

if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
    echo "Image not found locally."
    echo "Pulling exact immutable image..."

    docker pull "$IMAGE"

    if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
        echo "ERROR: Required image is not available: $IMAGE"
        exit 2
    fi
fi

echo "Exact image is available."

echo "Stopping old container..."

if docker ps -q --filter "name=^${CONTAINER}$" | grep -q .; then
    docker stop "$CONTAINER"
fi

echo "Removing old container..."

if docker ps -aq --filter "name=^${CONTAINER}$" | grep -q .; then
    docker rm "$CONTAINER"
fi

echo "Starting new container..."

docker run -d \
    --name "$CONTAINER" \
    -p "$PORT:8080" \
    -e APP_VERSION="$APP_VERSION" \
    -e BUILD_NUMBER="$BUILD_NUMBER" \
    -e GIT_COMMIT="$GIT_COMMIT" \
    "$IMAGE"

echo "Waiting for application health..."

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

    exit 3
fi

echo "Running smoke test..."

curl -fsS "http://localhost:$PORT/orders" >/dev/null

echo "Orders endpoint PASSED."

curl -fsS "http://localhost:$PORT/version"

echo

echo "Version endpoint PASSED."

echo "Checking container user..."

docker exec "$CONTAINER" whoami

echo
echo "======================================"
echo "Deployment successful"
echo "======================================"

echo "Deployed image:"
docker inspect "$CONTAINER" \
    --format '{{.Config.Image}}'

echo
echo "Container status:"
docker ps --filter "name=^${CONTAINER}$"

echo
echo "OrderHub deployment completed."
echo "======================================"