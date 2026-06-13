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
