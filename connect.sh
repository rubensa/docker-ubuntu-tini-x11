#!/usr/bin/env bash

DOCKER_IMAGE_NAME="ubuntu-tini-x11"

docker exec -it \
  "${DOCKER_IMAGE_NAME}" \
  bash -l
