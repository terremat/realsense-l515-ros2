#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
docker build \
  -f docker/Dockerfile \
  -t l515-humble:2.54.2-4.54.1 \
  .
