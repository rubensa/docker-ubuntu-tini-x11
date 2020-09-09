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
    && apt-get -y install --no-install-recommends kmod libglib2.0-bin pulseaudio-utils cups-client x11-utils mesa-utils mesa-utils-extra va-driver-all 2>&1 \
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
    # Install Micro$oft Fonts
    #
    # fontforge is required to convert TTC files into TTF
    && apt-get -y install fontforge \
    #
    # Windows Core fonts:
    # Andale Mono, Arial Black, Arial (Bold, Italic, Bold Italic), Comic Sans MS (Bold), Courier New (Bold, Italic, Bold Italic)
    # Georgia (Bold, Italic, Bold Italic), Impact, Times New Roman (Bold, Italic, Bold Italic), Trebuchet (Bold, Italic, Bold Italic)
    # Verdana (Bold, Italic, Bold Italic), Webdings
    && echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | debconf-set-selections \
    && apt-get -y install ttf-mscorefonts-installer \
    # Microsoft’s ClearType fonts (Windows Vista Fonts):
    # Calibri (Bold, Italic, Bold Italic), Consolas (Bold, Italic, Bold Italic), Candara (Bold, Italic, Bold Italic)
    # Corbel (Bold, Italic, Bold Italic), Constantia (Bold, Italic, Bold Italic), Cambria (Bold, Italic, Bold Italic)
    # Cambria Math
    && mkdir -p /tmp/fonts \
    && curl -L -o /tmp/fonts/PowerPointViewer.exe https://web.archive.org/web/20171225132744/http://download.microsoft.com/download/E/6/7/E675FFFC-2A6D-4AB0-B3EB-27C9F8C8F696/PowerPointViewer.exe \
    && cabextract -F ppviewer.cab /tmp/fonts/PowerPointViewer.exe -d /tmp/fonts \
    && cabextract -L -F '*.tt?' /tmp/fonts/ppviewer.cab -d /tmp/fonts \
    && fontforge -lang=ff -c 'Open("/tmp/fonts/cambria.ttc(Cambria)"); Generate("/tmp/fonts/cambria.ttf"); Close(); Open("/tmp/fonts/cambria.ttc(Cambria Math)"); Generate("/tmp/fonts/cambriamath.ttf"); Close();' \
    # Microsoft Tahoma
    && mkdir -p /tmp/fonts \
    && curl -L -o /tmp/fonts/IELPKTH.CAB https://master.dl.sourceforge.net/project/corefonts/OldFiles/IELPKTH.CAB \
    && cabextract -F 'tahoma*ttf' /tmp/fonts/IELPKTH.CAB -d /tmp/fonts \
    # Wine Tahoma
    && mkdir -p /tmp/fonts \
    && curl -L -o /tmp/fonts/tahoma.ttf http://source.winehq.org/source/fonts/tahoma.ttf?_raw=1 \
    && curl -L -o /tmp/fonts/tahomabd.ttf http://source.winehq.org/source/fonts/tahomabd.ttf?_raw=1 \
    #
    # Segoe UI
    # regular
    && curl -L -o /tmp/fonts/segoeui.ttf https://github.com/rubensa/clide/blob/master/doc/fonts/segoeui.ttf?raw=true \
    # bold
    && curl -L -o /tmp/fonts/segoeuib.ttf https://github.com/rubensa/clide/blob/master/doc/fonts/segoeuib.ttf?raw=true \
    # italic
    && curl -L -o /tmp/fonts/segoeuii.ttf https://github.com/rubensa/clide/blob/master/doc/fonts/segoeuib.ttf?raw=true \
    # bold italic
    && curl -L -o /tmp/fonts/segoeuiz.ttf https://github.com/rubensa/clide/blob/master/doc/fonts/segoeuiz.ttf?raw=true \
    # light
    && curl -L -o /tmp/fonts/segoeuil.ttf https://github.com/rubensa/clide/blob/master/doc/fonts/segoeuil.ttf?raw=true \
    # light italic
    && curl -L -o /tmp/fonts/seguili.ttf https://github.com/rubensa/clide/blob/master/doc/fonts/seguili.ttf?raw=true \
    # semilight
    && curl -L -o /tmp/fonts/segoeuisl.ttf https://github.com/rubensa/clide/blob/master/doc/fonts/segoeuisl.ttf?raw=true \
    # semilight italic
    && curl -L -o /tmp/fonts/seguisli.ttf https://github.com/rubensa/clide/blob/master/doc/fonts/seguisli.ttf?raw=true \
    # semibold
    && curl -L -o /tmp/fonts/seguisb.ttf https://github.com/rubensa/clide/blob/master/doc/fonts/seguisb.ttf?raw=true \
    # semibold italic
    && curl -L -o /tmp/fonts/seguisbi.ttf https://github.com/rubensa/clide/blob/master/doc/fonts/seguisbi.ttf?raw=true \
    #
    # WPS Office Fonts (Symbol fonts)
    && curl -L -o /tmp/fonts/WEBDINGS.TTF https://github.com/rubensa/ttf-wps-fonts/raw/master/WEBDINGS.TTF \
    && curl -L -o /tmp/fonts/WINGDNG2.ttf https://github.com/rubensa/ttf-wps-fonts/raw/master/WINGDNG2.ttf \
    && curl -L -o /tmp/fonts/WINGDNG3.ttf https://github.com/rubensa/ttf-wps-fonts/raw/master/WINGDNG3.ttf \
    && curl -L -o /tmp/fonts/mtextra.ttf https://github.com/rubensa/ttf-wps-fonts/raw/master/mtextra.ttf \
    && curl -L -o /tmp/fonts/symbol.ttf https://github.com/rubensa/ttf-wps-fonts/raw/master/symbol.ttf \
    && curl -L -o /tmp/fonts/wingding.ttf https://github.com/rubensa/ttf-wps-fonts/raw/master/wingding.ttf \
    #
    && mkdir -p /usr/share/fonts/truetype/msttcorefonts/ \
    && cp -f /tmp/fonts/*.ttf /usr/share/fonts/truetype/msttcorefonts \
    && cp -f /tmp/fonts/*.TTF /usr/share/fonts/truetype/msttcorefonts \
    && fc-cache -f /usr/share/fonts/truetype/msttcorefonts \
    && rm -rf /tmp/fonts \
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


