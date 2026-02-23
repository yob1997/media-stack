# media-stack backup (sanitized)

This repo tracks the Docker Compose stack and a sanitized `/data` layout so it can be rebuilt safely without leaking credentials.

## What is included
- `docker-compose.yml`
- `.env.example` (safe template for local values like LAN IPs)
- `folderstructure.txt`
- `data/` directory structure with **sanitized** `.example` configs
- `data/config/overseerr/overrides/plextv.js` (watchlist endpoint override)

## What is NOT included
- Any media or downloads (`/data/media`, `/data/downloads`)
- Databases, logs, caches, or actual config files with secrets
- Usenet/indexer credentials and API keys

## Restore workflow (fresh machine)
1. Create the `/data` folders using `folderstructure.txt` (or mirror `data/` from this repo).
2. Create your local environment file:
   - `cp .env.example .env`
   - Edit `.env` and set your LAN/public values (for example `PLEX_ADVERTISE_IP` and `SABNZBD_HOST_WHITELIST`).
3. Copy templates from `data/config/**/*.example` into `/data/config/...` and fill in secrets:
   - `sonarr/config.xml`
   - `radarr/config.xml`
   - `prowlarr/config.xml`
   - `sabnzbd/sabnzbd.ini`
   - `qbittorrent` config is created on first run at `/data/config/qbittorrent` (not tracked in repo)
   - `overseerr/settings.json`
   - `wireguard/privado.ams-032.conf`
   - `huntarr` config is created on first run at `/data/config/huntarr` (not tracked in repo)
   - `wg-easy` runtime data is created on first run at `/data/config/wg-easy` (not tracked in repo)
4. Copy the watchlist override into place:
   - `/data/config/overseerr/overrides/plextv.js`
5. Start the stack:
   ```bash
   cd /home/yob/media-stack
   docker compose up -d
   ```

## Notes
- Any runtime settings stored in app databases are not part of this repo and should be restored from separate backups if needed.
- If you add new services, add their config templates under `data/config/<service>/` as `*.example`.
- For onboarding users to Plex over WireGuard, use `ACCESS-CHECKLIST.md`.
- To restrict service UIs/Plex to selected IPs, edit `scripts/service-allowlist.conf` and run `sudo ./scripts/apply-service-allowlist.sh` (rollback: `sudo ./scripts/remove-service-allowlist.sh`).
- To refresh sanitized templates from live `/data/config`, run:
  ```bash
  /home/yob/media-stack/scripts/sync-configs.sh
  ```
