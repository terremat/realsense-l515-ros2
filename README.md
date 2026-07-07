# L515 ROS2 Docker

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

To build the experimental Jazzy image:

```bash
./scripts/build.sh jazzy
```

## Run

```bash
./scripts/run.sh
```

The runner creates one persistent container and opens a shell in it. Running the
same command from another terminal opens another shell in the same container.

ROS network environment variables are loaded from:

```bash
ros_network.env
```

By default this file keeps the container off the common ROS domain 0 and disables
the ROS 2 CLI daemon cache while debugging:

```bash
ROS_LOCALHOST_ONLY=0
ROS_DOMAIN_ID=42
RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
ROS_DISABLE_DAEMON=1
```

With `--net=host`, the container shares the host network namespace. If you need
to communicate with ROS 2 nodes on other PCs, use the same `ROS_DOMAIN_ID` on the
machines that should see each other.

To run the experimental Jazzy image instead of the default Humble image:

```bash
IMAGE=l515-jazzy:2.54.2-4.54.1-experimental CONTAINER_NAME=l515-jazzy ./scripts/run.sh
```

The Humble image remains the stable L515 baseline. The Jazzy image is provided
to test host/container ROS 2 compatibility with Jazzy systems.

The Jazzy image still defaults to `librealsense v2.54.2` for L515 support and
`realsense-ros 4.54.1`. That wrapper release does not officially support Jazzy,
so the Dockerfile applies a small experimental CMake patch that treats Jazzy like
the Humble/Iron-era ROS 2 backend. It builds that SDK with GCC 12 to avoid Ubuntu
24.04/GCC 13 build failures. To test another SDK version:

```bash
./scripts/build.sh jazzy --build-arg LIBREALSENSE_VERSION=v2.56.0
```

## Launch the Camera

Inside the container:

```bash
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
ros2 topic hz /camera/color/camera_info
ros2 topic echo /camera/color/image_raw --qos-reliability best_effort --once
```

To visually check the RGB stream inside the container:

```bash
ros2 run image_tools showimage --ros-args -r image:=/camera/color/image_raw
```

For quick DDS checks without the camera, run these in two terminals:

```bash
./scripts/run.sh --talker
./scripts/run.sh --listener
```

## Host Jazzy

When the host is running ROS 2 Jazzy, the Humble container may discover topics
over DDS using `--net=host`, but cross-distro communication is not always
reliable for all topic types, QoS settings, and RMW combinations. If topics are
visible but `ros2 topic echo` does not receive data, first try matching the RMW
implementation on both sides, then test the experimental Jazzy image.

This project uses CycloneDDS by default to keep the middleware choice explicit.

## Notes

Do not upgrade `librealsense` o `realsense-ros`. The Docker image intentionally pins the SDK and ROS wrapper to the last known working versions for the L515.
