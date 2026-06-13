#!/usr/bin/env bash

set -e

PODMAN_VERSION="${VERSION:-latest}"

echo "Installing Podman CLI version: $PODMAN_VERSION"

# Detect architecture
ARCH=$(dpkg --print-architecture)
case "$ARCH" in
    amd64) PODMAN_ARCH="amd64" ;;
    arm64) PODMAN_ARCH="arm64" ;;
    *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

# Create temp directory
PODMAN_TEMP_DIR=$(mktemp -d)
trap "rm -rf $PODMAN_TEMP_DIR" EXIT

# Resolve download URL
if [ "$PODMAN_VERSION" = "latest" ]; then
    echo "Fetching latest Podman version..."
    DOWNLOAD_URL=$(curl -fsSL "https://api.github.com/repos/containers/podman/releases?per_page=10" | jq -r '.[] | select(.prerelease==false) | .assets[] | select(.name | test("podman-remote-static-linux_'${PODMAN_ARCH}'")) | .browser_download_url' | head -1)
    if [ -z "$DOWNLOAD_URL" ]; then
        echo "Failed to find latest Podman release for architecture ${PODMAN_ARCH}"
        exit 1
    fi
else
    DOWNLOAD_URL="https://github.com/containers/podman/releases/download/v${PODMAN_VERSION}/podman-remote-static-linux_${PODMAN_ARCH}.tar.gz"
fi

echo "Using download URL: $DOWNLOAD_URL"

PODMAN_ARCHIVE="${PODMAN_TEMP_DIR}/podman-remote.tar.gz"

# Download Podman CLI with retry logic
echo "Downloading Podman CLI..."
for i in {1..3}; do
    if curl -fsSL -o "$PODMAN_ARCHIVE" "$DOWNLOAD_URL"; then
        break
    fi
    if [ $i -lt 3 ]; then
        echo "Download attempt $i failed, retrying..."
        sleep 2
    else
        echo "Failed to download Podman CLI after 3 attempts"
        exit 1
    fi
done

# Verify archive was downloaded
if [ ! -f "$PODMAN_ARCHIVE" ]; then
    echo "Podman archive not found at $PODMAN_ARCHIVE"
    exit 1
fi

# Extract and install
echo "Extracting Podman CLI..."
tar -xzf "$PODMAN_ARCHIVE" -C "$PODMAN_TEMP_DIR"

# Find the podman binary (it may be named podman-remote in the archive)
PODMAN_BINARY=""
if [ -f "$PODMAN_TEMP_DIR/podman-remote" ]; then
    PODMAN_BINARY="$PODMAN_TEMP_DIR/podman-remote"
elif [ -f "$PODMAN_TEMP_DIR/podman" ]; then
    PODMAN_BINARY="$PODMAN_TEMP_DIR/podman"
else
    echo "Podman binary not found in archive"
    exit 1
fi

echo "Installing Podman CLI to /usr/local/bin..."
cp "$PODMAN_BINARY" /usr/local/bin/podman
chmod +x /usr/local/bin/podman

# Verify installation
echo "Verifying Podman CLI installation..."
podman --version

echo "Podman CLI installation complete!"
