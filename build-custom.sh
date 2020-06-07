#!/usr/bin/env bash

DOCKER_REPOSITORY_NAME="rubensa"
DOCKER_IMAGE_NAME="ubuntu-tini-x11"
DOCKER_IMAGE_TAG="18.04"

# NVidia propietary drivers are needed on host for this to work
NVIDIA_VERSION=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader)

prepare_docker_nvidia_drivers_version() {
  # On build, if you specify NVIDIA_VERSION the nvidia specified drivers version are installed
  BUILD_ARGS+=" --build-arg NVIDIA_VERSION=$NVIDIA_VERSION"
}

prepare_docker_nvidia_drivers_version

# see: https://github.com/docker/buildx/issues/495#issuecomment-761562905
#docker buildx build --platform=linux/amd64,linux/arm64 --no-cache --progress=plain --pull \
docker buildx build --platform=linux/amd64,linux/arm64 --no-cache \
  -t "${DOCKER_REPOSITORY_NAME}/${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}" \
  --label "maintainer=Ruben Suarez <rubensa@gmail.com>" \
  ${BUILD_ARGS} \
  .

docker buildx build --load \
  -t "${DOCKER_REPOSITORY_NAME}/${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}" \
  .
