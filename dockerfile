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
    sudo \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create a user for running VSCode Server
RUN useradd -m -s /bin/bash vscodeuser && \
    echo "vscodeuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
USER vscodeuser
WORKDIR /home/vscodeuser

# Install VSCode Server
RUN curl -fsSL https://code-server.dev/install.sh | sh

# Create an entrypoint script
USER root
RUN echo '#!/bin/bash\n\
# Start code-server\n\
su - vscodeuser -c "code-server --bind-addr 0.0.0.0:8080 --auth password"\n\
' > /entrypoint.sh \
    && chmod +x /entrypoint.sh

# Expose VSCode Server port
EXPOSE 8080

# Set entrypoint
ENTRYPOINT ["/entrypoint.sh"]