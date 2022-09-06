#!/usr/bin/env bash

DOCKER_IMAGE_NAME="ubuntu-tini-x11"

docker stop  \
  "${DOCKER_IMAGE_NAME}"
