# WoW Admin Dashboard

The admin dashboard is a small Spring Boot web app for the local Dad's MMO Lab
AzerothCore WotLK Playerbots stack. It gives you a browser view into accounts,
characters, online players, Playerbots health, and selected server controls.

The dashboard lives in `admin-dashboard/` and is copied into
`~/wow-server-playerbots` by the WotLK installers.

## What It Shows

| Page | Purpose |
|---|---|
| `/` | Server totals, online players, recent accounts, and class breakdown |
| `/accounts` | Account list with online, locked, mute, last login, IP, and GM level details |
| `/characters` | Character list with owner account, level, class, race, map, zone, money, and play time |
| `/playerbots` | Random bot totals, online bot count, level bands, class breakdown, and sample bot list |
| `/playerbots/config` | Playerbots config browser and override editor |

The read-only pages query MySQL directly. Command buttons use AzerothCore SOAP
and stay disabled until SOAP credentials are configured.

## Default Local Access

After a WotLK installer finishes, open:

```text
http://127.0.0.1:8090
```

The default dashboard username is:

```text
admin
```

The installer generates the dashboard password and writes it into:

```text
~/wow-server-playerbots/docker-compose.override.yml
```

Look for the `WOW_ADMIN_DASHBOARD_PASSWORD` value under the
`wow-admin-dashboard` service.

## Docker Compose Service

The installer adds a `wow-admin-dashboard` service to the local WotLK Compose
stack. It builds from `./admin-dashboard`, exposes port `8090`, connects to
the existing AzerothCore database network, and mounts the Playerbots config
files.

Important mounts:

```yaml
volumes:
  - ./modules/mod-playerbots/conf/playerbots.conf.dist:/playerbots.conf.dist:ro
  - ./playerbot-overrides:/playerbot-overrides
  - /var/run/docker.sock:/var/run/docker.sock
```

The Docker socket mount lets the dashboard request an `ac-worldserver` restart
after Playerbots config changes. If that socket is not mounted, the config
editor can still write files, but the restart button is disabled.

## Starting, Stopping, Restarting, And Updating

Run these commands from the installed WotLK Playerbots server directory:

```bash
cd ~/wow-server-playerbots
```

Start the dashboard without recreating the rest of the stack:

```bash
docker compose up -d wow-admin-dashboard
```

Restart the dashboard after changing environment variables or if the web UI is
stale:

```bash
docker compose restart wow-admin-dashboard
```

Stop only the dashboard:

```bash
docker compose stop wow-admin-dashboard
```

Rebuild and restart the dashboard after changing files in
`~/wow-server-playerbots/admin-dashboard`:

```bash
docker compose up -d --build wow-admin-dashboard
```

If you are editing this repository instead of the installed server copy, sync
the dashboard source into the live Compose context first:

```bash
cp -R ~/projects/dads-mmo-lab/admin-dashboard/src ~/wow-server-playerbots/admin-dashboard/
cd ~/wow-server-playerbots
docker compose up -d --build wow-admin-dashboard
```

To update the installed dashboard from a fresh copy of this repository, replace
the live dashboard source and rebuild:

```bash
rsync -a --delete ~/projects/dads-mmo-lab/admin-dashboard/ ~/wow-server-playerbots/admin-dashboard/
cd ~/wow-server-playerbots
docker compose up -d --build wow-admin-dashboard
```

Check dashboard status and logs:

```bash
docker compose ps wow-admin-dashboard
docker compose logs -f wow-admin-dashboard
```

## Enabling Command Buttons

SOAP command support is intentionally off by default. To enable it, edit:

```text
~/wow-server-playerbots/docker-compose.override.yml
```

Set these values on the `wow-admin-dashboard` service:

```yaml
WOW_ADMIN_SOAP_USER: "admin"
WOW_ADMIN_SOAP_PASSWORD: "your-gm-password"
```

Then restart the dashboard:

```bash
cd ~/wow-server-playerbots
docker compose up -d wow-admin-dashboard
```

