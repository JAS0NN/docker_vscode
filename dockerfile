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

# Install code-server with enhanced debugging
RUN mkdir -p /home/vscodeuser/.local/bin && \
    echo "Downloading installation script..." && \
    curl -fsSL https://code-server.dev/install.sh > /tmp/install-code-server.sh && \
    echo "Examining installation script..." && \
    grep -n "install_" /tmp/install-code-server.sh && \
    echo "Running installation with verbose output..." && \
    bash -x /tmp/install-code-server.sh || echo "Installation script failed with exit code $?" && \
    echo "Checking installation results..." && \
    ls -la /home/vscodeuser/.local/bin/ && \
    ls -la /usr/local/bin/ && \
    ls -la /home/vscodeuser/.local/share/ && \
    echo "Setting up PATH..." && \
    echo 'export PATH=$PATH:/home/vscodeuser/.local/bin' >> /home/vscodeuser/.bashrc && \
    echo 'export PATH=$PATH:$HOME/.local/bin' >> /home/vscodeuser/.bashrc && \
    echo 'export PATH=$PATH:$HOME/.local/share/code-server/bin' >> /home/vscodeuser/.bashrc && \
    echo "Searching for code-server binary..." && \
    find / -name "code-server" -type f -o -type l 2>/dev/null || echo "code-server binary not found"

# Switch back to root to create entrypoint
USER root

# Create an entrypoint script with enhanced debugging and fallback paths
RUN echo '#!/bin/bash\n\
echo "Starting code-server..."\n\
echo "Debugging: Checking if code-server exists anywhere in the system:"\n\
find / -name "code-server" -type f -o -type l 2>/dev/null\n\
echo "Debugging: Current PATH for root user:"\n\
echo $PATH\n\
echo "Debugging: vscodeuser environment:"\n\
su - vscodeuser -c "echo PATH=\\$PATH; which code-server || echo code-server not in PATH"\n\
\n\
# Try multiple possible paths for code-server\n\
echo "Attempting to start code-server with multiple possible paths:"\n\
\n\
# First try: Using PATH after sourcing bashrc\n\
echo "Attempt 1: Using PATH after sourcing bashrc"\n\
su - vscodeuser -c "source ~/.bashrc && code-server --bind-addr 0.0.0.0:8080 --auth password" && exit 0\n\
\n\
# Second try: Direct path to .local/bin\n\
echo "Attempt 2: Direct path to .local/bin"\n\
if [ -f "/home/vscodeuser/.local/bin/code-server" ]; then\n\
  su - vscodeuser -c "/home/vscodeuser/.local/bin/code-server --bind-addr 0.0.0.0:8080 --auth password" && exit 0\n\
fi\n\
\n\
# Third try: Check in .local/share/code-server/bin\n\
echo "Attempt 3: Check in .local/share/code-server/bin"\n\
if [ -f "/home/vscodeuser/.local/share/code-server/bin/code-server" ]; then\n\
  su - vscodeuser -c "/home/vscodeuser/.local/share/code-server/bin/code-server --bind-addr 0.0.0.0:8080 --auth password" && exit 0\n\
fi\n\
\n\
# Fourth try: Check in /usr/local/bin\n\
echo "Attempt 4: Check in /usr/local/bin"\n\
if [ -f "/usr/local/bin/code-server" ]; then\n\
  su - vscodeuser -c "/usr/local/bin/code-server --bind-addr 0.0.0.0:8080 --auth password" && exit 0\n\
fi\n\
\n\
echo "ERROR: Could not find code-server binary in any expected location"\n\
exit 1\n\
' > /entrypoint.sh && chmod +x /entrypoint.sh

# Expose VSCode Server port
EXPOSE 8080

# Set entrypoint
ENTRYPOINT ["/entrypoint.sh"]