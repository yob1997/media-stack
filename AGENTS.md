# AGENTS.md

## What this project is
This repository is a **sanitized backup** of a Docker Compose media-server stack. It is meant to be safe to share and rebuild from scratch without leaking credentials. Only template configs and directory structure live here.

## What matters most
- Keep **secrets out of the repo**. Only store `.example` configs under `data/config/**`.
- Do **not** add media, downloads, databases, logs, or caches to this repo.
- Preserve the `/data` layout and volume mappings so the stack can be rebuilt reliably.

## Key paths
- Repo root: `/home/yob/media-stack`
- Host data root (runtime): `/data`
- Sanitized templates: `/home/yob/media-stack/data/config/**`
- Data folder layout reference: `/home/yob/media-stack/folderstructure.txt`

## Stack overview (docker-compose.yml)
Services and notable behavior:
- `plex`: host network, mounts `/data/media`.
- `sabnzbd`: routes through `wireguard` network; mounts `/data/downloads`.
- `wireguard`: VPN container; config at `/data/config/wireguard/privado.ams-032.conf`.
- `sonarr`, `radarr`: manage TV/movies; mount `/data/media/*` and `/data/downloads`.
- `prowlarr`: indexer manager.
- `overseerr`: requests UI; uses a `plextv.js` override.
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
1. Create `/data` folders (mirror `data/` or use `folderstructure.txt`).
2. Copy `*.example` templates to real configs under `/data/config/...` and fill secrets.
3. Copy the Overseerr override: `/data/config/overseerr/overrides/plextv.js`.
4. Start stack:
   ```bash
   cd /home/yob/media-stack
   docker compose up -d
   ```

## Updating sanitized templates
If you need to refresh templates from a live machine:
```bash
/home/yob/media-stack/scripts/sync-configs.sh
```
This reads `/data/config` and writes redacted `.example` files under `data/config`.

## Guardrails for changes
- If adding a new service, include its config templates as `data/config/<service>/*.example`.
- Never commit real API keys, tokens, or credentials.
- Keep volume mappings aligned with `/data` so restores stay consistent.

## Huntarr behavior (important)
- Huntarr does not define its own quality profiles; it triggers searches and Sonarr/Radarr decide what to grab using their existing quality profiles, cutoffs, and custom formats.
- Huntarr only talks to Sonarr/Radarr; those apps already pull indexers from Prowlarr, so Huntarr inherits that setup.
- To avoid indexer/API abuse: configure Huntarr for **missing-only** checks and conservative rate limits in each app instance.
- Sonarr settings: Missing Search low end (2-5), Upgrade Search 0, Sleep Duration >= 900s (15m), API Cap <= 400/hr.
- Radarr settings: Missing Search low end (3-5), Upgrade Search 0, Sleep Duration >= 1200s (20m), API Cap <= 300/hr.
