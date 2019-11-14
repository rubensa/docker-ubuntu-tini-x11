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
