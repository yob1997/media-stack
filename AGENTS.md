# AGENTS.md

## What this project is
This repository is a Docker Compose media-server stack with a documented `/data` folder layout.
It is safe to share because secrets and runtime app configs are intentionally excluded.

## What matters most
- Keep **secrets out of the repo**. Do not commit real app config files or credentials.
- Do **not** add media, downloads, databases, logs, or caches to this repo.
- Preserve the `/data` layout and volume mappings so the stack can be rebuilt reliably.

## Key paths
- Repo root: `/home/[user]/media-stack`
- Host data root (runtime): `/data`
- Data folder layout reference: `/home/[user]/media-stack/folderstructure.txt`
- Full setup guide: `/home/[user]/media-stack/INSTALL.md`
- Overseerr PlexTV override: `/home/[user]/media-stack/overrides/overseerr/plextv.js`

## Stack overview (docker-compose.yml)
Services and notable behavior:
- `plex`: host network, mounts `/data/media`.
- `sabnzbd`: routes through `wireguard` network; mounts `/data/downloads`.
- `wireguard`: VPN container; config at `/data/config/wireguard/privado.ams-032.conf`.
- `sonarr`, `radarr`: manage TV/movies; mount `/data/media/*` and `/data/downloads`.
- `prowlarr`: indexer manager.
- `overseerr`: requests UI, with PlexTV override mounted from repo.
- `huntarr`: triggers missing-item searches via Sonarr/Radarr; stores config in `/data/config/huntarr`.
- `portainer`: docker UI; mounts Docker socket.

## Ports (host)
- Plex: host network (no explicit port mapping)
- Sonarr: `8989`
- Radarr: `7878`
- Prowlarr: `9696`
- Overseerr: `5055`
- Huntarr: `9705`
- Portainer: `9000`
- Wireguard: `8080` (mapped)

## Restore workflow (fresh machine)
1. Create `/data` folders (use `folderstructure.txt` or the `mkdir` command in `INSTALL.md`).
2. Create local `.env` with required values.
3. Place WireGuard provider config at `/data/config/wireguard/`.
4. Start stack:
   ```bash
   cd /home/[user]/media-stack
   docker compose up -d
   ```
5. Follow `/home/[user]/media-stack/INSTALL.md` to link Prowlarr, Sonarr/Radarr, download clients, Plex, Overseerr, and Huntarr.

## Guardrails for changes
- If adding a new service, update both `docker-compose.yml` and `INSTALL.md` linking steps.
- Never commit real API keys, tokens, or credentials.
- Keep volume mappings aligned with `/data` so restores stay consistent.

## Huntarr behavior (important)
- Huntarr does not define its own quality profiles; it triggers searches and Sonarr/Radarr decide what to grab using their existing quality profiles, cutoffs, and custom formats.
- Huntarr only talks to Sonarr/Radarr; those apps already pull indexers from Prowlarr, so Huntarr inherits that setup.
- To avoid indexer/API abuse: configure Huntarr for **missing-only** checks and conservative rate limits in each app instance.
- Sonarr settings: Missing Search low end (2-5), Upgrade Search 0, Sleep Duration >= 900s (15m), API Cap <= 400/hr.
- Radarr settings: Missing Search low end (3-5), Upgrade Search 0, Sleep Duration >= 1200s (20m), API Cap <= 300/hr.
