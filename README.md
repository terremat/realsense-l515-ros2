# realsense-l515-ros2

Run the Intel RealSense **L515** on **ROS 2 Jazzy / Ubuntu 24.04**.

The L515 has reached End of Life (EOL): the last releases supporting it are
librealsense 2.54.2 and realsense-ros 4.54.1, while ROS 2 Jazzy ships newer
versions that no longer detect it. This repository keeps those versions working
on Jazzy, in two ways:

| | Native installation | Docker |
|---|---|---|
| On the host | librealsense 2.54.2 + the `realsense2_camera_l515` ROS 2 package | Docker only |
| Run the camera with | `ros2 launch` from your workspace | `./scripts/run.sh` |
| Best for | PCs with other RealSense cameras or ROS 2 workspaces | quick use, or hosts you prefer to keep clean |

Both use the same pinned software:

- **librealsense 2.54.2**, built into its own prefix `/opt/librealsense-l515`,
  separate from any other librealsense on the system;
- **`realsense2_camera_l515`**, the realsense-ros 4.54.1 node, renamed so it
  can run next to the standard `realsense2_camera` used for other RealSense
  cameras (e.g. D455).

## Native installation

### 1. Install librealsense 2.54.2

```bash
mkdir -p ~/ros2_ws/src && cd ~/ros2_ws/src
git clone https://github.com/terremat/realsense-l515-ros2.git
cd realsense-l515-ros2
./scripts/install_librealsense_l515.sh
```

The script installs the build dependencies with apt, builds librealsense
(15–20 minutes) into `/opt/librealsense-l515` and adds an L515-only udev rule
(`/etc/udev/rules.d/99-realsense-l515.rules`). It also links two librealsense
2.54.2 tools into `~/.local/bin`: `rs-enumerate-devices-l515` and
`realsense-viewer-l515`.

Reconnect the camera, then check it:

```bash
rs-enumerate-devices-l515 -s
```

### 2. Build the ROS 2 package

```bash
cd ~/ros2_ws
source /opt/ros/jazzy/setup.bash
rosdep install --from-paths src --ignore-src -y
colcon build --cmake-args -DCMAKE_BUILD_TYPE=Release
source install/setup.bash
```

## Usage

```bash
ros2 launch realsense2_camera_l515 rs_launch.py serial_no:=_<serial> camera_name:=l515 \
  depth_module.profile:=1024x768x30 rgb_camera.profile:=1280x720x30
```

Topics are published under `/<camera_name>/`, e.g. `/l515/color/image_raw` and
`/l515/depth/image_rect_raw`. Main launch arguments:

| Argument | Description |
|---|---|
| `serial_no` | camera serial number; the leading `_` keeps it a string |
| `camera_name` | namespace and node name (default `camera`) |
| `depth_module.profile` | depth resolution and fps, e.g. `1024x768x30` |
| `rgb_camera.profile` | color resolution and fps, e.g. `1280x720x30` |
| `enable_color`, `enable_depth` | enable the streams (default `true`) |
| `align_depth.enable` | publish depth aligned to color |
| `pointcloud.enable` | publish a point cloud |
| `config_file` | YAML file with further node parameters |

### Depth stopping every second

If the log repeats `Receiver light saturation, stream stopped for 1 sec`, the
sensor is saturated by ambient light or by close, reflective objects. Change
the preset (`1` Default, `2` No Ambient Light, `3` Low Ambient Light,
`4` Max Range, `5` Short Range) while the node is running:

```bash
ros2 param set /l515/l515 depth_module.visual_preset 5
```

or at startup, with `config_file:=<file>.yaml` containing
`depth_module.visual_preset: 5`.

### Tools

- `rs-enumerate-devices-l515` and `realsense-viewer-l515` use librealsense 2.54.2.
- The viewer may warn that udev rules are missing: it only looks for the
  standard rule file names, so with the L515 rule installed you can ignore it.
- Do not use these tools to update the firmware of other RealSense cameras.

## Docker

From the repository root:

```bash
docker build -f docker/Dockerfile -t realsense-l515-ros2:jazzy .
./scripts/run.sh                                  # shell in a persistent container
./scripts/run.sh ros2 launch realsense2_camera_l515 rs_launch.py serial_no:=_<serial>
./scripts/run.sh realsense-viewer-l515
```

- `run.sh` starts the container with USB access (`--privileged`, `/dev`), the
  host network and X11; further calls open more shells or run commands in the
  same container. The host needs neither ROS nor udev rules.
- ROS network settings come from `docker/ros_network.env` (override with
  `ROS_ENV_FILE`). `ROS_DOMAIN_ID` must match the nodes the container talks to.
- `./scripts/run.sh --help` lists the DDS test helpers (`--talker`,
  `--listener`, `--debug-ros`) and `--stop` / `--rm`.

## Building other code against librealsense 2.54.2

When a system or apt librealsense is also installed:

- find it only in the private prefix:
  `find_package(realsense2 2.54.2 EXACT PATHS /opt/librealsense-l515 NO_DEFAULT_PATH)`;
- put its headers first:
  `target_include_directories(<target> BEFORE PRIVATE ${realsense2_INCLUDE_DIR})`;
- set the target `INSTALL_RPATH` to `/opt/librealsense-l515/lib`.

See `realsense2_camera_l515/CMakeLists.txt` for an example.

## License

Apache License 2.0, see [LICENSE](LICENSE).

`realsense2_camera_l515` is derived from
[realsense-ros](https://github.com/realsenseai/realsense-ros) 4.54.1 by Intel
Corporation; its `LICENSE` and `NOTICE` are in the package folder and modified
files are marked. librealsense is downloaded and built from
[upstream](https://github.com/IntelRealSense/librealsense) during installation.

Intel and RealSense are trademarks of Intel Corporation, used here descriptively.