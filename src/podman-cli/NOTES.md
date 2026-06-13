# Podman CLI Feature Notes

This feature installs only the Podman CLI binary (client), not the Podman daemon. This is useful for scenarios where you want to interact with a remote Podman daemon or use Podman in rootless mode without running a full daemon in the container.

## Socket Mounting Example

To use the Podman CLI with a Podman socket from the host:

```json
"mounts": [
    "source=/run/podman/podman.sock,target=/run/podman/podman.sock,type=bind"
]
```

## Remote Podman Host Example

To connect to a remote Podman daemon:

```json
"containerEnv": {
    "PODMAN_CONNECTION": "ssh://user@remote-host"
}
```

## Rootless Podman

Podman supports rootless operation by default. To use rootless Podman, ensure the necessary user namespaces and cgroup settings are configured on the host system.
