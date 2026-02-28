# media-stack

This repo keeps a Docker Compose media stack plus the host folder layout only.

## Included
- `docker-compose.yml`
- `.env.example`
- `scripts/service-allowlist.conf.example`
- `overrides/overseerr/plextv.js` (PlexTV watchlist override)
- `folderstructure.txt`
- setup and access docs

## Not Included
- app secrets or API keys
- runtime databases, logs, and caches
- media/download content

## Installation
Follow the full guide in `INSTALL.md`.

Quick start:
```bash
cd /home/yob/media-stack
docker compose up -d
```

## Notes
- For Plex + WireGuard onboarding, use `ACCESS-CHECKLIST.md`.
- To restrict service UIs/Plex to selected IPs, edit `scripts/service-allowlist.conf` and run:
  - `sudo ./scripts/apply-service-allowlist.sh`
  - rollback: `sudo ./scripts/remove-service-allowlist.sh`
