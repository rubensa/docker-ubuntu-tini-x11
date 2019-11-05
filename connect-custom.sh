#!/usr/bin/env bash

# Get current user name
IMAGE_BUILD_USER_NAME=$(id -un)

docker exec -it \
  -u $IMAGE_BUILD_USER_NAME \
  -w /home/$IMAGE_BUILD_USER_NAME \
  ubuntu-tini-x11 \
  bash -l
