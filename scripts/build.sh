#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

variant="${1:-humble}"
if [ "$#" -gt 0 ]; then
  shift
fi

case "${variant}" in
  humble)
    dockerfile="docker/Dockerfile"
    tag="${IMAGE:-l515-humble:2.54.2-4.54.1}"
    ;;
  jazzy)
    dockerfile="docker/Dockerfile.jazzy"
    tag="${IMAGE:-l515-jazzy:2.54.2-4.54.1-experimental}"
    ;;
  *)
    printf "Usage: %s [humble|jazzy] [docker build args...]\n" "$0" >&2
    exit 2
    ;;
esac

docker build \
  -f "${dockerfile}" \
  -t "${tag}" \
  "$@" \
  .
