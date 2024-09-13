#!/bin/bash

# Create .devcontainer directory
mkdir -p .devcontainer

# Create devcontainer.json file
cat > .devcontainer/devcontainer.json <<EOL
{
  "name": "Flutter Dev Container",
  "build": {
    "dockerfile": "Dockerfile"
  },
  "settings": {
    "terminal.integrated.shell.linux": "/bin/bash"
  },
  "extensions": [
    "Dart-Code.dart-code",
    "Dart-Code.flutter"
  ],
  "forwardPorts": [8080],
  "postCreateCommand": "flutter doctor",
  "remoteUser": "codespace"
}
EOL

# Create Dockerfile
cat > .devcontainer/Dockerfile <<EOL
# Use Ubuntu 20.04 as base image
FROM ubuntu:20.04

# Avoid prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install necessary packages
RUN apt-get update && apt-get install -y \\
    curl \\
    git \\
    unzip \\
    xz-utils \\
    zip \\
    libglu1-mesa \\
    libgtk-3-dev \\
    libpulse0 \\
    libbz2-dev \\
    sudo \\
    apt-transport-https \\
    ca-certificates \\
    build-essential \\
    openssh-client \\
    openssl \\
    clang \\
    cmake \\
    ninja-build \\
    pkg-config \\
    liblzma-dev

# Create a non-root user and add to sudoers
RUN useradd -ms /bin/bash codespace && adduser codespace sudo
RUN echo 'codespace ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

USER codespace
WORKDIR /home/codespace

# Install Flutter SDK
RUN git clone https://github.com/flutter/flutter.git -b stable

# Set Flutter PATH
ENV PATH="/home/codespace/flutter/bin:/home/codespace/flutter/bin/cache/dart-sdk/bin:\${PATH}"

# Enable web support
RUN flutter config --enable-web

# Pre-cache Flutter web artifacts
RUN flutter precache --web

# Accept Android licenses (if needed)
# RUN yes "y" | flutter doctor --android-licenses || true

# Run flutter doctor
RUN flutter doctor

# Set default shell to bash
SHELL ["/bin/bash", "-c"]

EOL

echo "Dev container setup complete. Please rebuild your Codespace to apply the changes."