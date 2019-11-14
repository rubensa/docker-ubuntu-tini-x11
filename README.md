# Docker image based on rubensa/ubuntu-tini-dev for running GUI apps

This is a Docker image based on [rubensa/ubuntu-tini-dev](https://github.com/rubensa/docker-ubuntu-tini-dev) useful for launching X11 GUI applications.

## Building

You can build the image like this:

```
#!/usr/bin/env bash

docker build --no-cache \
  -t "rubensa/ubuntu-tini-x11" \
  --label "maintainer=Ruben Suarez <rubensa@gmail.com>" \
  .
```

To make an Nvidia GPU available in the docker container, the following steps have to be taken:

```
#!/usr/bin/env bash

# NVidia propietary drivers are needed on host for this to work
NVIDIA_VERSION=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader)

prepare_docker_nvidia_drivers_version() {
  # On build, if you specify NVIDIA_VERSION the nvidia specified drivers version are installed
  BUILD_ARGS+=" --build-arg NVIDIA_VERSION=$NVIDIA_VERSION"
}

prepare_docker_nvidia_drivers_version

docker build --no-cache \
  -t "rubensa/ubuntu-tini-x11" \
  --label "maintainer=Ruben Suarez <rubensa@gmail.com>" \
  ${BUILD_ARGS} \
  .
```

## Running

You can run the container like this (change --rm with -d if you don't want the container to be removed on stop):

```
#!/usr/bin/env bash

# Get current user UID
USER_ID=$(id -u)
# Get current user main GUID
GROUP_ID=$(id -g)

prepare_docker_timezone() {
  # https://www.waysquare.com/how-to-change-docker-timezone/
  MOUNTS+=" --mount type=bind,source=/etc/timezone,target=/etc/timezone,readonly"
  MOUNTS+=" --mount type=bind,source=/etc/localtime,target=/etc/localtime,readonly"
}

prepare_docker_user_and_group() {
  RUNNER+=" --user=${USER_ID}:${GROUP_ID}"
}

prepare_docker_dbus_host_sharing() {
  # To access DBus you ned to start a container without an AppArmor profile
  SECURITY+=" --security-opt apparmor:unconfined"
  # https://github.com/mviereck/x11docker/wiki/How-to-connect-container-to-DBus-from-host
  # User DBus
  MOUNTS+=" --mount type=bind,source=${XDG_RUNTIME_DIR}/bus,target=${XDG_RUNTIME_DIR}/bus"
  # System DBus
  MOUNTS+=" --mount type=bind,source=/run/dbus/system_bus_socket,target=/run/dbus/system_bus_socket"
  # User DBus unix socket
  ENV_VARS+=" --env=DBUS_SESSION_BUS_ADDRESS=$DBUS_SESSION_BUS_ADDRESS"
}

prepare_docker_xdg_runtime_dir_host_sharing() {
  # XDG_RUNTIME_DIR defines the base directory relative to which user-specific non-essential runtime files and other file objects (such as sockets, named pipes, ...) should be stored.
  MOUNTS+=" --mount type=bind,source=${XDG_RUNTIME_DIR},target=${XDG_RUNTIME_DIR}"
  # XDG_RUNTIME_DIR
  ENV_VARS+=" --env=XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR}"
}

prepare_docker_sound_host_sharing() {
  # Sound device (ALSA - Advanced Linux Sound Architecture - support)
  [ -d /dev/snd ] && DEVICES+=" --device /dev/snd"
  # Pulseaudio unix socket (needs XDG_RUNTIME_DIR support)
  MOUNTS+=" --mount type=bind,source=${XDG_RUNTIME_DIR}/pulse,target=${XDG_RUNTIME_DIR}/pulse,readonly"
  # https://github.com/TheBiggerGuy/docker-pulseaudio-example/issues/1
  ENV_VARS+=" --env=PULSE_SERVER=unix:${XDG_RUNTIME_DIR}/pulse/native"
  RUNNER_GROUPS+=" --group-add audio"
}

prepare_docker_webcam_host_sharing() {
  # Allow webcam access
  for device in /dev/video*
  do
    if [[ -c $device ]]; then
      DEVICES+=" --device $device"
    fi
  done
  RUNNER_GROUPS+=" --group-add video"
}

prepare_docker_gpu_host_sharing() {
  # GPU support (Direct Rendering Manager)
  [ -d /dev/dri ] && DEVICES+=" --device /dev/dri"
  # VGA Arbiter
  [ -c /dev/vga_arbiter ] && DEVICES+=" --device /dev/vga_arbiter"
  # Allow nvidia devices access
  for device in /dev/nvidia*
  do
    if [[ -c $device ]]; then
      DEVICES+=" --device $device"
    fi
  done
}

prepare_docker_printer_host_sharing() {
  # CUPS (https://github.com/mviereck/x11docker/wiki/CUPS-printer-in-container)
  MOUNTS+=" --mount type=bind,source=/run/cups/cups.sock,target=/run/cups/cups.sock"
  ENV_VARS+=" --env CUPS_SERVER=/run/cups/cups.sock"
}

prepare_docker_x11_host_sharing() {
   # X11 Unix-domain socket
  MOUNTS+=" --mount type=bind,source=/tmp/.X11-unix,target=/tmp/.X11-unix"
  ENV_VARS+=" --env=DISPLAY=unix${DISPLAY}"
  # Credentials in cookies used by xauth for authentication of X sessions
  MOUNTS+=" --mount type=bind,source=${XAUTHORITY},target=${XAUTHORITY}"
  ENV_VARS+=" --env=XAUTHORITY=${XAUTHORITY}"
}

prepare_docker_hostname_host_sharing() {
  # Using host hostname allows gnome-shell windows grouping
  EXTRA+="  --hostname `hostname`"
}

prepare_docker_timezone
prepare_docker_user_and_group
prepare_docker_dbus_host_sharing
prepare_docker_xdg_runtime_dir_host_sharing
prepare_docker_sound_host_sharing
prepare_docker_webcam_host_sharing
prepare_docker_gpu_host_sharing
prepare_docker_printer_host_sharing
prepare_docker_x11_host_sharing
prepare_docker_hostname_host_sharing

docker run --rm -it \
  --name "ubuntu-tini-x11" \
  ${SECURITY} \
  ${ENV_VARS} \
  ${DEVICES} \
  ${MOUNTS} \
  ${EXTRA} \
  ${RUNNER} \
  ${RUNNER_GROUPS} \
  rubensa/ubuntu-tini-x11
```

*NOTE*: Mounting /etc/timezone and /etc/localtime allows you to use your host timezone on container.

This way, the internal user UID an group GID are changed to the current host user:group launching the container and the existing files under his internal HOME directory that where owned by user and group are also updated to belong to the new UID:GID.

Functions prepare_docker_dbus_host_sharing, prepare_docker_xdg_runtime_dir_host_sharing, prepare_docker_sound_host_sharing, prepare_docker_webcam_host_sharing, prepare_docker_gpu_host_sharing, prepare_docker_printer_host_sharing, prepare_docker_x11_host_sharing and prepare_docker_hostname_host_sharing allows sharing your host resources with the running container as GUI apps can interact with your host system as they where installed in the host.

## Connect

You can connect to the running container like this:

```
#!/usr/bin/env bash

docker exec -it \
  ubuntu-tini-x11 \
  bash -l
```

This creates a bash shell run by the internal user.

Once connected...

You can check DBUS running command:

```
app_name="MY APP NAME" \
id="42" \
icon="ubuntu-logo" \
summary="my summary" \
body="my body" \
actions="[]" \
hints="{}" \
timeout="5000" # in milliseconds \
gdbus call --session   \
   --dest org.freedesktop.Notifications \
   --object-path /org/freedesktop/Notifications \
   --method org.freedesktop.Notifications.Notify \
   "${app_name}" "${id}" "${icon}" "${summary}" "${body}" \
   "${actions}" "${hints}" "${timeout}"
```

You can check Pulse Audio running command:

```
pacat < /dev/urandom
```

You can check CUPS running command:

```
lpstat -H
```

You can check X11 running command:

```
xmessage 'Hello, World!'
```

Your can chedk GPU acceleration is working running command:
```
glxgears
```

## Stop

You can stop the running container like this:

```
#!/usr/bin/env bash

docker stop \
  ubuntu-tini-x11
```

## Start

If you run the container without --rm you can start it again like this:

```
#!/usr/bin/env bash

docker start \
  ubuntu-tini-x11
```

## Remove

If you run the container without --rm you can remove once stopped like this:

```
#!/usr/bin/env bash

docker rm \
  ubuntu-tini-x11
```
