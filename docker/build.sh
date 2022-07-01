#!/bin/sh
set -ef

IMAGE_TAG=${1:-latest}

export BASE_NAME=gcc-base-build
export TAG_NAME=${BASE_NAME}:${IMAGE_TAG}

oldpath=`pwd`
cd ..
  docker build --network host --file docker/Dockerfile --tag $TAG_NAME .
cd $oldpath


