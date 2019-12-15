#!/bin/bash
docker run -it --rm \
  -v "$1":/home/balena/yocto/output \
  -v "$PWD/yocto/output":/home/balena/yocto/output \
  balena-os-builder:latest