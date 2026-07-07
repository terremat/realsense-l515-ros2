#!/usr/bin/env bash
set -e
set +u
source "/opt/ros/${ROS_DISTRO:-humble}/setup.bash"
source /ros2_ws/install/setup.bash
set -u
exec "$@"
