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

# Install code-server with debugging
RUN mkdir -p /home/vscodeuser/.local/bin && \
    curl -fsSL https://code-server.dev/install.sh | sh -x && \
    echo 'export PATH=$PATH:/home/vscodeuser/.local/bin' >> /home/vscodeuser/.bashrc && \
    echo 'export PATH=$PATH:$HOME/.local/bin' >> /home/vscodeuser/.bashrc && \
    find /home/vscodeuser -name "code-server" -type f -o -type l 2>/dev/null || echo "code-server binary not found"

# Switch back to root to create entrypoint
USER root

# Create an entrypoint script with debugging and proper environment sourcing
RUN echo '#!/bin/bash\n\
echo "Starting code-server..."\n\
echo "Debugging: Checking if code-server exists"\n\
find /home -name "code-server" -type f -o -type l\n\
echo "Debugging: Current PATH for root user:"\n\
echo $PATH\n\
echo "Debugging: vscodeuser environment:"\n\
su - vscodeuser -c "echo PATH=\\$PATH; which code-server || echo code-server not in PATH"\n\
echo "Attempting to start code-server with full environment sourcing:"\n\
su - vscodeuser -c "source ~/.bashrc && code-server --bind-addr 0.0.0.0:8080 --auth password"\n\
' > /entrypoint.sh && chmod +x /entrypoint.sh

# Expose VSCode Server port
EXPOSE 8080

# Set entrypoint
ENTRYPOINT ["/entrypoint.sh"]