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
    echo "Fetching latest Docker version..."
    DOCKER_VERSION=$(curl -fsSL "https://api.github.com/repos/moby/moby/releases/latest" | grep -o '"tag_name":"[^"]*"' | head -1 | cut -d'"' -f4)
    if [ -z "$DOCKER_VERSION" ]; then
        echo "Failed to determine latest Docker version, using 27.0.3 as fallback"
        DOCKER_VERSION="27.0.3"
    fi
    DOCKER_VERSION="${DOCKER_VERSION#v}"
    echo "Using Docker version: $DOCKER_VERSION"
fi

# Create temp directory
DOCKER_TEMP_DIR=$(mktemp -d)
trap "rm -rf $DOCKER_TEMP_DIR" EXIT

DOCKER_ARCHIVE="${DOCKER_TEMP_DIR}/docker-${DOCKER_VERSION}.tgz"

# Download Docker CLI with retry logic
DOWNLOAD_URL="https://download.docker.com/linux/static/stable/${DOCKER_ARCH}/docker-${DOCKER_VERSION}.tgz"
echo "Downloading Docker CLI from: $DOWNLOAD_URL"

for i in {1..3}; do
    if curl -fsSL -o "$DOCKER_ARCHIVE" "$DOWNLOAD_URL"; then
        break
    fi
    if [ $i -lt 3 ]; then
        echo "Download attempt $i failed, retrying..."
        sleep 2
    else
        echo "Failed to download Docker CLI after 3 attempts"
        exit 1
    fi
done

# Verify archive was downloaded
if [ ! -f "$DOCKER_ARCHIVE" ]; then
    echo "Docker archive not found at $DOCKER_ARCHIVE"
    exit 1
fi

# Extract and install
echo "Extracting Docker CLI..."
tar -xzf "$DOCKER_ARCHIVE" -C "$DOCKER_TEMP_DIR"

if [ ! -f "$DOCKER_TEMP_DIR/docker/docker" ]; then
    echo "Docker binary not found in archive"
    exit 1
fi

echo "Installing Docker CLI to /usr/local/bin..."
cp "$DOCKER_TEMP_DIR/docker/docker" /usr/local/bin/docker
chmod +x /usr/local/bin/docker

# Verify installation
echo "Verifying Docker CLI installation..."
docker --version

echo "Docker CLI installation complete!"
