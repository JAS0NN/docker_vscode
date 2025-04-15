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

# Switch to vscodeuser for installation
USER vscodeuser
WORKDIR /home/vscodeuser

# Install code-server correctly
RUN mkdir -p /home/vscodeuser/.local/bin && \
    curl -fsSL https://code-server.dev/install.sh | sh && \
    echo 'export PATH=$PATH:/home/vscodeuser/.local/bin' >> /home/vscodeuser/.bashrc

# Switch back to root to create entrypoint
USER root

# Create an entrypoint script with correct path
RUN echo '#!/bin/bash\n\
echo "Starting code-server..."\n\
su - vscodeuser -c "/home/vscodeuser/.local/bin/code-server --bind-addr 0.0.0.0:8080 --auth password"\n\
' > /entrypoint.sh && chmod +x /entrypoint.sh

# Expose VSCode Server port
EXPOSE 8080

# Set entrypoint
ENTRYPOINT ["/entrypoint.sh"]