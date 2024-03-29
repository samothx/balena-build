# Copyright 2019, Burkhard Stubert (DBA Embedded Use)

# In any directory on the docker host, perform the following actions:
#   * Copy this Dockerfile in the directory.
#   * Create input and output directories: mkdir -p yocto/output yocto/input
#   * Build the Docker image with the following command:
#     docker build --no-cache --build-arg "host_uid=$(id -u)" --build-arg "host_gid=$(id -g)" \
#         --tag "cuteradio-image:latest" .
#   * Run the Docker image, which in turn runs the Yocto and which produces the Linux rootfs,
#     with the following command:
#     docker run -it --rm -v $PWD/yocto/output:/home/cuteradio/yocto/output cuteradio-image:latest

# Use Ubuntu 16.04 LTS as the basis for the Docker image.
FROM ubuntu:16.04

# Install all the Linux packages required for Yocto builds. Note that the packages python3,
# tar, locales and cpio are not listed in the official Yocto documentation. The build, however,
# without them.
RUN apt-get update && apt-get -y install gawk wget git-core diffstat unzip texinfo gcc-multilib \
     build-essential chrpath socat cpio python python3 python3-pip python3-pexpect curl \
     xz-utils debianutils iputils-ping libsdl1.2-dev xterm tar locales iptables \
     nodejs npm jq software-properties-common apt-transport-https ca-certificates


# By default, Ubuntu uses dash as an alias for sh. Dash does not support the source command
# needed for setting up the build environment in CMD. Use bash as an alias for sh.
RUN rm /bin/sh && ln -s bash /bin/sh

# Set the locale to en_US.UTF-8, because the Yocto build fails without any locale set.
RUN locale-gen en_US.UTF-8 && update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8

ENV USER_NAME balena
ENV PROJECT balena

# The running container writes all the build artefacts to a host directory (outside the container).
# The container can only write files to host directories, if it uses the same user ID and
# group ID owning the host directories. The host_uid and group_uid are passed to the docker build
# command with the --build-arg option. By default, they are both 1001. The docker image creates
# a group with host_gid and a user with host_uid and adds the user to the group. The symbolic
# name of the group and user is cuteradio.
# docker gid needs to be same as on host too so set before installing
ARG host_uid=1001
ARG host_gid=1001
ARG docker_gid=1002

RUN groupadd -g $host_gid $USER_NAME && \
    useradd -g $host_gid -m -s /bin/bash -u $host_uid $USER_NAME -d /home/yocto && \
    groupadd -g $docker_gid docker && \
    usermod -aG docker $USER_NAME

RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - && \
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" && \
    apt-get update && \
    apt-cache policy docker-ce && \
    apt-get install -y docker-ce

# Perform the Yocto build as user cuteradio (not as root).
# NOTE: The USER command does not set the environment variable HOME.

# Create the directory structure for the Yocto build in the container. The lowest two directory
# levels must be the same as on the host.
ENV BUILD_INPUT_DIR /home/yocto/input
ENV BUILD_OUTPUT_DIR /home/yocto/output
RUN mkdir -p $BUILD_INPUT_DIR $BUILD_OUTPUT_DIR && \
    chown "$USER_NAME.$USER_NAME" /home/yocto/input && \
    chown "$USER_NAME.$USER_NAME" /home/yocto/output

# By default, docker runs as root. However, Yocto builds should not be run as root, but as a 
# normal user. Hence, we switch to the newly created user cuteradio.

# Prepare Yocto's build environment. If TEMPLATECONF is set, the script oe-init-build-env will
# install the customised files bblayers.conf and local.conf. This script initialises the Yocto
# build environment. The bitbake command builds the rootfs for our embedded device.
WORKDIR $BUILD_INPUT_DIR
# ENV TEMPLATECONF=$BUILD_INPUT_DIR/$PROJECT/sources/meta-$PROJECT/custom
# CMD source $BUILD_INPUT_DIR/$PROJECT/sources/poky/oe-init-build-env build \
#     && bitbake $PROJECT-image

USER root
ADD ./init.sh /home/bin/init.sh

ENTRYPOINT [ "/home/bin/init.sh" ]
CMD ["/bin/bash"]