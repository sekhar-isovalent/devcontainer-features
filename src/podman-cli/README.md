
# Podman CLI

Installs the Podman CLI tool (client only, without the daemon).

## Example Usage

```json
"features": {
    "ghcr.io/sekhar-isovalent/devcontainer-features/podman-cli:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Select version of Podman CLI to install, if not latest. | string | latest |

## OS Support

This Feature should work on recent versions of Debian/Ubuntu-based distributions with the `apt` package manager installed.

`bash` and `curl` are required to execute the `install.sh` script.

---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/sekhar-isovalent/devcontainer-features/blob/main/src/podman-cli/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
