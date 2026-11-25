#!/usr/bin/env bash
# Build librealsense v2.54.2 (last release supporting the L515) into a private
# prefix, so it coexists with the apt librealsense used by other RealSense cameras.
#
# Environment overrides:
#   PREFIX     install prefix                   (default: /opt/librealsense-l515)
#   LINKS_DIR  where to create the *-l515 links (default: ~/.local/bin, empty = none)
#   JOBS       parallel build jobs              (default: nproc)
set -euo pipefail

readonly LIBREALSENSE_VERSION=v2.54.2
PREFIX="${PREFIX:-/opt/librealsense-l515}"
LINKS_DIR="${LINKS_DIR-$HOME/.local/bin}"
JOBS="${JOBS:-$(nproc)}"
INSTALL_UDEV="${INSTALL_UDEV:-1}"

SUDO=""
if [ "$(id -u)" -ne 0 ]; then SUDO="sudo"; fi        # id -u = 0 means root

$SUDO apt-get update
$SUDO apt-get install -y --no-install-recommends \
  git ca-certificates build-essential pkg-config cmake gcc-12 g++-12 \
  libssl-dev libusb-1.0-0-dev libudev-dev \
  libgtk-3-dev libglfw3-dev libgl1-mesa-dev libglu1-mesa-dev

WORK_DIR="$(mktemp -d)"
trap '$SUDO rm -rf "$WORK_DIR"' EXIT

# Keep librealsense pinned to the last known L515-friendly version (v2.54.2)
git clone --depth 1 --branch "$LIBREALSENSE_VERSION" \
  https://github.com/IntelRealSense/librealsense.git "$WORK_DIR/src"

# GCC 12: v2.54.2 does not build with Ubuntu 24.04's default GCC 13.
# RPATH: installed binaries find this librealsense without LD_LIBRARY_PATH.
# HOME: the viewer installs sample presets under $HOME/Documents; keep them in the temp dir.
HOME="$WORK_DIR" cmake -S "$WORK_DIR/src" -B "$WORK_DIR/build" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_C_COMPILER=gcc-12 -DCMAKE_CXX_COMPILER=g++-12 \
  -DCMAKE_INSTALL_PREFIX="$PREFIX" -DCMAKE_INSTALL_LIBDIR=lib \
  -DCMAKE_INSTALL_RPATH="$PREFIX/lib" \
  -DFORCE_RSUSB_BACKEND=ON \
  -DBUILD_EXAMPLES=ON \
  -DBUILD_GRAPHICAL_EXAMPLES=ON \
  -DBUILD_WITH_CUDA=OFF \
  -DBUILD_PYTHON_BINDINGS=OFF \
  -DIMPORT_DEPTH_CAM_FW=OFF \
  -DCHECK_FOR_UPDATES=OFF
cmake --build "$WORK_DIR/build" --parallel "$JOBS"
$SUDO cmake --install "$WORK_DIR/build"

if [ -n "$LINKS_DIR" ]; then
  mkdir -p "$LINKS_DIR"
  ln -sf "$PREFIX/bin/rs-enumerate-devices" "$LINKS_DIR/rs-enumerate-devices-l515"
  ln -sf "$PREFIX/bin/realsense-viewer" "$LINKS_DIR/realsense-viewer-l515"
fi

# The installed tools must resolve the private librealsense, not the apt one.
if ! ldd "$PREFIX/bin/rs-enumerate-devices" | grep -q "$PREFIX/lib/librealsense2.so.2.54"; then
  echo "ERROR: $PREFIX/bin/rs-enumerate-devices does not use $PREFIX/lib" >&2
  exit 1
fi

# Grant user access to the L515 (USB id 0b64) with a dedicated rules file,
# independent of the rules installed for other RealSense cameras.
if [ "$INSTALL_UDEV" = 1 ]; then
  {
    echo "# Intel RealSense L515, from librealsense $LIBREALSENSE_VERSION"
    grep 'idProduct}=="0b64"' "$WORK_DIR/src/config/99-realsense-libusb.rules"
  } | $SUDO tee /etc/udev/rules.d/99-realsense-l515.rules >/dev/null
  $SUDO udevadm control --reload-rules
  $SUDO udevadm trigger
fi

echo "librealsense $LIBREALSENSE_VERSION installed in $PREFIX"