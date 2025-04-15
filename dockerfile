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
    xvfb \
    xfce4 \
    xfce4-goodies \
    tightvncserver \
    dbus-x11 \
    xterm \
    sudo \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Visual Studio Code
RUN wget -qO - https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg \
    && install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/ \
    && sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list' \
    && apt-get update \
    && apt-get install -y code \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create a user for running VSCode and VNC
RUN useradd -m -s /bin/bash vscodeuser && \
    echo "vscodeuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
USER vscodeuser
WORKDIR /home/vscodeuser

# Set up VNC server
RUN mkdir ~/.vnc \
    && echo "password" | vncpasswd -f > ~/.vnc/passwd \
    && chmod 600 ~/.vnc/passwd \
    && echo '#!/bin/bash\nxrdb $HOME/.Xresources\nstartxfce4 &' > ~/.vnc/xstartup \
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
# Start Xvfb with proper permissions\n\
Xvfb :0 -screen 0 1280x720x24 &\n\
sleep 2\n\
export DISPLAY=:0\n\
\n\
# Start VNC server as vscodeuser\n\
su - vscodeuser -c "vncserver :1 -geometry 1280x720 -depth 24 -localhost no"\n\
sleep 2\n\
\n\
# Start XFCE4 and VSCode\n\
su - vscodeuser -c "DISPLAY=:1 startxfce4 &"\n\
sleep 3\n\
su - vscodeuser -c "DISPLAY=:1 code --no-sandbox &"\n\
\n\
# Keep the container running\n\
tail -f /dev/null' > /entrypoint.sh \
    && chmod +x /entrypoint.sh

# Expose VNC port
EXPOSE 5901

# Set entrypoint
ENTRYPOINT ["/entrypoint.sh"]
