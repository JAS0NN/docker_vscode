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

# Install code-server (VSCode Server)
RUN curl -fsSL https://code-server.dev/install.sh | sh

# Create an entrypoint script with proper path to code-server
RUN echo '#!/bin/bash\n\
export PATH=$PATH:/usr/bin:/usr/local/bin\n\
echo "Starting code-server..."\n\
su - vscodeuser -c "/usr/bin/code-server --bind-addr 0.0.0.0:8080 --auth password"\n\
' > /entrypoint.sh && chmod +x /entrypoint.sh

# Set working directory
WORKDIR /home/vscodeuser

# Expose VSCode Server port
EXPOSE 8080

# Set entrypoint
ENTRYPOINT ["/entrypoint.sh"]