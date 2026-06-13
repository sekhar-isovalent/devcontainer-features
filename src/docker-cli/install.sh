#!/usr/bin/env bash

set -e

DOCKER_VERSION="${VERSION:-latest}"

echo "Installing Docker CLI version: $DOCKER_VERSION"

# Detect architecture
ARCH=$(dpkg --print-architecture)
case "$ARCH" in
    amd64) DOCKER_ARCH="x86_64" ;;
    arm64) DOCKER_ARCH="aarch64" ;;
    armhf) DOCKER_ARCH="armv7l" ;;
    *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

# Get version if not specified or if latest
if [ "$DOCKER_VERSION" = "latest" ]; then
    DOCKER_VERSION=$(curl -fsSL "https://api.github.com/repos/moby/moby/releases/latest" | grep -oP '"tag_name": "\K[^"]+')
    DOCKER_VERSION="${DOCKER_VERSION#v}"
    echo "Latest Docker version: $DOCKER_VERSION"
fi

# Download Docker CLI
DOWNLOAD_URL="https://download.docker.com/linux/static/stable/${DOCKER_ARCH}/docker-${DOCKER_VERSION}.tgz"
DOCKER_TEMP_DIR=$(mktemp -d)
DOCKER_ARCHIVE="${DOCKER_TEMP_DIR}/docker-${DOCKER_VERSION}.tgz"

echo "Downloading Docker CLI from: $DOWNLOAD_URL"
curl -fsSL -o "$DOCKER_ARCHIVE" "$DOWNLOAD_URL"

# Extract and install
echo "Extracting Docker CLI..."
tar -xzf "$DOCKER_ARCHIVE" -C "$DOCKER_TEMP_DIR"

echo "Installing Docker CLI to /usr/local/bin..."
cp "$DOCKER_TEMP_DIR/docker/docker" /usr/local/bin/docker
chmod +x /usr/local/bin/docker

# Cleanup
rm -rf "$DOCKER_TEMP_DIR"

# Verify installation
echo "Verifying Docker CLI installation..."
docker --version

echo "Docker CLI installation complete!"
