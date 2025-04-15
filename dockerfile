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

# Install code-server directly from GitHub releases
RUN mkdir -p /home/vscodeuser/.local/bin && \
    echo "Downloading code-server directly from GitHub..." && \
    VERSION="4.14.1" && \
    wget -q https://github.com/coder/code-server/releases/download/v${VERSION}/code-server-${VERSION}-linux-amd64.tar.gz -O /tmp/code-server.tar.gz && \
    echo "Extracting code-server..." && \
    mkdir -p /home/vscodeuser/.local/lib/code-server && \
    tar -xzf /tmp/code-server.tar.gz -C /home/vscodeuser/.local/lib && \
    mv /home/vscodeuser/.local/lib/code-server-${VERSION}-linux-amd64 /home/vscodeuser/.local/lib/code-server && \
    echo "Creating symlink to code-server binary..." && \
    ln -sf /home/vscodeuser/.local/lib/code-server/bin/code-server /home/vscodeuser/.local/bin/code-server && \
    echo "Setting permissions..." && \
    chown -R vscodeuser:vscodeuser /home/vscodeuser/.local && \
    echo "Setting up PATH..." && \
    echo 'export PATH=$PATH:/home/vscodeuser/.local/bin' >> /home/vscodeuser/.bashrc && \
    echo "Verifying installation..." && \
    ls -la /home/vscodeuser/.local/bin/ && \
    ls -la /home/vscodeuser/.local/lib/code-server/bin/

# Switch back to root to create entrypoint
USER root

# Create a simple entrypoint script with direct path to code-server
RUN echo '#!/bin/bash\n\
echo "--- Entrypoint Start ---"\n\
echo "Running as: $(whoami)"\n\
echo "Attempting to start code-server as vscodeuser..."\n\
echo "Command: /home/vscodeuser/.local/bin/code-server --bind-addr 0.0.0.0:8080 --auth password"\n\
# Execute code-server as vscodeuser and capture exit code\n\
su - vscodeuser -c "echo \\"--- Running as vscodeuser: $(whoami) ---\\"; echo \\"--- vscodeuser PATH: $PATH ---\\"; echo \\"--- vscodeuser Environment: ---\\"; env; echo \\"--- Starting code-server process ---\\"; /home/vscodeuser/.local/bin/code-server --bind-addr 0.0.0.0:8080 --auth password"\n\
EXIT_CODE=$?\n\
echo "--- code-server process exited with code: $EXIT_CODE ---"\n\
# Keep container running if needed for debugging, or exit based on code\n\
# exit $EXIT_CODE \n\
# For debugging, let\'s sleep indefinitely if it fails\n\
if [ $EXIT_CODE -ne 0 ]; then\n\
  echo "Error detected. Sleeping indefinitely for debugging..."\n\
  sleep infinity\n\
fi\n\
' > /entrypoint.sh && chmod +x /entrypoint.sh

# Expose VSCode Server port
EXPOSE 8080

# Set entrypoint
ENTRYPOINT ["/entrypoint.sh"]