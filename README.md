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

## Configuration output

`get-configuration` returns: `host`, `lets_encrypt`, `http2https`.

## Images

| Image | Version |
|---|---|
| `docker.io/postgres` | `18.7-alpine3.24` |
| `docker.io/redis` | `8.10.3-alpine3.23` |
| `docker.io/tacticalrmm/tactical` | `0.20.1` |
| `docker.io/tacticalrmm/tactical-nats` | `0.20.1` |
| `docker.io/tacticalrmm/tactical-meshcentral` | `0.20.1` |
| `docker.io/mongo` | `9.0.8` |
| `docker.io/tacticalrmm/tactical-frontend` | `0.20.1` |

## Network and access

- Reserves 2 TCP port(s) on the node. The web application is published through Traefik on the configured host name.
- Runs rootless.
- Declares these NS8 authorizations: `traefik@node:routeadm`.

## Backup

The following paths are included in the NS8 backup (`imageroot/etc/state-include.conf`):

- `state/tacticalrmm.sql`
- `volumes/tacticalrmm-app`

## Services

- `postgresql-app.service`
- `redis-app.service`
- `tactical-backend.service`
- `tactical-celery.service`
- `tactical-celerybeat.service`
- `tactical-frontend.service`
- `tactical-init.service`
- `tactical-nats.service`
- `tactical-websockets.service`
- `tacticalrmm.service`

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

The suite installs the module, configures a host name, checks that the web application answers through Traefik, takes UI screenshots and removes the module.

Run it locally with the NS8 standard infrastructure described in the [ns8-github-actions README](https://github.com/NethServer/ns8-github-actions/blob/v1/README.md#running-tests-locally).

## Open items

Found by the NS8 module standards check. These must be resolved before a stable release:

- tests/tacticalrmm.robot generated from template: set real configure payload and URL check
- metadata: documentation_url is a placeholder
- metadata: categories empty (use standard categories)
- postgresql-app.service: uses %S/state, kickstart uses %E/state
- tactical-init.service: uses %S/state, kickstart uses %E/state
- tacticalrmm.service: uses %S/state, kickstart uses %E/state
- tactical-celery.service: uses %S/state, kickstart uses %E/state
- redis-app.service: uses %S/state, kickstart uses %E/state
- tactical-nats.service: uses %S/state, kickstart uses %E/state
- tactical-celerybeat.service: uses %S/state, kickstart uses %E/state
- tactical-websockets.service: uses %S/state, kickstart uses %E/state
- tactical-backend.service: uses %S/state, kickstart uses %E/state
- tactical-frontend.service: uses %S/state, kickstart uses %E/state
- discover-smarthost still present: remove if the app does not use SMTP
- secrets passed through agent.set_env(): move to state/passwords.env
- README still has the template boilerplate
- postgresql-app.service: %S/state changed to %E/state (review the bind mounts that remain)
- tactical-init.service: %S/state changed to %E/state (review the bind mounts that remain)
- tacticalrmm.service: %S/state changed to %E/state (review the bind mounts that remain)
- tactical-celery.service: %S/state changed to %E/state (review the bind mounts that remain)
- redis-app.service: %S/state changed to %E/state (review the bind mounts that remain)
- tactical-nats.service: %S/state changed to %E/state (review the bind mounts that remain)
- tactical-celerybeat.service: %S/state changed to %E/state (review the bind mounts that remain)
- tactical-websockets.service: %S/state changed to %E/state (review the bind mounts that remain)
- tactical-backend.service: %S/state changed to %E/state (review the bind mounts that remain)
- tactical-frontend.service: %S/state changed to %E/state (review the bind mounts that remain)
- imageroot/actions/configure-module/80start_services: smarthost lines removed, check the unit still starts
- POSTGRES_IMAGE is used by the module but no image in the label provides it: leftover from the template?
- REDIS_IMAGE is used by the module but no image in the label provides it: leftover from the template?
- TACTICAL_IMAGE is used by the module but no image in the label provides it: leftover from the template?
- TACTICAL_NATS_IMAGE is used by the module but no image in the label provides it: leftover from the template?

## Upstream

Application documentation: https://docs.tacticalrmm.com/

## License

GPL-3.0-or-later. See [LICENSE](LICENSE).
