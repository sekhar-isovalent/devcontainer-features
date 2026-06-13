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

# Resolve download URL by querying GitHub API
echo "Resolving Podman download URL..."

if [ "$PODMAN_VERSION" = "latest" ]; then
    API_URL="https://api.github.com/repositories/109145553/releases/latest"
else
    API_URL="https://api.github.com/repositories/109145553/releases/tags/v${PODMAN_VERSION}"
fi

json_response=$(curl -fsSL "$API_URL")

# Extract browser_download_url for podman-remote-static-linux_${PODMAN_ARCH}
# Try using jq if available, otherwise fall back to grep
if command -v jq &> /dev/null; then
    DOWNLOAD_URL=$(echo "$json_response" | jq -r '.assets[] | select(.name | contains("podman-remote-static-linux_'"${PODMAN_ARCH}"'")) | .browser_download_url' | head -1)
else
    DOWNLOAD_URL=$(echo "$json_response" | grep -A 3 "podman-remote-static-linux_${PODMAN_ARCH}.tar.gz" | grep "browser_download_url" | grep -o 'https://[^"]*' | head -1)
fi

if [ -z "$DOWNLOAD_URL" ]; then
    echo "Failed to find Podman ${PODMAN_VERSION} release for architecture ${PODMAN_ARCH}"
    exit 1
fi

echo "Downloading from: $DOWNLOAD_URL"

PODMAN_ARCHIVE="${PODMAN_TEMP_DIR}/podman-remote.tar.gz"

# Download Podman CLI with retry logic
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

# Find the podman binary (it's in bin/ subdirectory with architecture suffix)
PODMAN_BINARY=$(find "$PODMAN_TEMP_DIR" -type f \( -name "podman-remote-static*" -o -name "podman-remote" -o -name "podman" \) | head -1)

if [ -z "$PODMAN_BINARY" ] || [ ! -f "$PODMAN_BINARY" ]; then
    echo "Podman binary not found in archive"
    echo "Archive contents:"
    tar -tzf "$PODMAN_ARCHIVE"
    exit 1
fi

echo "Installing Podman CLI to /usr/local/bin..."
cp "$PODMAN_BINARY" /usr/local/bin/podman
chmod +x /usr/local/bin/podman

# Verify installation
echo "Verifying Podman CLI installation..."
podman --version

echo "Podman CLI installation complete!"
