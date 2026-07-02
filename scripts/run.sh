#!/usr/bin/env bash
set -euo pipefail

IMAGE="${IMAGE:-l515-humble:2.54.2-4.54.1}"
CONTAINER_NAME="${CONTAINER_NAME:-l515-humble}"

xhost +local:docker >/dev/null 2>&1 || true

docker run -it --rm \
  --name "${CONTAINER_NAME}" \
  --net=host \
  --privileged \
  -v /dev:/dev \
  -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
  -e DISPLAY="${DISPLAY:-}" \
  -e RMW_IMPLEMENTATION=rmw_cyclonedds_cpp \
  "${IMAGE}" "$@"
