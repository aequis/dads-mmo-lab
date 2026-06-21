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
environment:
  WOW_ADMIN_PLAYERBOTS_CONFIG_PATH: "/playerbots.conf.dist"
```

The config page shows defaults from the template. If the dashboard service has
matching `AC_AI_PLAYERBOT_...` environment variables, it marks those rows as
overridden and shows the effective value visible to the dashboard.

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
