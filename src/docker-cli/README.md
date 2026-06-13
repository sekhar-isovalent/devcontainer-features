
# Docker CLI (docker-cli)

Installs the Docker CLI tool (client only, without the daemon).

## Example Usage

```json
"features": {
    "ghcr.io/sekhar-isovalent/devcontainer-features/docker-cli:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Select version of Docker CLI to install, if not latest. | string | latest |

# Docker CLI Feature Notes

This feature installs only the Docker CLI binary (client), not the Docker daemon. This is useful for scenarios where you want to interact with a remote Docker daemon (e.g., via Docker socket mounting or Docker host environment variables) without running a full Docker daemon in the container.

## Socket Mounting Example

To use the Docker CLI with a Docker socket from the host:

```json
"mounts": [
    "source=/var/run/docker.sock,target=/var/run/docker.sock,type=bind"
]
```

## Remote Docker Host Example

To connect to a remote Docker daemon:

```json
"containerEnv": {
    "DOCKER_HOST": "tcp://docker-host:2375"
}
```


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/sekhar-isovalent/devcontainer-features/blob/main/src/docker-cli/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
