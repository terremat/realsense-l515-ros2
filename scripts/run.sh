#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

IMAGE="${IMAGE:-l515-humble:2.54.2-4.54.1}"
CONTAINER_NAME="${CONTAINER_NAME:-l515-humble}"
ROS_ENV_FILE="${ROS_ENV_FILE:-${ROOT_DIR}/ros_network.env}"
ROS_ENV_KEYS=()

usage() {
  cat <<EOF
Usage:
  $0 [command...]
  $0 --stop
  $0 --rm
  $0 --debug-ros
  $0 --talker
  $0 --listener

Without arguments, opens a bash shell in ${CONTAINER_NAME}.
With a command, runs it inside the same container.

Environment:
  IMAGE=${IMAGE}
  CONTAINER_NAME=${CONTAINER_NAME}
  ROS_ENV_FILE=${ROS_ENV_FILE}
EOF
}

load_ros_env_file() {
  if [ ! -f "${ROS_ENV_FILE}" ]; then
    return
  fi

  while IFS= read -r line || [ -n "${line}" ]; do
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"

    case "${line}" in
      ""|\#*)
        continue
        ;;
    esac

    if [[ "${line}" =~ ^[A-Za-z_][A-Za-z0-9_]*= ]]; then
      key="${line%%=*}"
      value="${line#*=}"
      export "${key}=${value}"
      ROS_ENV_KEYS+=("${key}")
    else
      printf "Ignoring invalid line in %s: %s\n" "${ROS_ENV_FILE}" "${line}" >&2
    fi
  done < "${ROS_ENV_FILE}"
}

docker_env_args() {
  local args=()
  local key

  for key in "${ROS_ENV_KEYS[@]}"; do
    args+=("-e" "${key}=${!key}")
  done

  printf '%s\n' "${args[@]}"
}

container_exists() {
  docker container inspect "${CONTAINER_NAME}" >/dev/null 2>&1
}

container_running() {
  [ "$(docker inspect -f '{{.State.Running}}' "${CONTAINER_NAME}" 2>/dev/null || true)" = "true" ]
}

start_new_container() {
  xhost +local:docker >/dev/null 2>&1 || true
  mapfile -t env_args < <(docker_env_args)

  docker run -d \
    --name "${CONTAINER_NAME}" \
    --net=host \
    --privileged \
    -v /dev:/dev \
    -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
    -e DISPLAY="${DISPLAY:-}" \
    "${env_args[@]}" \
    "${IMAGE}" sleep infinity >/dev/null
}

ensure_container_running() {
  if container_running; then
    return
  fi

  if container_exists; then
    printf "Starting existing container %s...\n" "${CONTAINER_NAME}"
    docker start "${CONTAINER_NAME}" >/dev/null
  else
    printf "Creating container %s from image %s...\n" "${CONTAINER_NAME}" "${IMAGE}"
    start_new_container
  fi
}

case "${1:-}" in
  -h|--help)
    usage
    exit 0
    ;;
  -s|--stop)
    if container_exists; then
      printf "Stopping %s...\n" "${CONTAINER_NAME}"
      docker stop "${CONTAINER_NAME}" >/dev/null
    else
      printf "Container %s does not exist.\n" "${CONTAINER_NAME}"
    fi
    exit 0
    ;;
  -r|--rm|--remove)
    if container_exists; then
      printf "Removing %s...\n" "${CONTAINER_NAME}"
      docker rm -f "${CONTAINER_NAME}" >/dev/null
    else
      printf "Container %s does not exist.\n" "${CONTAINER_NAME}"
    fi
    exit 0
    ;;
esac

load_ros_env_file
ensure_container_running

xhost +local:docker >/dev/null 2>&1 || true

exec_args=("-it")
if [ ! -t 0 ] || [ ! -t 1 ]; then
  exec_args=("-i")
fi

if [ "$#" -eq 0 ]; then
  set -- bash
fi

if [ "${1:-}" = "--debug-ros" ]; then
  set -- bash -lc 'set -e; echo "container=$(hostname)"; echo "ROS_DISTRO=${ROS_DISTRO:-}"; echo "ROS_DOMAIN_ID=${ROS_DOMAIN_ID:-}"; echo "ROS_LOCALHOST_ONLY=${ROS_LOCALHOST_ONLY:-}"; echo "ROS_AUTOMATIC_DISCOVERY_RANGE=${ROS_AUTOMATIC_DISCOVERY_RANGE:-}"; echo "RMW_IMPLEMENTATION=${RMW_IMPLEMENTATION:-}"; ros2 daemon stop >/dev/null 2>&1 || true; echo "--- nodes"; ros2 node list --no-daemon || true; echo "--- topics"; ros2 topic list --no-daemon || true'
fi

if [ "${1:-}" = "--talker" ]; then
  set -- ros2 run demo_nodes_cpp talker
fi

if [ "${1:-}" = "--listener" ]; then
  set -- ros2 run demo_nodes_cpp listener
fi

mapfile -t env_args < <(docker_env_args)
docker exec "${exec_args[@]}" \
  -e DISPLAY="${DISPLAY:-}" \
  "${env_args[@]}" \
  "${CONTAINER_NAME}" /container_entrypoint.sh "$@"
