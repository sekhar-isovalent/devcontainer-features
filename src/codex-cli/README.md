# Codex CLI (codex-cli)

Installs Codex CLI and the Codex VS Code extension.

## Example Usage

```json
"features": {
    "ghcr.io/sekhar-isovalent/devcontainer-features/codex-cli:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Select the Codex CLI version to install. | string | latest |

## Customizations

### VS Code Extensions

- `openai.chatgpt`

## OS Support

This Feature should work on recent versions of Debian/Ubuntu-based distributions with the `apt` package manager installed.

`bash` is required to execute the `install.sh` script.

---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/sekhar-isovalent/devcontainer-features/blob/main/src/codex-cli/devcontainer-feature.json). Add additional notes to a `NOTES.md`._
