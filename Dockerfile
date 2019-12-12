FROM rubensa/ubuntu-tini-dev
LABEL author="Ruben Suarez <rubensa@gmail.com>"

# If defined, install specified NVIDIA driver version
ARG NVIDIA_VERSION

# Tell docker that all future commands should be run as root
USER root

# Set root home directory
ENV HOME=/root

# DBUS_SESSION_BUS_ADDRESS is lost with sudo (https://github.com/SeleniumHQ/docker-selenium/issues/358)
RUN printf "\nDefaults env_keep += \"DBUS_SESSION_BUS_ADDRESS\"\n" >> /etc/sudoers

# Add script to allow nvidia drivers installation
ADD install-nvidia-drivers.sh /usr/bin/install-nvidia-drivers.sh

# Avoid warnings by switching to noninteractive
ENV DEBIAN_FRONTEND=noninteractive

# Configure apt and install packages
RUN apt-get update \
    # 
    # Install software and needed libraries
    && apt-get -y install module-init-tools libglib2.0-bin pulseaudio-utils cups-client x11-utils mesa-utils mesa-utils-extra va-driver-all \
    #
    # Assign audio group to non-root user
    && usermod -a -G audio ${USER_NAME} \
    #
    # Assign video group to non-root user
    && usermod -a -G video ${USER_NAME} \
    #
    # Install NVIDIA drivers
    && if [ ! -z ${NVIDIA_VERSION} ] ; \
      then \
      curl -O http://us.download.nvidia.com/XFree86/Linux-x86_64/${NVIDIA_VERSION}/NVIDIA-Linux-x86_64-${NVIDIA_VERSION}.run; \
      chmod +x NVIDIA-Linux-x86_64-${NVIDIA_VERSION}.run; \
      ./NVIDIA-Linux-x86_64-${NVIDIA_VERSION}.run --ui=none --no-kernel-module --no-install-compat32-libs --install-libglvnd --no-questions; \
      rm NVIDIA-Linux-x86_64-${NVIDIA_VERSION}.run; \
    fi \
    #
    # Enable runtime nvidia drivers installation
    && chmod +x /usr/bin/install-nvidia-drivers.sh \
    #
    # Configure nvidia drivers installation for the non-root user
    && printf "\n. /usr/bin/install-nvidia-drivers.sh\n" >> /home/${USER_NAME}/.bashrc \
    #
    # Clean up
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

# Switch back to dialog for any ad-hoc use of apt-get
ENV DEBIAN_FRONTEND=

# Tell docker that all future commands should be run as the non-root user
USER ${USER_NAME}

# Set user home directory (see: https://github.com/microsoft/vscode-remote-release/issues/852)
ENV HOME /home/$USER_NAME