SOAP-backed actions include creating accounts, promoting accounts to GM level,
running safe dashboard commands, and sending supported Playerbots commands.

## Playerbots Config Overrides

The config page reads the Playerbots template from:

```text
/playerbots.conf.dist
```

When you save an option, the dashboard writes two files in the mounted
`playerbot-overrides` directory:

| File | Purpose |
|---|---|
| `playerbots.env` | Compact list of dashboard-managed environment-style overrides |
| `playerbots.conf` | Full generated Playerbots config with overrides applied |

The worldserver reads the generated config on restart. Use the dashboard
restart button, or restart manually:

```bash
cd ~/wow-server-playerbots
docker compose restart ac-worldserver
```

The dashboard recognizes both dashboard-managed overrides and matching
environment variables that are already set on the container.

## Configuration Reference

| Variable | Default | Purpose |
|---|---|---|
| `SERVER_PORT` | `8090` | Dashboard HTTP port inside the container |
| `WOW_ADMIN_DASHBOARD_USER` | `admin` | Basic Auth username |
| `WOW_ADMIN_DASHBOARD_PASSWORD` | random UUID if unset | Basic Auth password |
| `WOW_ADMIN_JDBC_URL` | `jdbc:mysql://ac-database:3306/acore_auth?allowPublicKeyRetrieval=true&useSSL=false` | MySQL connection URL |
| `WOW_ADMIN_DB_USER` | `root` | MySQL user |
| `WOW_ADMIN_DB_PASSWORD` | `password` | MySQL password |
| `WOW_ADMIN_AUTH_DB` | `acore_auth` | Auth database name |
| `WOW_ADMIN_CHARACTERS_DB` | `acore_characters` | Characters database name |
| `WOW_ADMIN_PLAYERBOTS_DB` | `acore_playerbots` | Playerbots database name |
| `WOW_ADMIN_PLAYERBOTS_CONFIG_PATH` | `/playerbots.conf.dist` | Preferred Playerbots template path |
| `WOW_ADMIN_PLAYERBOTS_OVERRIDE_ENV_PATH` | `/playerbot-overrides/playerbots.env` | Saved override file |
| `WOW_ADMIN_PLAYERBOTS_GENERATED_CONFIG_PATH` | `/playerbot-overrides/playerbots.conf` | Generated config file |
| `WOW_ADMIN_DOCKER_SOCKET_PATH` | `/var/run/docker.sock` | Docker socket path for restart control |
| `WOW_ADMIN_WORLDSERVER_CONTAINER` | `ac-worldserver` | Container restarted by the config page |
| `WOW_ADMIN_SOAP_URL` | `http://ac-worldserver:7878/` | AzerothCore SOAP endpoint |
| `WOW_ADMIN_SOAP_USER` | blank | GM account used for SOAP commands |
| `WOW_ADMIN_SOAP_PASSWORD` | blank | GM password used for SOAP commands |

## Developer Commands

Build the dashboard container:

```bash
cd admin-dashboard
docker build -t wow-admin-dashboard .
```

Run the Spring Boot app directly with Maven:

```bash
cd admin-dashboard
mvn spring-boot:run
```

Package the jar:

```bash
cd admin-dashboard
mvn -DskipTests package
```

The app requires Java 17.

## Troubleshooting

If the browser asks for a password you do not know, check
`WOW_ADMIN_DASHBOARD_PASSWORD` in `~/wow-server-playerbots/docker-compose.override.yml`.

If database pages fail, make sure the WotLK stack is running and that
`ac-database` is healthy:

```bash
cd ~/wow-server-playerbots
docker compose ps
```

If command buttons are disabled, set `WOW_ADMIN_SOAP_USER` and
`WOW_ADMIN_SOAP_PASSWORD`, then recreate the dashboard container.

If Playerbots config saves but changes do not affect the game, restart
`ac-worldserver` and confirm the worldserver has this mounted:

```text
./playerbot-overrides/playerbots.conf:/azerothcore/env/dist/etc/modules/playerbots.conf:ro
```
