FROM ros:humble-ros-base-jammy

ARG DEBIAN_FRONTEND=noninteractive
ARG LIBREALSENSE_VERSION=v2.54.2
ARG REALSENSE_ROS_VERSION=4.54.1

ENV ROS_DISTRO=humble \
    RMW_IMPLEMENTATION=rmw_cyclonedds_cpp

SHELL ["/bin/bash", "-c"]

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    cmake \
    build-essential \
    pkg-config \
    ninja-build \
    python3-colcon-common-extensions \
    python3-rosdep \
    python3-vcstool \
    libssl-dev \
    libusb-1.0-0-dev \
    libudev-dev \
    libgtk-3-dev \
    libglfw3-dev \
    libgl1-mesa-dev \
    libglu1-mesa-dev \
    udev \
    v4l-utils \
    ros-humble-demo-nodes-cpp \
    ros-humble-image-tools \
    ros-humble-rqt-image-view \
    ros-humble-rviz2 \
    ros-humble-rmw-cyclonedds-cpp \
    ros-humble-diagnostic-updater \
    ros-humble-cv-bridge \
    ros-humble-image-transport \
    ros-humble-tf2-ros \
    ros-humble-xacro \
    && rm -rf /var/lib/apt/lists/*

# Build librealsense from pinned source. Avoid DKMS inside container.
WORKDIR /opt/src
RUN git clone https://github.com/IntelRealSense/librealsense.git && \
    cd librealsense && \
    git checkout ${LIBREALSENSE_VERSION} && \
    mkdir -p build && cd build && \
    cmake .. \
      -DCMAKE_BUILD_TYPE=Release \
      -DBUILD_EXAMPLES=true \
      -DBUILD_GRAPHICAL_EXAMPLES=true \
      -DBUILD_WITH_CUDA=false \
      -DFORCE_RSUSB_BACKEND=true && \
    make -j$(nproc) && \
    make install && \
    ldconfig

# Copy udev rules into the image for reference; host still controls actual device permissions.
RUN cp /opt/src/librealsense/config/99-realsense-libusb.rules /etc/udev/rules.d/ || true

# Build realsense-ros from pinned source.
WORKDIR /ros2_ws/src
RUN git clone https://github.com/realsenseai/realsense-ros.git && \
    cd realsense-ros && \
    git checkout ${REALSENSE_ROS_VERSION}

WORKDIR /ros2_ws
RUN source /opt/ros/${ROS_DISTRO}/setup.bash && \
    (rosdep update || true) && \
    apt-get update && \
    rosdep install --from-paths src --ignore-src -r -y --skip-keys=librealsense2 && \
    rm -rf /var/lib/apt/lists/* && \
    colcon build --symlink-install --cmake-args -DCMAKE_BUILD_TYPE=Release

COPY scripts/container_entrypoint.sh /container_entrypoint.sh
COPY scripts/l515-camera /usr/local/bin/l515-camera
RUN chmod +x /container_entrypoint.sh /usr/local/bin/l515-camera

ENTRYPOINT ["/container_entrypoint.sh"]
CMD ["bash"]
