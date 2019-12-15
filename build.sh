#!/bin/bash
# removed option --no-cache 
docker build --build-arg "host_uid=$(id -u)" \
  --build-arg "host_gid=$(id -g)" --tag "balena-os-builder:latest" .