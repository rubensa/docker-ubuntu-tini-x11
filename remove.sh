#!/usr/bin/env bash

DOCKER_IMAGE_NAME="ubuntu-tini-x11"

docker rm \
  "${DOCKER_IMAGE_NAME}"
