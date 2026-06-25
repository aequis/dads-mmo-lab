# WoW Admin Dashboard

Spring Boot dashboard for a local Dad's MMO Lab AzerothCore WotLK Playerbots
server.

The dashboard reads common server state directly from MySQL and can send GM or
playerbot commands through AzerothCore SOAP when you provide a GM account.
It also surfaces Playerbots configuration options from `playerbots.conf.dist`
at `/playerbots/config`.

## Local Compose Defaults

The WotLK installers copy this directory into `~/wow-server-playerbots` and add
it as the `wow-admin-dashboard` Compose service.

- URL: <http://127.0.0.1:8090>
- Dashboard login: `admin` plus the generated password in
  `docker-compose.override.yml`
- Database host: `ac-database`
- Default database user/password: `root` / `password`
- SOAP URL: `http://ac-worldserver:7878/`
- Playerbots config template: `/playerbots.conf.dist`

The installer mounts the Playerbots config template into the dashboard service:

```yaml
volumes:
  - ./modules/mod-playerbots/conf/playerbots.conf.dist:/playerbots.conf.dist:ro
  - ./playerbot-overrides:/playerbot-overrides
  - /var/run/docker.sock:/var/run/docker.sock
environment:
  WOW_ADMIN_PLAYERBOTS_CONFIG_PATH: "/playerbots.conf.dist"
  WOW_ADMIN_PLAYERBOTS_OVERRIDE_ENV_PATH: "/playerbot-overrides/playerbots.env"
  WOW_ADMIN_PLAYERBOTS_GENERATED_CONFIG_PATH: "/playerbot-overrides/playerbots.conf"
```

The config page shows defaults from the template. The dashboard can save
overrides into `/playerbot-overrides/playerbots.env` and generates a full
`/playerbot-overrides/playerbots.conf` for the worldserver to read on restart.
It can also restart the `ac-worldserver` container when `/var/run/docker.sock`
is mounted read-write.

To enable command buttons, add these environment variables to the
`wow-admin-dashboard` service in `docker-compose.override.yml`:

```yaml
WOW_ADMIN_SOAP_USER: "admin"
WOW_ADMIN_SOAP_PASSWORD: "your-gm-password"
```

The dashboard intentionally leaves SOAP credentials blank by default.

Change the dashboard login with:

```yaml
WOW_ADMIN_DASHBOARD_USER: "admin"
WOW_ADMIN_DASHBOARD_PASSWORD: "a-better-password"
```

## Operations

Use the installed server directory for normal operations:

```bash
cd ~/wow-server-playerbots
```

Start, restart, or stop only the dashboard:

```bash
docker compose up -d wow-admin-dashboard
docker compose restart wow-admin-dashboard
docker compose stop wow-admin-dashboard
```

Rebuild and restart after changing the installed dashboard source:

```bash
docker compose up -d --build wow-admin-dashboard
```

If you changed this repository copy, sync it into the installed Compose context
before rebuilding:

```bash
cp -R ~/projects/dads-mmo-lab/admin-dashboard/src ~/wow-server-playerbots/admin-dashboard/
cd ~/wow-server-playerbots
docker compose up -d --build wow-admin-dashboard
```

For a full dashboard update from this repository:

```bash
rsync -a --delete ~/projects/dads-mmo-lab/admin-dashboard/ ~/wow-server-playerbots/admin-dashboard/
cd ~/wow-server-playerbots
docker compose up -d --build wow-admin-dashboard
```

Check status or follow logs:

```bash
docker compose ps wow-admin-dashboard
docker compose logs -f wow-admin-dashboard
```
