FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Update and install necessary packages
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    git \
    gnupg2 \
    software-properties-common \
    sudo \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create a user for running VSCode Server
RUN useradd -m -s /bin/bash vscodeuser && \
    echo "vscodeuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Set working directory
WORKDIR /home/vscodeuser

# Install code-server directly from GitHub releases (as root)
RUN mkdir -p /home/vscodeuser/.local/bin && \
    echo "Downloading code-server directly from GitHub..." && \
    VERSION="4.22.1" && \
    wget -q https://github.com/coder/code-server/releases/download/v${VERSION}/code-server-${VERSION}-linux-amd64.tar.gz -O /tmp/code-server.tar.gz && \
    echo "Extracting code-server..." && \
    mkdir -p /home/vscodeuser/.local/lib/code-server && \
    tar -xzf /tmp/code-server.tar.gz --strip-components=1 -C /home/vscodeuser/.local/lib/code-server && \
    echo "Creating symlink to code-server binary..." && \
    ln -sf /home/vscodeuser/.local/lib/code-server/bin/code-server /home/vscodeuser/.local/bin/code-server && \
    echo "Setting permissions..." && \
    chown -R vscodeuser:vscodeuser /home/vscodeuser/.local && \
    echo "Setting up PATH..." && \
    echo 'export PATH=$PATH:/home/vscodeuser/.local/bin' >> /home/vscodeuser/.bashrc

# Now switch to vscodeuser after installation
USER vscodeuser

# Create a script to set default password and start code-server
USER root
RUN mkdir -p /home/vscodeuser/.config/code-server && \
    echo "bind-addr: 0.0.0.0:8080" > /home/vscodeuser/.config/code-server/config.yaml && \
    echo "auth: password" >> /home/vscodeuser/.config/code-server/config.yaml && \
    echo "password: MySecurePassword123" >> /home/vscodeuser/.config/code-server/config.yaml && \
    echo "cert: false" >> /home/vscodeuser/.config/code-server/config.yaml && \
    chown -R vscodeuser:vscodeuser /home/vscodeuser/.config && \
    echo '#!/bin/bash' > /entrypoint.sh && \
    echo 'echo "Config file already created with default password."' >> /entrypoint.sh && \
    echo 'ls -l /home/vscodeuser/.config/code-server/config.yaml' >> /entrypoint.sh && \
    echo 'exec sudo -iu vscodeuser /home/vscodeuser/.local/bin/code-server' >> /entrypoint.sh && \
    chmod +x /entrypoint.sh

# Expose VSCode Server port
EXPOSE 8080

# Set entrypoint
ENTRYPOINT ["/entrypoint.sh"]