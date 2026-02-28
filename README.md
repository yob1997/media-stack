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

## System Requirements
### Minimum
- 64-bit Linux host
- Docker Engine + Docker Compose plugin (`docker compose`)
- 4 CPU threads
- 8 GB RAM (or 4 GB with low concurrency and no Plex transcoding)
- 100+ GB free disk for configs/temp downloads, plus separate media storage
- `/data` mount (or enough local disk to create the same paths)

### Recommended
- 8+ CPU threads
- 16 GB RAM
- SSD-backed `/data/config` and `/data/downloads/incomplete`
- 2 TB+ for `/data/media` (adjust to your library growth)
- Hardware transcoding capability if Plex users stream remotely

### Current Host Specs (This Repo's Active Setup)
- OS: Ubuntu 24.04.3 LTS (kernel `6.8.0-90-generic`)
- CPU: AMD FX-8350 (8 threads)
- Memory: 7.6 GiB RAM + 4.0 GiB swap
- Storage:
  - `/`: 479 GB SSH
  - `/data`: 5.5 TB HDD

## Prerequisites
- Docker Engine and Docker Compose plugin
- `.env` file created from `.env.example` with required values
- WireGuard provider config placed under `/data/config/wireguard/`
- At least one content source path:
  - Usenet path: active Usenet provider account + at least one NZB indexer account (configured through Prowlarr)
  - Torrent path: tracker/indexer access + qBittorrent (included in this stack)
- If using TorrentLeech: it is invite-only, so an invite/account is required before adding it in Prowlarr

## Download Source Modes
- Hybrid (default): configure both SABnzbd (Usenet) and qBittorrent (torrents).
- Torrent-only:
  1. Do not configure SABnzbd in Sonarr/Radarr.
  2. Keep only qBittorrent as download client.
  3. Stop SABnzbd if not used: `docker compose stop sabnzbd`.
- Usenet-only:
  1. Do not configure qBittorrent in Sonarr/Radarr.
  2. Keep only SABnzbd as download client.
  3. Stop qBittorrent if not used: `docker compose stop qbittorrent`.

## Legal and Risk Note
- Torrenting may be illegal in some jurisdictions depending on what is downloaded.
- Public/private trackers can also introduce privacy, malware, or account-ban risks.
- You are responsible for legal compliance and operational risk in your region.

## Installation
Follow the full guide in `INSTALL.md`.

Quick start:
```bash
cd /home/[user]/media-stack
docker compose up -d
```

## Notes
- For Plex + WireGuard onboarding, use `ACCESS-CHECKLIST.md`.
- To restrict service UIs/Plex to selected IPs, edit `scripts/service-allowlist.conf` and run:
  - `sudo ./scripts/apply-service-allowlist.sh`
  - rollback: `sudo ./scripts/remove-service-allowlist.sh`
