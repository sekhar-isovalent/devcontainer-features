#!/usr/bin/env bash

set -e

PODMAN_VERSION="${VERSION:-latest}"

echo "Installing Podman CLI version: $PODMAN_VERSION"

# Detect architecture
ARCH=$(dpkg --print-architecture)
case "$ARCH" in
    amd64) PODMAN_ARCH="amd64" ;;
    arm64) PODMAN_ARCH="arm64" ;;
    armhf) PODMAN_ARCH="arm" ;;
    *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

# Get version if not specified or if latest
if [ "$PODMAN_VERSION" = "latest" ]; then
    PODMAN_VERSION=$(curl -fsSL "https://api.github.com/repos/containers/podman/releases/latest" | grep -oP '"tag_name": "\K[^"]+')
    PODMAN_VERSION="${PODMAN_VERSION#v}"
    echo "Latest Podman version: $PODMAN_VERSION"
fi

# Download Podman CLI
DOWNLOAD_URL="https://github.com/containers/podman/releases/download/v${PODMAN_VERSION}/podman-${PODMAN_VERSION}.linux-${PODMAN_ARCH}.tar.gz"
PODMAN_TEMP_DIR=$(mktemp -d)
PODMAN_ARCHIVE="${PODMAN_TEMP_DIR}/podman-${PODMAN_VERSION}.tar.gz"

echo "Downloading Podman CLI from: $DOWNLOAD_URL"
if ! curl -fsSL -o "$PODMAN_ARCHIVE" "$DOWNLOAD_URL"; then
    echo "Failed to download Podman CLI. The version or architecture may not be available."
    rm -rf "$PODMAN_TEMP_DIR"
    exit 1
fi

# Extract and install
echo "Extracting Podman CLI..."
tar -xzf "$PODMAN_ARCHIVE" -C "$PODMAN_TEMP_DIR"

echo "Installing Podman CLI to /usr/local/bin..."
cp "$PODMAN_TEMP_DIR/podman/podman" /usr/local/bin/podman
chmod +x /usr/local/bin/podman

# Cleanup
rm -rf "$PODMAN_TEMP_DIR"

# Verify installation
echo "Verifying Podman CLI installation..."
podman --version

echo "Podman CLI installation complete!"
