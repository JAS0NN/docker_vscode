FROM ubuntu:22.04

# Set environment variables for non-interactive installation
ENV DEBIAN_FRONTEND=noninteractive

# Update and install necessary packages
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    git \
    gnupg2 \
    software-properties-common \
    xorg \
    lxde \
    lxde-common \
    tightvncserver \
    dbus-x11 \
    xterm \
    sudo \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && echo "allowed_users=anybody" > /etc/X11/Xwrapper.config

# Install Visual Studio Code
RUN apt-get update && apt-get install -y apt-transport-https ca-certificates gnupg \
    && mkdir -p /etc/apt/keyrings \
    && wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /etc/apt/keyrings/microsoft.gpg \
    && echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list \
    && apt-get update \
    && apt-get install -y code \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create a user for running VSCode and VNC
RUN useradd -m -s /bin/bash vscodeuser && \
    echo "vscodeuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
USER vscodeuser
WORKDIR /home/vscodeuser

# Set up .xsession to start LXDE for VNC sessions
RUN echo "startlxde" > /home/vscodeuser/.xsession

# Set up VNC server
RUN mkdir ~/.vnc \
    && echo "password" | vncpasswd -f > ~/.vnc/passwd \
    && chmod 600 ~/.vnc/passwd \
    && touch ~/.Xresources \
    && echo '#!/bin/bash\nunset SESSION_MANAGER\nunset DBUS_SESSION_BUS_ADDRESS\nexport XKL_XMODMAP_DISABLE=1\nexport DISPLAY=:1\nxrdb $HOME/.Xresources\nif [ -f $HOME/.xsession ]; then\n    . $HOME/.xsession &\nelse\n    startlxde &\nfi\nsleep 3\ncode --no-sandbox &' > ~/.vnc/xstartup \
    && chmod +x ~/.vnc/xstartup

# Create an entrypoint script to start services
USER root
RUN echo '#!/bin/bash\n\
# Create required directories with proper permissions\n\
mkdir -p /tmp/.X11-unix /tmp/.ICE-unix\n\
chmod 1777 /tmp/.X11-unix /tmp/.ICE-unix\n\
\n\
# Start dbus system daemon\n\
service dbus start\n\
sleep 2\n\
\n\
# Set proper permissions for the vscodeuser'\''s .vnc directory\n\
chown -R vscodeuser:vscodeuser /home/vscodeuser/.vnc\n\
\n\
# Start VNC server as vscodeuser (which will start LXDE and VSCode via xstartup)\n\
su - vscodeuser -c "vncserver :1 -geometry 1280x720 -depth 24"\n\
sleep 2\n\
\n\
# Keep the container running\n\
tail -f /dev/null' > /entrypoint.sh \
    && chmod +x /entrypoint.sh

# Expose VNC port
EXPOSE 5901

# Set entrypoint
ENTRYPOINT ["/entrypoint.sh"]
