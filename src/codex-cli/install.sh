#!/usr/bin/env bash
set -e

umask 022

VERSION="${VERSION:-latest}"
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

file_sha256() {
    local path=$1

    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$path" | cut -d' ' -f1
        return
    fi

    if command -v shasum >/dev/null 2>&1; then
        shasum -a 256 "$path" | cut -d' ' -f1
        return
    fi

    if command -v openssl >/dev/null 2>&1; then
        openssl dgst -sha256 "$path" | sed 's/^.*= //'
        return
    fi

    echo "sha256sum, shasum, or openssl is required." >&2
    exit 1
}

resolve_version() {
    if [ "$VERSION" != "latest" ]; then
        echo "${VERSION#v}"
        return
    fi

    local release_json
    release_json="$(curl -fsSL "https://api.github.com/repos/openai/codex/releases/latest")"
    echo "$release_json" | sed -n 's/.*"tag_name":[[:space:]]*"rust-v\([^"]*\)".*/\1/p' | head -n 1
}

install_packages

tmp_dir="$(mktemp -d)"
cleanup() {
    rm -rf "$tmp_dir"
}
trap cleanup EXIT

echo "==> Resolving Codex CLI version"
resolved_version="$(resolve_version)"
if [ -z "$resolved_version" ]; then
    echo "Failed to resolve Codex CLI version." >&2
    exit 1
fi
echo "==> Version: $resolved_version"

arch="$(uname -m)"
case "$arch" in
    x86_64|amd64) vendor_target="x86_64-unknown-linux-musl" ;;
    arm64|aarch64) vendor_target="aarch64-unknown-linux-musl" ;;
    *) echo "Unsupported architecture: $arch" >&2; exit 1 ;;
esac

package_asset="codex-package-${vendor_target}.tar.gz"
checksum_asset="codex-package_SHA256SUMS"
base_url="https://github.com/openai/codex/releases/download/rust-v${resolved_version}"

archive_path="$tmp_dir/$package_asset"
checksum_path="$tmp_dir/$checksum_asset"

echo "==> Downloading Codex CLI"
download_file "$base_url/$checksum_asset" "$checksum_path"
download_file "$base_url/$package_asset" "$archive_path"

echo "==> Verifying checksum"
expected_digest="$(grep "  ${package_asset}$" "$checksum_path" | cut -d' ' -f1)"
if [ -z "$expected_digest" ]; then
    expected_digest="$(grep "  ${package_asset}\$" "$checksum_path" | awk '{print $1}')"
fi
if [ -z "$expected_digest" ]; then
    echo "Could not find checksum for $package_asset" >&2
    echo "Contents of SHA256SUMS:"
    cat "$checksum_path"
    exit 1
fi

actual_digest="$(file_sha256 "$archive_path")"
if [ "$actual_digest" != "$expected_digest" ]; then
    echo "Checksum mismatch!" >&2
    echo "expected: $expected_digest" >&2
    echo "actual:   $actual_digest" >&2
    exit 1
fi

echo "==> Installing Codex CLI"
release_dir="$CODEX_GLOBAL_HOME/packages/standalone/releases/${resolved_version}-${vendor_target}"
mkdir -p "$release_dir"
tar -xzf "$archive_path" -C "$release_dir"

mkdir -p /usr/local/bin
ln -sf "$release_dir/bin/codex" /usr/local/bin/codex

# Create the "current" symlink
current_link="$CODEX_GLOBAL_HOME/packages/standalone/current"
ln -sfn "$release_dir" "$current_link"

chmod -R a+rX "$CODEX_GLOBAL_HOME"

codex --version
echo "Done!"
