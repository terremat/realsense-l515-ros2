# L515 ROS2 Humble Docker

A reproducible Docker environment for the Intel RealSense L515, allowing the camera to run on modern Linux systems (e.g. Ubuntu 24.04 + ROS 2 Jazzy) while keeping the last known working software stack inside an Ubuntu 22.04 + ROS 2 Humble container.

The goal of this project is to preserve compatibility with the Intel RealSense L515, which has reached End of Life (EOL) and is no longer supported by the latest librealsense releases.

This project is pinned to the last known working combination for the L515:
- Ubuntu 22.04 Jammy nel container
- ROS2 Humble
- librealsense `v2.54.2`
- realsense-ros `4.54.1`

## Host Requirements

The host only needs Docker (or Podman) and USB access to the camera.

For Ubuntu:

```bash
sudo apt update
sudo apt install -y docker.io git
sudo usermod -aG docker $USER
```
Then log out and log back in.

For simplicity, the container runs with `--privileged` e `/dev` mounted from the host. For production deployments, device access can be restricted as needed.

## Build

```bash
./scripts/build.sh
```

## Run

```bash
./scripts/run.sh
```

## Launch the Camera

Inside the container:

```bash
source /opt/ros/humble/setup.bash
source /ros2_ws/install/setup.bash
ros2 launch realsense2_camera rs_launch.py \
  depth_module.profile:=1024x768x30 \
  pointcloud.enable:=true
```

Alternatively, use the provided shortcut:

```bash
l515-camera
```

## Verify topic

```bash
ros2 topic list
ros2 topic echo /camera/camera/depth/camera_info --once
```

## Host Jazzy

When the host is running ROS 2 Jazzy, the container can publish standard ROS messages over DDS using `--net=host`.
This project uses CycloneDDS to maximize interoperability between ROS 2 distributions.

## Notes

Do not upgrade `librealsense` o `realsense-ros`. The Docker image intentionally pins the SDK and ROS wrapper to the last known working versions for the L515.