FROM ros:jazzy-ros-base-noble

ARG DEBIAN_FRONTEND=noninteractive

ENV ROS_DISTRO=jazzy \
    RMW_IMPLEMENTATION=rmw_cyclonedds_cpp

SHELL ["/bin/bash", "-c"]

# Tools for the workspace build and debugging helpers.
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3-colcon-common-extensions \
    python3-rosdep \
    ros-jazzy-demo-nodes-cpp \
    ros-jazzy-image-tools \
    ros-jazzy-rqt-image-view \
    ros-jazzy-rviz2 \
    ros-jazzy-rmw-cyclonedds-cpp \
    && rm -rf /var/lib/apt/lists/*

# librealsense 2.54.2, same procedure as the native installation. Kept in its
# own layer so that changing the ROS package does not rebuild it.
COPY scripts/install_librealsense_l515.sh /tmp/install_librealsense_l515.sh
RUN INSTALL_UDEV=0 LINKS_DIR=/usr/local/bin /tmp/install_librealsense_l515.sh && \
    rm -rf /var/lib/apt/lists/* /tmp/install_librealsense_l515.sh

COPY realsense2_camera_l515 /ros2_ws/src/realsense2_camera_l515

WORKDIR /ros2_ws
RUN source /opt/ros/${ROS_DISTRO}/setup.bash && \
    (rosdep update || true) && \
    apt-get update && \
    rosdep install --from-paths src --ignore-src -y && \
    rm -rf /var/lib/apt/lists/* && \
    colcon build --cmake-args -DCMAKE_BUILD_TYPE=Release

COPY docker/entrypoint.sh /container_entrypoint.sh
RUN chmod +x /container_entrypoint.sh

ENTRYPOINT ["/container_entrypoint.sh"]
CMD ["bash"]
