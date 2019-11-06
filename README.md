# Docker image based on rubensa/ubuntu-tini-user for running GUI apps

This is a Docker image based on [rubensa/ubuntu-tini-user](https://github.com/rubensa/docker-ubuntu-tini-user) useful for launching X11 GUI applications.

## Building

You can build the image like this:

```
#!/usr/bin/env bash

docker build --no-cache \
  -t "rubensa/ubuntu-tini-x11" \
  --label "maintainer=Ruben Suarez <rubensa@gmail.com>" \
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
  # On run, if you specify USER_ID or GROUP_ID environment variables the system change internal user UID and group GID to that provided.
  # This also changes file ownership for those under /home/$USER/ owned by build-time UID and GUID.
  ENV_VARS+=" --env=USER_ID=$USER_ID"
  ENV_VARS+=" --env=GROUP_ID=$GROUP_ID"
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
}

prepare_docker_webcam_host_sharing() {
  # Allow webcam access
  for device in /dev/video*
  do
    if [[ -c $device ]]; then
      DEVICES+=" --device $device"
    fi
  done
}

prepare_docker_gpu_host_sharing() {
  # GPU support (Direct Rendering Manager)
  # Only available if non propietry drivers used
  [ -d /dev/dri ] && DEVICES+=" --device /dev/dri"
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
  rubensa/ubuntu-tini-x11
```

*NOTE*: Mounting /etc/timezone and /etc/localtime allows you to use your host timezone on container.

Specifying USER_ID, and GROUP_ID environment variables on run, makes the system change internal user UID and group GID to that provided.  This also changes files under his home directory that are owned by user and group to those provided.

This allows to set default owner of the files to you (very usefull for mounted volumes).

If you enabled Docker in Docker support in base image and you are memmber of docker group in your host system you can run de container like:

```
#!/usr/bin/env bash

# Get current user UID
USER_ID=$(id -u)
# Get current user main GUID
GROUP_ID=$(id -g)
# Host docker group
DOCKER_GROUP_NAME=docker
# Host docker group GID
DOCKER_GROUP_ID=$(getent group $DOCKER_GROUP_NAME | cut -d: -f3)

prepare_docker_timezone() {
  # https://www.waysquare.com/how-to-change-docker-timezone/
  MOUNTS+=" --mount type=bind,source=/etc/timezone,target=/etc/timezone,readonly"
  MOUNTS+=" --mount type=bind,source=/etc/localtime,target=/etc/localtime,readonly"
}

prepare_docker_user_and_group() {
  # On run, if you specify USER_ID or GROUP_ID environment variables the system change internal user UID and group GID to that provided.
  # This also changes file ownership for those under /home/$USER/ owned by build-time UID and GUID.
  ENV_VARS+=" --env=USER_ID=$USER_ID"
  ENV_VARS+=" --env=GROUP_ID=$GROUP_ID"
}

prepare_docker_in_docker() {
  # Allow host docker access
  MOUNTS+=" --mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock"
  MOUNTS+=" --mount type=bind,source=$(which docker),target=/usr/local/bin/docker"
  # On run, if you specify DOCKER_GROUP_ID environment variable the system change internal docker group GID to that provided.
  ENV_VARS+=" --env=DOCKER_GROUP_ID=$DOCKER_GROUP_ID"
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
}

prepare_docker_webcam_host_sharing() {
  # Allow webcam access
  for device in /dev/video*
  do
    if [[ -c $device ]]; then
      DEVICES+=" --device $device"
    fi
  done
}

prepare_docker_gpu_host_sharing() {
  # GPU support (Direct Rendering Manager)
  # Only available if non propietry drivers used
  [ -c /dev/dri ] && DEVICES+=" --device /dev/dri"
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
prepare_docker_in_docker
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
  rubensa/ubuntu-tini-x11
```

## Connect

You can connect to the running container like this:

```
#!/usr/bin/env bash

# Set build time user name
IMAGE_BUILD_USER_NAME=user

docker exec -it \
  -u $IMAGE_BUILD_USER_NAME \
  -w /home/$IMAGE_BUILD_USER_NAME \
  ubuntu-tini-x11 \
  bash -l
```

This creates a bash shell run by the specified user (that must exist in the container - by default "user" if not specified other on base rubensa/ubuntu-tini-user image build)

*NOTE*:  Keep in mind that if you do not specify user, the command is run as root in the container.

If you added docker build image args to change default non-root user you sould connect to the running container like this:

```
#!/usr/bin/env bash

# Get current user name
IMAGE_BUILD_USER_NAME=$(id -un)

docker exec -it \
  -u $IMAGE_BUILD_USER_NAME \
  -w /home/$IMAGE_BUILD_USER_NAME \
  ubuntu-tini-x11 \
  bash -l
```

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
