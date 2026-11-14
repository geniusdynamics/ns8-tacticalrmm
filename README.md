# ns8-tacticalrmm

Tactical RMM is a remote monitoring & management tool built with Django, Vue and Golang

Module id: `tacticalrmm`. Images are pinned in `build-images.sh` and updated through reviewed changes.

## Install

```bash
add-module ghcr.io/geniusdynamics/tacticalrmm:latest 1
```

The command returns the instance id, for example `tacticalrmm1`. Use the id NS8 returns.

## Configure

```bash
api-cli run configure-module --agent module/tacticalrmm1 --data - <<'EOF'
{
  "host": "tacticalrmm.example.org",
  "http2https": true,
  "lets_encrypt": false
}
EOF
```

| Parameter | Required | Type | Description |
|---|---|---|---|
| `host` | yes | string | Host name for the application, like 'tacticalrmm.domain.org' |
| `lets_encrypt` | yes | boolean | Request a valid Let's Encrypt certificate. |
| `http2https` | yes | boolean | Redirect all the HTTP requests to HTTPS |
| `API_HOST` | no | string | Host name of the API. Default: `api.<host>` |
| `MESH_HOST` | no | string | Host name of MeshCentral. Default: `mesh.<host>` |
| `TACTICAL_USER` | no | string | Dashboard user, created at the first start. Default: `admin` |
| `TACTICAL_PASSWORD` | no | string | Password of the dashboard user. Set it before the first start: the user is created only once. Default: random |
| `MESH_USER` | no | string | MeshCentral admin account. Default: `meshadmin` |
| `MESH_PASSWORD` | no | string | Password of the MeshCentral admin account. Default: random |

The three host names must resolve to the node: Traefik routes each of them to the module.

## Configuration output

`get-configuration` returns: `host`, `lets_encrypt`, `http2https`, `API_HOST`, `MESH_HOST`, `MESH_USER`, `TACTICAL_USER`. It never returns the passwords.

## Images

| Image | Version |
|---|---|
| `docker.io/postgres` | `18.7-alpine3.24` |
| `docker.io/redis` | `8.10.3-alpine3.23` |
| `docker.io/tacticalrmm/tactical` | `1.6.1` |
| `docker.io/tacticalrmm/tactical-nats` | `1.6.1` |
| `docker.io/tacticalrmm/tactical-meshcentral` | `1.6.1` |
| `docker.io/tacticalrmm/tactical-frontend` | `1.6.1` |
| `docker.io/tacticalrmm/tactical-nginx` | `1.6.1` |

MeshCentral keeps its data in its built-in NeDB database (volume `mesh_data`), so the module runs no MongoDB.

## Network and access

- Reserves 1 TCP port on the node. Traefik terminates TLS and sends the app, API and MeshCentral host names to the nginx container of the pod, which dispatches them by host name.
- All the containers run in one pod and talk on 127.0.0.1: nginx 8000, uwsgi 8080, frontend 8081, websockets 8383, NATS 4222 and 9235, MeshCentral 4443, PostgreSQL 5432, Redis 6379.
- Runs rootless.
- Declares these NS8 authorizations: `traefik@node:routeadm`.

## Backup

The following paths are included in the NS8 backup (`imageroot/etc/state-include.conf`):

- `state/tacticalrmm.pg_dump`: PostgreSQL dump written by `bin/module-dump-state`
- `volumes/mesh_data`: MeshCentral database and certificates

## Services

- `postgresql-app.service`
- `redis-app.service`
- `tactical-backend.service`
- `tactical-celery.service`
- `tactical-celerybeat.service`
- `tactical-frontend.service`
- `tactical-init.service`: one-shot setup (migrations, first user, ready file); it stays `active (exited)`
- `tactical-meshcentral.service`
- `tactical-nginx.service`
- `tactical-nats.service`
- `tactical-websockets.service`
- `tacticalrmm.service`: the pod

## Get the configuration

```bash
api-cli run get-configuration --agent module/tacticalrmm1
```

## Update and uninstall

```bash
api-cli run update-module --data '{"module_url":"ghcr.io/geniusdynamics/tacticalrmm:latest","instances":["tacticalrmm1"],"force":true}'
remove-module --no-preserve tacticalrmm1
```

## Testing

Continuous integration:

- `Publish images` builds the module image on every push.
- `Test module` installs the image on a QEMU NS8 node and runs the Robot Framework suite in `tests/`. It runs after `Publish images` succeeds on `dev` and on `main`.
- `Build API JSON Schema docs` and the security scan run alongside.

The suite installs the module, configures a host name, reads the configuration back, waits until the web UI and the API answer through Traefik, takes UI screenshots and removes the module.

Run it locally with the NS8 standard infrastructure described in the [ns8-github-actions README](https://github.com/NethServer/ns8-github-actions/blob/v1/README.md#running-tests-locally).

## Open items

- metadata: documentation_url is a placeholder
- metadata: categories empty (use standard categories)
- MeshCentral fetches its web certificate from `https://<MESH_HOST>:443/` to give its hash to the agents: the host name must resolve and serve the Traefik certificate.

## Upstream

Application documentation: https://docs.tacticalrmm.com/

## License

GPL-3.0-or-later. See [LICENSE](LICENSE).
