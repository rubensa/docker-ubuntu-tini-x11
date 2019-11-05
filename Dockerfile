FROM rubensa/ubuntu-tini-user
LABEL author="Ruben Suarez <rubensa@gmail.com>"

# Avoid warnings by switching to noninteractive
ENV DEBIAN_FRONTEND=noninteractive

# Configure apt and install packages
RUN apt-get update \
    # 
    # Install software and needed libraries
    && apt-get -y install libglib2.0-bin pulseaudio-utils cups-client x11-utils \
    #
    # Assign audio group to non-root user
    && usermod -a -G audio ${USER} \
    #
    # Assign video group to non-root user
    && usermod -a -G video ${USER} \
    #
    # Clean up
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

# Switch back to dialog for any ad-hoc use of apt-get
ENV DEBIAN_FRONTEND=
