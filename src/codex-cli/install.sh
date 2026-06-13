#!/usr/bin/env bash
set -e

umask 022

VERSION="${VERSION:-latest}"
CODEX_INSTALL_SCRIPT_URL="https://chatgpt.com/codex/install.sh"
CODEX_GLOBAL_HOME="/usr/local/share/codex"

install_packages() {
    if ! command -v apt-get >/dev/null 2>&1; then
        return
    fi

    packages=()

    if ! command -v curl >/dev/null 2>&1; then
        packages+=("curl")
    fi

    if [ ! -f /etc/ssl/certs/ca-certificates.crt ]; then
        packages+=("ca-certificates")
    fi

    if ! command -v tar >/dev/null 2>&1; then
        packages+=("tar")
    fi

    if ! command -v gzip >/dev/null 2>&1; then
        packages+=("gzip")
    fi

    if ! command -v sha256sum >/dev/null 2>&1 \
        && ! command -v shasum >/dev/null 2>&1 \
        && ! command -v openssl >/dev/null 2>&1; then
        packages+=("coreutils")
    fi

    if [ ${#packages[@]} -eq 0 ]; then
        return
    fi

    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    apt-get -y install --no-install-recommends "${packages[@]}"
}

download_file() {
    local url=$1
    local output=$2

    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$url" -o "$output"
        return
    fi

    if command -v wget >/dev/null 2>&1; then
        wget -q -O "$output" "$url"
        return
    fi

    echo "curl or wget is required to install Codex CLI." >&2
    exit 1
}

install_packages

tmp_dir="$(mktemp -d)"
cleanup() {
    rm -rf "$tmp_dir"
}
trap cleanup EXIT

installer_path="$tmp_dir/codex-install.sh"
download_file "$CODEX_INSTALL_SCRIPT_URL" "$installer_path"
chmod +x "$installer_path"

# Patch the installer to fix mawk incompatibility: mawk doesn't support
# interval expressions like {64} in regex. Replace with + which is portable.
sed -i 's/{64}/+/g' "$installer_path"

mkdir -p "$CODEX_GLOBAL_HOME" /usr/local/bin

CODEX_RELEASE="$VERSION" \
CODEX_NON_INTERACTIVE=true \
CODEX_INSTALL_DIR="/usr/local/bin" \
CODEX_HOME="$CODEX_GLOBAL_HOME" \
    sh "$installer_path" --release "$VERSION"

chmod -R a+rX "$CODEX_GLOBAL_HOME"

codex --version
echo "Done!"
